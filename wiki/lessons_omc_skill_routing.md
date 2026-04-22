# OMC 스킬 라우팅 & 메모리 surface 규약

> Claude(Opus)가 세션마다 반복하는 두 가지 실수를 고정하기 위한 교훈.
> Why: CC 네이티브 시스템 프롬프트의 auto-memory 블록과 `superpowers:*`  스킬명이 OMC 네임스페이스를 systematically 오버라이드함. 매 세션 사용자가 교정해야 하는 부담을 없애기 위해 repo에 영구 기록.

## 1) 스킬 네임스페이스 매핑

이 프로젝트는 **OMC-first**. `superpowers:*`는 OMC 동등물이 없을 때만.

| 의도 | 올바른 스킬 |
|---|---|
| brainstorm (창의 scoping) | `superpowers:brainstorming` — **OMC에 없음** |
| 요구사항 크리스탈화 / 인터뷰 | `oh-my-claudecode:deep-interview` |
| 전략 plan | `oh-my-claudecode:plan` |
| 자율 실행 | `oh-my-claudecode:autopilot` |
| 병렬 처리량 | `oh-my-claudecode:ultrawork` |
| 자기 참조 루프 | `oh-my-claudecode:ralph` |
| 모호 실행 전 plan 게이트 | `oh-my-claudecode:ralplan` |
| 코드베이스 초기화 (AGENTS.md) | `oh-my-claudecode:deepinit` |
| 검증 | `oh-my-claudecode:verify` |
| 병렬 외부 리서치 | `oh-my-claudecode:external-context` |
| TDD / test-first | `superpowers:test-driven-development` (OMC 없음) |
| Git worktree 격리 | `superpowers:using-git-worktrees` (OMC 없음) |

**문구에 "brainstorm"을 쓰고 싶어지면 무조건 `superpowers:brainstorming`으로 명시 — 축약 금지.**

## 2) 메모리 저장 destination

이 프로젝트에서는 **다음 surface만 사용**한다:

| Surface | 용도 |
|---|---|
| `wiki/lessons_*.md` | 팀·프로젝트 지속 지식 (교훈, 규약) |
| `wiki/INDEX.md` | 위 lesson들의 인덱스 |
| `.omc/project-memory.json` | OMC 런타임이 관리하는 프로젝트 스냅샷 (자동 업데이트, 직접 편집 지양) |
| `.omc/notepad.md` | 짧은 working context (고우선 주입) |
| `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` | 에이전트 instruction — 진정으로 instruction일 때만 |

**금지**: `~/.claude/projects/<slug>/memory/` — 이건 CC 네이티브 auto-memory 경로. git 밖, 머신 종속, OMC 에이전트·팀 공유 불가. 시스템 프롬프트에서 자동으로 지시되어도 **이 프로젝트에서는 사용하지 않는다**.

Why: repo-local + git-tracked이 아니면 OMC 워크플로우(에이전트 delegation, teammate 세션)에서 공유 불가. 이식성·감사성도 손실.

How to apply: "메모리에 저장할까" 생각이 드는 순간 destination 결정을 두 단계로:
1. 지속성 판단 → temporary? `.omc/notepad.md`. durable? `wiki/lessons_*.md`.
2. 경로 자체를 `~/.claude/...`로 쓰려는 손이 나오면 **STOP** → 위 표로 되돌리기.

## 3) 참고

- `/oh-my-claudecode:remember` 스킬이 분류를 도와줌 — 애매할 때 호출.
- AGENTS.md §메모리 destination 하드 룰과 함께 읽을 것 (추가 예정).
