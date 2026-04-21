# Deep Interview Spec: Robot OMC Role-Scoped Distillation

## Metadata
- Interview ID: `robot-omc-role-scoped-distillation-20260420`
- Rounds: 5 (Round 1-2 + 문서 확인 + Round 3-5 Critical 보강)
- Final Ambiguity Score: **18%** (threshold 20% 이하, 공백 12개 재반영 후)
- Type: brownfield
- Generated: 2026-04-20 (revised)
- Threshold: 0.20
- Status: **PASSED (revised)**
- Meta-criteria (모든 결정 평가 기준): OMC-native / 장기유지 / 토큰효율 / 효율성

## Clarity Breakdown

| Dimension | Score | Weight | Weighted | 이전 (초안) |
|---|---|---|---|---|
| Goal Clarity | 0.90 | 0.35 | 0.315 | 0.90 |
| Constraint Clarity | 0.65 | 0.25 | 0.163 | 0.70 (공백 12개 미반영) |
| Success Criteria | 0.80 | 0.25 | 0.200 | 0.80 |
| Context Clarity | 0.95 | 0.15 | 0.143 | 0.95 |
| **Total Clarity** | | | **0.820** | 0.833 |
| **Ambiguity** | | | **0.18** | 0.167 (blind) |

초안 17% → 공백 재인식 후 ~35% → Round 3-5 Critical 3개 해결 후 **18%**.

## Goal

**로봇 parent(`~/robot/`) + children(datafactory + 이후 신규)에 걸쳐, 역할별로 MCP·플러그인·도구를 비대칭 분리하는 OMC-native 프로파일을 증류한다.** 기획단(main Claude)은 search/docs/NotebookLM-CLI 중심 research 도구만 상시 활성화하고, 서브에이전트(Agent 툴 / tmux pane / optional custom class)는 담당 도메인 MCP(isaac-sim 또는 ros-mcp)만 스코프로 받아 결과만 기획단에 리포팅한다. 기존 `robot-dev-omc-setup-guide.md` §3-5, §11에 이미 설계된 디렉토리 격리 + 인라인 `mcpServers` 패턴을 OMC-native 스킬/훅으로 번역하여 모든 child에 드롭-인 적용 가능하게 만든다.

## Constraints

- **역할별 MCP 금지 교차**: 기획단에 isaac-sim/ros-mcp 직접 붙이지 않음. 서브에이전트에 context7/exa/NotebookLM-CLI 등 research 도구 붙이지 않음.
- **on/off 메커니즘 = 디렉토리 격리** (setup-guide §11 명시): 별도 `/robot:mcp-on/off` slash command 만들지 않음. `.claude/settings.json` + `.mcp.json`의 위치(parent vs child vs subagent-cwd)가 스코프 결정.
- **OMC-native 유지**: 새 agent class·스킬은 `skill-creator` / agent definition 표준을 따르고 OMC 업스트림과 drift 최소화. OMC-fork 금지.
- **이식성 단위 = `bootstrap-child.sh`**: 새 child 등록 시 이 스크립트 하나가 2-tier wiki hook + `.mcp.json` 템플릿 + `.claude/settings.json` 템플릿을 동일하게 설치.
- **Anthropic 미해결 이슈(#16177 #4476 #32514)는 우회 전제**: 우회 3종(디렉토리 격리 / 인라인 `mcpServers` / omc-teams tmux) 중 디렉토리 격리가 default.
- **NotebookLM CLI는 MCP 아닌 독립 Python CLI**: `python3 -m notebooklm ...` 호출로 사용. Bash tool 권한이면 충분. 기획단에서만 호출.
- **현재 범위 = parent + datafactory 1 child**: N future children 시간 최적화는 비목표 (단, bootstrap 패턴은 신규 child에 재사용 가능해야 함).

### Round 3-5 Critical 결정사항

- **Docker = Bash-only (MCP 미도입)** (Round 3): `docker compose up/down`, `docker logs`, `docker ps` 모두 기획단의 Bash 직접 실행. Docker MCP 플러그인은 skip (setup-guide §3 "Docker MCP 상시" 원안은 **reject** — 토큰·drift 절감, datafactory Phase 1 smoke가 이미 Bash docker로 통과). 장수명 state 변경(compose down 전 rollback 등)은 필요 시 docker-operator 서브에이전트로 격리 옵션 열어두되 default 아님.
- **Git = 기획단 phase/feature atomic commit** (Round 4): 서브에이전트는 파일 변경만, commit 책임은 기획단. 여러 Agent 결과를 누적한 뒤 `superpowers:receiving-code-review` → `superpowers:finishing-a-development-branch` → phase 단위 atomic commit. 기존 `~/robot/` commit 스타일(f681100, 5df7f8d, de395ca)과 일치. git-mcp 도입 안 함 (Q2 survey 결정 유지). worktree 격리는 병렬 experiment 브랜치에만 옵션.
- **Cross-tier 데이터 흐름 = Return-value only (단방향)** (Round 5): 서브에이전트는 Agent return 텍스트 단일 채널로 보고. `notepad_*`, `wiki_*`, `shared_memory_*`, `project_memory_*` 접근 **차단** — 서브에이전트 allowedTools에서 전부 제외. 영속화(증류/학습/기록)는 전적으로 기획단 책임 (return value 파싱 → `wiki` / `remember` / `learner` / `skillify` 스킬로 처리). Race condition·권한 분산 위험 제거.

## Non-Goals

- 새 child 부트스트랩 시간 최적화 (Round 2에서 배제 확인).
- `/robot:mcp-on` 류 런타임 MCP 토글 slash command (setup-guide §11: 디렉토리 격리로 대체).
- Doc-driven config 자동화(AGENTS.md 파싱 → MCP 설정 자동 동기화).
- CI/hook 기반 drift 자동 감지.
- Anthropic 이슈 #16177/#4476이 closed 되기 전까지 "agent-scoped MCP 공식 지원"을 전제로 한 설계.
- Gazebo/MoveIt/PyBullet MCP 자체 구현 (존재하지 않음, 필요 시 별도 프로젝트).

## Acceptance Criteria

- [ ] **AC-1 (토큰 예산)**: child 세션 SessionStart 주입 컨텍스트 측정치 공개(현재값 기록). 이후 증류로 감소 입증 — 감소량은 목표 < 5k tokens/session 지향하되 기능 손실 없을 것.
- [ ] **AC-2 (Agent 호출 토큰)**: 서브에이전트 평균 호출당 토큰 ≥ 30% 감소 (현재 baseline: hook log로 측정). research 도구를 서브에이전트에서 배제함으로써 자연 감소.
- [ ] **AC-3 (기능 재현성)**: 기존 DATAFACTORY Phase 1 smoke (Isaac Sim MCP 8766 + rosbridge 9090 + `execute_script` 4.5.0 round-trip)를 새 역할-분리 구조로 재실행 → 동일 결과. Phase 2-4 다음 단계 블록 없이 진행 가능.
- [ ] **AC-4 (문서/Agent 계약 종결)**: `~/robot/wiki/omc_robot_profile.md` 작성 완료 — 기획단 tools/MCPs 리스트, 서브에이전트 type별 `allowedTools` + `mcpServers` 계약, NotebookLM CLI 역할, 3-Layer 구조 요약, 이식 절차.
- [ ] **AC-5 (서브에이전트 scope 위반 테스트)**: isaac-operator Agent에 `context7` 도구 요청 → 거부. 기획단에 `isaac-sim` MCP 직접 호출 → 거부 또는 경고.
- [ ] **AC-6 (이식 smoke)**: 가상의 신규 child(예: `~/robot/scratch-lab`)에 `bootstrap-child.sh` 실행 → 2-tier wiki hook + `.mcp.json` 템플릿 + `.claude/settings.json` 템플릿 배치 확인. 실제 MCP 연결 smoke까지는 child별 맞춤 필요(비목표).
- [ ] **AC-7 (NotebookLM 유틸 캡처)**: NotebookLM CLI 활용 워크플로우를 wiki에 1페이지 내 요약 (기획단만 호출, 활성 노트북 ID, 기본 명령 5개).
- [ ] **AC-8 (MCP/Skill 대안 검토)**: 현재 사용 중인 `isaac-sim-mcp`(8766) 및 `ros-mcp`(rosbridge 9090)의 alternative 후보를 정리하고 전환 비용/이점 판정을 `wiki/omc_robot_profile.md`에 기록. 또한 로봇 워크플로우에 직접 유용하나 아직 도입 안 된 skill/MCP를 최소 3개 shortlist(adopt/trial/watch 구분). Q2 `ecosystem_survey.md` §C + §A를 baseline으로 사용하되 2026-04 기준 최신 후보(Robosynx/Isaac Monitor, NVIDIA forum MCP tutorial, lpigeon/ros-mcp-server, hijimasa/isaac-ros2-control-sample) 교차 검증.

## Assumptions Exposed & Resolved

| Assumption | Challenge | Resolution |
|---|---|---|
| "notebookcli"는 Jupyter나 OMC notepad일 것 | Round 3에서 3-way options 제시 | 실제는 Google NotebookLM CLI — datafactory `notebooklm-cli-guide.md`에 이미 사용법 문서화 |
| 서브에이전트는 하나의 구현(Agent 또는 tmux)으로 통일해야 | Round 1에서 4-way options (Agent/tmux/custom/hybrid) | **Hybrid 채택** — default = Agent + inline mcpServers, 장시간/물리 격리 = tmux team, 반복 패턴 = custom class로 증류 |
| 역할별 MCP on/off = slash command 또는 env var 토글 | Round 3 question (중단) + setup-guide §11 확인 | **디렉토리 격리가 toggle을 대체** — 추가 메커니즘 불요 |
| 이 작업의 "완료"는 단일 지표로 측정 | Round 2 multiSelect | **3-지표 조합**: 토큰 예산 + 기능 재현성 + 문서/계약 종결. 시간 지표는 비목표. |
| Docker MCP를 기획단에 상시 로드 (setup-guide §3 원안) | Round 3에서 Bash-only로 재검토 | **Docker MCP reject** — Bash docker로 충분, 토큰/drift 절감 우위. setup-guide §3은 대안으로만 남김. |
| 서브에이전트가 commit 해도 무방 | Round 4 4-way options + 메타기준 대조 | **기획단 phase/feature atomic commit만** — 서브에이전트는 file 변경만, commit은 superpowers:finishing-a-development-branch로 종결 |
| 서브에이전트가 notepad/wiki 등 영속화 도구 접근 가능 | Round 5 4-way options | **Return-value only (단방향)** — 서브에이전트 allowedTools에서 `notepad_*`/`wiki_*`/`shared_memory_*`/`project_memory_*` 전부 제외, race 제거 |
| 새 `/robot:*` 커스텀 스킬 4개 모두 만들어야 | (미해결, omc-plan 단계로 이월) | omc-plan 단계에서 Priority 1/2/3 분류 재평가 — highest leverage는 `/robot:promote` |

## Technical Context

### Brownfield 상태 (setup-guide + notebooklm-cli-guide에서 확정)

**이미 완료**:
- `~/robot/` parent repo + `~/robot/datafactory/` symlink (DATAFACTORY)
- 2-tier wiki (global + local) + SessionStart hook
- `.mcp.json`에 isaac-sim (8766) + ros-mcp (9090) + context7 + github-mcp
- NotebookLM CLI: 활성 노트북 `7cf81435-cc9d-419e-8dfa-fe88c02dfa42` (Isaac Sim and Robotics Simulation DATAFACTORY)
- `bootstrap-child.sh` + `promote.sh`
- BLOCKING smoke: Isaac Sim MCP + rosbridge + execute_script 4.5 round-trip
- tmux teammate 모드 설정 (`teammateMode: tmux`, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

**현재 범위 작업**:
- 역할별 MCP/tool 매핑을 `wiki/omc_robot_profile.md`로 수록
- 서브에이전트 type별 allowedTools + mcpServers 계약 명시
- 기획단 research-tool 번들 정의 (NotebookLM CLI 포함)
- 기능 재현 smoke 재실행 (새 역할-분리 구조로)

### 3-Layer 구조 (setup-guide §11에서 승계)

1. **Layer 1 (정적)**: AGENTS.md + CLAUDE.md + SessionStart hook — 도메인 규칙 주입
2. **Layer 2 (동적 스킬)**: `wiki`, `remember`, `external-context`, `learner`, `skillify` — 세션 중 호출
3. **Layer 3 (MCP 격리)**: 디렉토리 기반 — `.claude/settings.json` + `.mcp.json`의 cwd가 스코프 결정

### 기획단 vs 서브에이전트 도구 매트릭스 (Round 3-5 반영 확정)

| 계층 | 플러그인/스킬 | MCP 서버 | 비MCP 도구 | 영속화 권한 |
|---|---|---|---|---|
| **기획단 (main Claude)** | oh-my-claudecode(`wiki`, `remember`, `external-context`, `ralplan`, `plan`, `verify`, `cancel`, `learner`, `skillify`, `trace`, `deep-interview`), superpowers(`tdd`, `receiving-code-review`, `finishing-a-development-branch`, `using-git-worktrees`), skill-creator | context7, github-mcp, (선택) exa | Bash (`docker compose`, `docker logs`, `docker ps`, `git *`, NotebookLM CLI, 일반 shell), Read/Edit/Write, WebSearch/WebFetch | `notepad_*`, `wiki_*`, `shared_memory_*`, `project_memory_*` **전부 허용** — 증류·commit 책임자 |
| **서브에이전트 (domain)** | 없음 (OMC 스킬·superpowers 차단 — research·workflow 도구 제외) | **per-type 1개만**: isaac-operator → `mcp__isaac-sim__*` / ros2-operator → `mcp__ros-mcp__*` / (옵션) docker-operator → 없음, Bash만 | Bash(domain-scoped: Isaac/ROS CLI 등), Read/Edit. `git commit` **금지**, `docker compose up/down` **비권장**(기획단 기본) | **전부 차단** — Return value 단방향만 |

**경계 테스트 (AC-5)**:
- isaac-operator에 `mcp__context7__*` 요청 → 거부
- isaac-operator에 `notepad_write_working` 요청 → 거부
- 기획단이 `mcp__isaac-sim__execute_script` 직접 호출 → 경고 (스코프 위반, 서브에이전트 delegate 권장)

### MCP / Skill 대안 검토 (AC-8 baseline, Q2 `ecosystem_survey.md` 요약)

#### Isaac Sim MCP 대안
| 후보 | 상태 | 평가 | 판정 |
|---|---|---|---|
| 현재: `isaac-sim-mcp` (port 8766, mcp 1.27 패치 완료) | 운영 중, Phase 1 smoke PASS | 우리 스택 검증 | **stay** |
| NVIDIA-Omniverse/IsaacSim-MCP (공식?) | 존재 불분명 (2026-04 시점) | Q2 확인 필요 | **investigate** (Ralplan Planner) |
| 직접 `omni.kit.exec_script` MCP wrapper | 더 얇은 wrapper, extension 활성화 회피 | 우리 `wiki/mcp_lessons.md` 교훈과 겹침 | **watch** |
| Robosynx / Isaac Monitor (2026-04 공개 full-stack) | 상용/OSS? 미확인 | AC-8에서 investigate | **investigate** |

#### ROS2 MCP 대안
| 후보 | 상태 | 평가 | 판정 |
|---|---|---|---|
| 현재: `ros-mcp` via rosbridge 9090 | 운영 중, `connect_to_robot`/`get_topics` 검증 | 포터블 | **stay** (default) |
| `robotmcp/ros-mcp-server` | rosbridge 기반 공식 커뮤니티 | 우리와 동일 패턴, 대안은 아님 | **reference only** |
| `lpigeon/ros-mcp-server` | fork/variant | 차별점 불명 | **investigate** |
| 직접 rclpy MCP wrapper (rosbridge 없음) | 낮은 레이턴시, 환경 coupling 높음 | 고주파 토픽 필요 시에만 | **revisit when needed** |
| `hijimasa/isaac-ros2-control-sample` | Isaac + ros2_control 유틸 | MCP 아닌 샘플 코드; reusable | **cherry-pick** |

#### 로봇 워크플로우용 추가 skill/MCP shortlist
| 후보 | 판정 | 근거 |
|---|---|---|
| `superpowers:test-driven-development` | **adopt** (기획단) | 제어/비전 알고리즘 TDD, OMC 유니크 |
| `oh-my-claudecode:visual-verdict` | **trial** (기획단) | Isaac 렌더 frame 회귀 검증 (Phase 2+ 확장) |
| `oh-my-claudecode:configure-notifications` | **trial** (기획단) | 장시간 Replicator/훈련 run 완료 알림 |
| Exa MCP | **trial** (parent scope) | ecosystem 조사 semantic depth (Q2 결정 이월) |
| Docker MCP Toolkit | **skip** (Round 3 reject) | Bash로 충분, drift 회피 |
| `filesystem MCP` per-child | **watch** | 특정 child가 외부 데이터셋 디렉토리 접근 필요 시 |

**Open investigation (Ralplan Planner가 잡음)**:
- NVIDIA Developer Forum "Setting up MCP server using Claude on Linux for Isaac Sim" 튜토리얼 crosscheck → 우리 `wiki/mcp_lessons.md`와 diff
- Robosynx/Isaac Monitor 라이선스·architecture 확인
- Context7 `resolve-library-id("isaac-sim")` / `("ros2")` coverage 감사

## Ontology (Key Entities)

| Entity | Type | Fields | Relationships |
|---|---|---|---|
| 기획단 (Planning tier) | core domain | main-session cwd, loaded-plugins, loaded-mcps, research-tools | delegates to 서브에이전트; reads from wiki; calls NotebookLM CLI |
| 서브에이전트 (Sub-agent tier) | core domain | agent-type, allowedTools, mcpServers, cwd | receives delegation from 기획단; reports via return value |
| NotebookLM CLI | supporting tool | notebook-id, session-auth, commands | called by 기획단 only (Bash) |
| MCP 서버 | external system | name, command, port, cwd-scope | attached per-role via `.mcp.json` location |
| Agent 계약 | supporting | allowedTools[], mcpServers{}, model | bound to agent-type |
| Wiki (2-tier) | supporting | global-index, local-index, topics | read/written via `wiki` skill; promotion via `promote.sh` |
| Bootstrap 스크립트 | supporting | `bootstrap-child.sh`, `promote.sh` | 신규 child 등록 시 실행 |
| `robot-dev-omc-setup-guide.md` | supporting doc | 13 sections, troubleshooting, 체크리스트 | 이 spec의 상위 설계 문서 |
| `notebooklm-cli-guide.md` | supporting doc | 명령 레퍼런스, 역할 분담표 | NotebookLM CLI 사용법 canonical |
| Anthropic 이슈 #16177/#4476/#32514 | external blocker | open status, 우회 3종 | constraint source |

## Ontology Convergence

| Round | Entity Count | New | Changed | Stable | Stability Ratio |
|---|---|---|---|---|---|
| 1 | 6 | 6 | - | - | N/A |
| 2 | 8 | 2 | 0 | 6 | 75% |
| Doc-check | 10 | 2 | 0 | 8 | 80% → **100% (converged)** |

Entity 모델 안정적 — 추가 round로 엔티티가 재정의될 가능성 낮음.

## Interview Transcript

<details>
<summary>Full Q&A (2 rounds + doc confirmation)</summary>

### Round 1 | Targeting: Goal Clarity | Ambiguity: 60.5% → 57%
**Q:** 당신이 말한 '서브에이전트'는 지금 어떤 실체에 매핑됩니까? (OMC Agent / omc-teams tmux / 신규 robot agent class / hybrid)
**A:** 혼합(상황별)
**Scores:** Goal 0.6, Constraints 0.3, Criteria 0.1, Context 0.8

### Round 2 | Targeting: Success Criteria | Ambiguity: 57% → 37%
**Q:** 이 증류가 '완료'를 제대로 정의하려면 어떤 상태를 검증해야 하나요? (multiSelect)
**A:** 토큰 예산 지표 + 기능 재현성 + 문서/Agent 계약(프로토콜) 종결 (3선택). "새 child 부트스트랩 시간"은 배제.
**Scores:** Goal 0.6, Constraints 0.4, Criteria 0.8, Context 0.8

### Round 3 | Targeting: Constraint + Goal | 중단됨
**Q:** 기획단의 '기본 공간 + on/off' 모델은? (OMC notepad / Jupyter kernel MCP / 그냥 Claude 대화창 / hybrid)
**A:** (사용자 중단) — "notebookcli = NotebookLM CLI. 관련 문서 확인하라. 의도는 역할별 MCP 분리."

### Doc-check (Round 3 대체)
**Action:** `datafactory/notebooklm-cli-guide.md` + `robot-dev-omc-setup-guide.md` 읽음.
**Resolution:** NotebookLM CLI 정체 확정, 역할별 MCP 분리 설계 setup-guide §3-5/§11에 이미 문서화됨을 확인. on/off 메커니즘은 디렉토리 격리로 이미 해결.
**Scores:** Goal 0.9, Constraints 0.7, Criteria 0.8, Context 0.95 → **Ambiguity 17% (blind, 공백 12개 미반영)**

### 공백 12개 재식별 (사용자 비판 후)
**Action:** Critical 3개(Docker/Git/Cross-tier) + High 4개 + Medium 3개 + Low 2개 = 12 gap 식별.
**Resolution:** Constraint 재평가 0.70 → 0.50 → 실제 **Ambiguity ~35%** (초안 낙관적 수렴이었음 실토).

### Round 3 | Targeting: Constraint (Docker) | Ambiguity: 35% → 33%
**Q:** Docker (container 조작: compose up/down, logs, ps)를 어떤 계층에 두시겠습니까?
**A:** Docker MCP 제거 + Bash만
**Rationale:** OMC-native ◎ (의존성 0) / 장기유지 ◎ (drift 없음) / 토큰 ◎ (MCP tool 등록 부담 0) / 효율 ○ (Bash stdout 파싱)
**Scores:** Goal 0.9, Constraints 0.50, Criteria 0.8, Context 0.95 → Ambiguity ~33%

### Round 4 | Targeting: Constraint (Git) | Ambiguity: 33% → 20.5%
**Q:** Git workflow를 어떤 모델로 가겠습니까? (commit 책임자·시점·worktree 전략)
**A:** 기획단 phase/feature atomic commit (추천)
**Rationale:** superpowers native ◎ / 기존 commit 스타일 일치(f681100, 5df7f8d) ◎ / 중간 commit 노이즈 0 ◎ / git log 가독성 ◎
**Scores:** Goal 0.9, Constraints 0.55, Criteria 0.8, Context 0.95 → Ambiguity ~20.5%

### Round 5 | Targeting: Constraint (Cross-tier flow) | Ambiguity: 20.5% → 18%
**Q:** 서브에이전트가 기획단으로 데이터를 돌려보낼 때 어떤 채널을 허용하겠습니까?
**A:** Return-value only (단방향)
**Rationale:** Agent tool 기본 동작 ◎ / race 없음 ◎ / 서브 allowedTools 최소화 ◎ / 파싱 단순 ○
**Scores:** Goal 0.9, Constraints 0.65, Criteria 0.8, Context 0.95 → **Ambiguity 18% (PASSED, revised)**

</details>

## 관련 파일

- `datafactory/robot-dev-omc-setup-guide.md` — 상위 설계 문서 (13 sections)
- `datafactory/notebooklm-cli-guide.md` — NotebookLM CLI 사용법
- `~/robot/wiki/ecosystem_survey.md` — 2026-04-20 Q2 생태계 survey
- `~/robot/.omc/research/skill-gap-analysis-20260420.md` — 4 decisions (superpowers/Exa/shortlist/custom skills)
- Anthropic 이슈: #16177 / #4476 / #32514
