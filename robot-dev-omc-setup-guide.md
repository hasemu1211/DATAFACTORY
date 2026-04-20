# 로봇 개발환경 OMC + MCP 동적 제어 설계 가이드

> 작성일: 2026-04-19 (최종 수정: 2026-04-20)  
> 환경: Linux (Isaac Sim Docker + ROS2 Docker) + OMC + tmux + wezterm  
> 목적: 리눅스 환경에서 OMC 설치 및 MCP 동적 제어 구조 구축
>
> **업데이트 2026-04-20**: DATAFACTORY 호스트에 OMC 4.13.0 글로벌 설치 완료. 
> 섹션 11(컨텍스트 관리 전략), 섹션 12(개발환경 실전 교훈) 추가.
> `~/robot/` 디렉토리는 **미생성 (설계안 상태)** — 현재 DATAFACTORY가 예행 플랫폼.

---

## 1. 배경 및 문제 정의

### 환경
- 리눅스 호스트 (wezterm + tmux)
- Isaac Sim Docker (전용 MCP 있음)
- ROS2 Docker (전용 MCP 있음)
- Docker MCP (컨테이너 제어)

### 핵심 문제
Claude Code는 세션 시작 시 MCP를 로드하고 세션 중에는 재로드하지 않는다.  
→ 모든 MCP를 항상 로드하면 토큰 낭비  
→ 에이전트별로 필요한 MCP만 격리해서 사용하고 싶음

### Anthropic 공식 이슈 (진행 중)
- [Issue #16177: Enable specific MCP servers for sub-agents](https://github.com/anthropics/claude-code/issues/16177)
- [Issue #4476: Agent-Scoped MCP Configuration with Strict Isolation](https://github.com/anthropics/claude-code/issues/4476)
- [Issue #32514: Agent identity context for sub-agent resource isolation](https://github.com/anthropics/claude-code/issues/32514)

> 정확히 동일한 문제를 Anthropic이 인식하고 개발 중. 현재 미구현.

---

## 2. 현재 가능한 최선의 설계

### 핵심 발견: 서브에이전트 인라인 MCP 주입

서브에이전트 생성 시 `mcpServers` 필드를 인라인으로 지정하면  
**해당 서브에이전트 시작 시 연결, 종료 시 자동 해제**된다.

```json
{
  "mcpServers": {
    "isaac": {
      "command": "npx",
      "args": ["-y", "isaac-sim-mcp"]
    }
  }
}
```

이것이 현재 가능한 가장 동적인 MCP 제어 방식이다.

---

## 3. 디렉토리 구조 설계

```
~/robot/                              ← 메인 레포 (git)
  .claude/
    settings.json                     ← Docker MCP만 (최소 권한)
  .gitmodules
  scripts/
    mcp-enable.sh                     ← MCP 토글 헬퍼
    mcp-disable.sh
  ├─ isaac-sim/                       ← git submodule (별도 레포)
  │   .claude/
  │     settings.json                 ← Isaac MCP만
  │   CLAUDE.md
  └─ ros2/                            ← git submodule (별도 레포)
      .claude/
        settings.json                 ← ROS2 MCP만
      CLAUDE.md
```

### 메인 settings.json (~/robot/.claude/settings.json)
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "tmux"
}
```
> MCP는 최소한으로 유지. Docker MCP만 상시 연결.

### Isaac Sim settings.json (~/robot/isaac-sim/.claude/settings.json)
```json
{
  "mcpServers": {
    "isaac-sim": {
      "command": "npx",
      "args": ["-y", "isaac-sim-mcp-server"]
    }
  }
}
```

### ROS2 settings.json (~/robot/ros2/.claude/settings.json)
```json
{
  "mcpServers": {
    "ros2": {
      "command": "npx",
      "args": ["-y", "ros2-mcp-server"]
    }
  }
}
```

---

## 4. MCP 동적 제어 흐름

### 방식 A: 디렉토리 기반 (권장)
```
메인 컨트롤러 (~/robot/)
  → Docker MCP만 로드 (고정)
  → EnterWorktree("isaac-sim/")
      → 새 프로세스: Isaac MCP 로드
      → Isaac 작업 수행
      → ExitWorktree → Isaac MCP 해제
  → EnterWorktree("ros2/")
      → 새 프로세스: ROS2 MCP 로드
      → ROS2 작업 수행
      → ExitWorktree → ROS2 MCP 해제
```

### 방식 B: 인라인 MCP 주입 (서브에이전트)
```python
# 메인 컨트롤러가 서브에이전트 생성 시 MCP 지정
Agent(
  subagent_type="executor",
  mcpServers={"isaac": {...}},  # 이 에이전트만 사용
  prompt="Isaac Sim에서 ..."
)
```

### 방식 C: 스크립트 토글 (세션 재시작 필요)
```bash
# ~/robot/scripts/mcp-enable.sh
#!/bin/bash
TARGET=$1  # isaac | ros2 | docker

case $TARGET in
  isaac)
    claude mcp add isaac -- npx -y isaac-sim-mcp-server
    ;;
  ros2)
    claude mcp add ros2 -- npx -y ros2-mcp-server
    ;;
  docker)
    claude mcp add docker -- npx -y docker-mcp-server
    ;;
esac

echo "$TARGET MCP enabled. Restart Claude Code session to apply."
```

---

## 5. tmux 워크스페이스 구성

```
tmux
├─ window 1: main        → ~/robot/          (메인 컨트롤러, Docker MCP)
├─ window 2: isaac       → ~/robot/isaac-sim/ (Isaac MCP)
├─ window 3: ros2        → ~/robot/ros2/      (ROS2 MCP)
└─ window 4: monitor     → 로그/상태 모니터링
```

### tmux 세션 초기화 스크립트
```bash
#!/bin/bash
# ~/robot/scripts/dev-session.sh

tmux new-session -d -s robot -n main
tmux send-keys -t robot:main 'cd ~/robot && claude' Enter

tmux new-window -t robot -n isaac
tmux send-keys -t robot:isaac 'cd ~/robot/isaac-sim && claude' Enter

tmux new-window -t robot -n ros2
tmux send-keys -t robot:ros2 'cd ~/robot/ros2 && claude' Enter

tmux new-window -t robot -n monitor
tmux send-keys -t robot:monitor 'cd ~/robot && watch -n 2 "claude mcp list"' Enter

tmux attach-session -t robot
```

---

## 6. git submodule 구성

```bash
# 최초 설정
cd ~/robot
git init
git submodule add https://github.com/yourname/isaac-sim-ws isaac-sim
git submodule add https://github.com/yourname/ros2-ws ros2

# 클론 시
git clone --recurse-submodules https://github.com/yourname/robot

# 서브모듈 업데이트
git submodule update --remote --merge
```

---

## 7. 리눅스 환경 OMC 설치 순서

### Step 1: 사전 요구사항
```bash
# Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# tmux
sudo apt install tmux

# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# OMC CLI
npm install -g oh-my-claude-sisyphus
```

### Step 2: Claude Code에 OMC 플러그인 설치
```bash
claude /plugin install oh-my-claudecode
```

### Step 3: OMC 전역 설정
```bash
# Claude Code 실행 후
claude
> /oh-my-claudecode:omc-setup --global
```

설정 시 선택사항:
- 설치 범위: **Global**
- 실행 모드: **ultrawork**
- 팀 모드: **Yes, enable**
- teammate 표시: **tmux**
- 기본 에이전트 수: **3**
- MCP: **Context7** (기본) + 이후 개별 추가

### Step 4: 프로젝트별 MCP 설정
```bash
# 메인 레포
cd ~/robot
claude mcp add docker -- npx -y docker-mcp-server

# Isaac Sim 서브모듈
cd ~/robot/isaac-sim
claude mcp add isaac -- npx -y isaac-sim-mcp-server

# ROS2 서브모듈
cd ~/robot/ros2
claude mcp add ros2 -- npx -y ros2-mcp-server
```

### Step 5: 개발 세션 시작
```bash
chmod +x ~/robot/scripts/dev-session.sh
~/robot/scripts/dev-session.sh
```

---

## 8. 참고 자료

### 공식 문서
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Claude Code Sub-agents](https://code.claude.com/docs/en/sub-agents)

### GitHub 이슈 (MCP 동적 제어 관련)
- [#16177: Enable specific MCP servers for sub-agents](https://github.com/anthropics/claude-code/issues/16177)
- [#4476: Agent-Scoped MCP with Strict Isolation](https://github.com/anthropics/claude-code/issues/4476)
- [#32514: Agent identity context for sub-agent resource isolation](https://github.com/anthropics/claude-code/issues/32514)
- [#37823: Per-agent-type model overrides in settings](https://github.com/anthropics/claude-code/issues/37823)

### 관련 프로젝트
- [Continuous Claude v3](https://github.com/parcadei/continuous-claude-v3) — MCP 실행을 컨텍스트 오염 없이 격리
- [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) — OMC 플러그인
- [Claude Code Multi-Agent 2026](https://shipyard.build/blog/claude-code-multi-agent/)
- [Claude Code MCP Enterprise Guide](https://dextralabs.com/blog/claude-code-mcp-enterprise-ai-integrations/)

---

## 9. 현재 한계 및 향후 개선 예상

| 항목 | 현재 | 향후 (Anthropic 개발 중) |
|------|------|--------------------------|
| 에이전트별 MCP 격리 | 디렉토리 분리로 우회 | Agent-Scoped MCP 공식 지원 예정 |
| 세션 중 MCP 토글 | 불가 (재시작 필요) | 동적 MCP 로드 가능성 |
| 서브에이전트 MCP 주입 | 인라인 mcpServers 부분 지원 | 완전한 격리 모드 지원 예정 |

---

## 10. 체크리스트 (리눅스 환경 구축 시)

### 이미 완료 (DATAFACTORY 호스트, 2026-04-20)
- [x] Node.js 20+ 설치
- [x] tmux 설치 (3.2a) + `~/.tmux.conf` (mouse on, history 50k, true-color, `|`/`-` 분할 바인딩)
- [x] Claude Code CLI 설치
- [x] OMC 플러그인 설치 (`/plugin install oh-my-claudecode`)
- [x] OMC 전역 설정 완료 (`~/.claude/CLAUDE.md`, 4.13.0)
- [x] OMC CLI 설치 (`omc --version` → 4.13.0)
- [x] tmux teammate 모드 설정 (`settings.json`: `teammateMode: tmux`, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- [x] 팀 기본값 저장 (`~/.claude/.omc-config.json`: 3 agents, claude provider, ultrawork default)
- [x] HUD statusLine 설정 (`node ~/.claude/hud/omc-hud.mjs`)
- [x] xclip/xsel 설치 (X11 클립보드)
- [x] wezterm 마우스 바인딩 (드래그 자동 복사, 우클릭 붙여넣기)
- [x] Context7 MCP (DATAFACTORY 프로젝트 레벨, `.mcp.json`)
- [x] Isaac Sim MCP (포트 8766)
- [x] ROS2 MCP (rosbridge 9090)
- [x] GitHub MCP, NotebookLM CLI

### ~/robot 신규 레포에서 해야 할 것
- [ ] `~/robot/` 디렉토리 생성 + `git init`
- [ ] git submodule 구조 구성 (`isaac-sim/`, `ros2/`)
- [ ] 프로젝트별 `.claude/settings.json` MCP 격리 설정
- [ ] 메인 레포: Docker MCP 설치
- [ ] `dev-session.sh` 스크립트 작성 및 테스트
- [ ] 메인 `AGENTS.md` + 각 서브모듈 `AGENTS.md` (`/oh-my-claudecode:deepinit` 활용)
- [ ] 루트에 OMC wiki 활성 (크로스 서브모듈 지식 축적)
- [ ] 웹 서치 MCP 추가 (Exa 추천, `/oh-my-claudecode:mcp-setup`)

---

## 11. 컨텍스트 관리 전략 (토큰 효율성)

> 2026-04-20 논의에서 확정. MCP 격리 + OMC 네이티브 스킬 조합으로 Anthropic이 미구현한 agent-scoped MCP를 우회.

### 3-Layer 구조

**Layer 1 — 정적 컨텍스트 (세션 시작 시 주입)**
- `AGENTS.md` @ 서브모듈 루트 — 해당 도메인 규칙만 (ROS2, Isaac Sim, Docker 등)
- 메인 `AGENTS.md` — 얇게, 네비게이션만
- `CLAUDE.md` (global) — OMC 기본 동작
- SessionStart/PostCompact hook로 자동 재주입 (DATAFACTORY 이미 설정됨)

**Layer 2 — 동적 컨텍스트 (세션 중 skill 호출)**
- `oh-my-claudecode:wiki` — 영속 마크다운 KB (Obsidian-like, 크로스 서브모듈 지식)
- `oh-my-claudecode:remember` — 재사용 지식 선별/저장
- `oh-my-claudecode:external-context` — 외부 문서 병렬 조사 (document-specialist 에이전트)
- `oh-my-claudecode:learner` / `skillify` — 반복 워크플로우를 skill로 증류
- `save-memory` — 타입형(user/feedback/project/reference) 영속 메모

**Layer 3 — MCP 격리 (디렉토리 기반)**
- 서브모듈별 `.claude/settings.json` → 해당 도메인 MCP만 로드
- 디렉토리 진입 시 자동 격리 (Claude Code 기본 동작)
- **MCP toggle 스크립트(섹션 4 방식 C)는 불필요** — 디렉토리 격리가 그 역할

### 추가 도구 우선순위

| 우선 | 도구 | 목적 |
|---|---|---|
| 1 | Exa MCP 또는 네이티브 WebSearch | AI 최적화 웹 서치 |
| 2 | OMC `wiki` 스킬 | 영속 지식 (즉시 사용 가능) |
| 3 | `deepinit` 스킬 | 계층적 AGENTS.md 생성 |
| 선택 | Obsidian MCP | 기존 vault 있을 때만 |
| 미적용 | LightRAG | 공식 MCP 없음, wiki로 대체 가능 |

### Anthropic 미구현 이슈와 우회

| Anthropic 이슈 | 우회 |
|---|---|
| #16177 (sub-agent MCP) | 서브모듈 디렉토리 격리 + 인라인 `mcpServers` |
| #4476 (Agent-Scoped MCP) | OMC team 모드 + 각 teammate를 다른 디렉토리에서 기동 |
| #32514 (agent identity) | AGENTS.md 계층으로 컨텍스트 구분 |

---

## 12. 개발환경 실전 교훈 (2026-04-20)

### 필수 설치 (쉽게 빠뜨림)
- `xclip` + `xsel` — wezterm X11 클립보드 연동. **미설치 시 복사/붙여넣기 무음 실패**
- `tmux` 3.2+ — 3.0 미만은 일부 바인딩 문법 다름
- `~/.tmux.conf` 없으면 마우스 휠 스크롤 안됨. 최소 설정 필요:
  ```
  set -g mouse on
  set -g history-limit 50000
  set -g default-terminal "tmux-256color"
  set -ga terminal-overrides ",xterm-256color:RGB"
  ```

### wezterm 마우스 바인딩 주의
- `config.mouse_bindings`에 항목을 하나라도 지정하면 **기본 바인딩을 덮어쓰는 현상** 보고됨
- 드래그 자동 복사를 원하면 `CompleteSelection 'ClipboardAndPrimarySelection'`를 명시적으로 추가
- 기본 설정 예시: `~/.config/wezterm/wezterm.lua`의 `config.mouse_bindings` 블록 참조

### 한국어 IME + tmux 주의
- wezterm `use_ime=true` + IBus: **한글 모드에서 일부 Ctrl 조합 간섭 가능**
- 영문 모드로도 해결 안 되는 경우 있음 (미해결 사례: `.memory/project_tmux_prefix_unresolved.md`)
- 워크어라운드: `tmux` 명령을 직접 호출 (`tmux split-window -h`, `tmux detach` 등)

### OMC 글로벌 설치 시 묻는 것
- 설치 범위: **Global**
- 실행 모드 기본값: **ultrawork**
- 팀 모드: **Yes + tmux**
- 기본 에이전트 수: **3** (Pro 플랜 적정선)
- 기본 provider: **claude** (Gemini/Codex는 명시 호출 `team 3:gemini`)

### ~/.claude 구조 (글로벌 설치 후)
```
~/.claude/
├── CLAUDE.md              # OMC 글로벌 설정 (OMC:START~OMC:END 마커)
├── settings.json          # statusLine, enabledPlugins, teammateMode, env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
├── .omc-config.json       # defaultExecutionMode, team 기본값
├── hud/
│   ├── omc-hud.mjs        # HUD 래퍼 스크립트
│   └── lib/config-dir.mjs
├── skills/omc-reference/  # 글로벌 참조 skill
└── plugins/cache/omc/...  # 플러그인 캐시
```

### MCP 구성 위치 (우선순위 순)
1. 프로젝트: `<project>/.mcp.json` (DATAFACTORY가 이 방식)
2. 프로젝트: `<project>/.claude/settings.json` 의 `mcpServers`
3. 글로벌: `~/.claude/settings.json` 의 `mcpServers`

서브모듈에서 로컬 `.mcp.json`이 있으면 해당 MCP만 활성 — 이게 섹션 3 설계의 핵심.
