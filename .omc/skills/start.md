---
name: start
description: |
  DATAFACTORY 세션 진입 디스패처. 사용자가 `/start` 슬래시 커맨드를 **명시적으로** 입력한 경우에만 호출한다. repo 상태를 스캔해 resume / kickoff / stale-hint / infra-only / ambiguous 중 적절한 모드로 라우팅하고, 필요할 때만 컨테이너를 기동한다.

  호출 금지 신호: 사용자가 "start", "resume", "이어서", "다시", "세션 시작" 같은 **자연어만** 사용한 경우 — 이 스킬은 opt-in이고, 자연어만으론 부족하다. `/start` 문자열이 직접 포함되지 않으면 호출하지 않는다. 버그 조사·원샷 질문·문서 열람 같은 일상 요청에서도 호출 금지.
---

# start — DATAFACTORY 세션 진입 디스패처

이 스킬은 세션의 "어디서부터 시작할지"를 반복적으로 틀리는 문제를 해결한다. 매 세션마다 같은 git/상태 파일 조회를 다시 하고, 잘못된 기본값(항상 kickoff)으로 사용자를 오도하는 일을 없애는 게 목적이다.

## 호출 조건 (재확인)

사용자 메시지에 **정확히 `/start`** 이 포함된 경우에만 실행. 그 외엔 스킬을 invoke하지 않는다. 이 스킬은 kickoff 플로우가 사용자 대화 흐름을 가로막지 않도록 opt-in이다.

## 입력 스캔 (한 번의 병렬 호출)

다음을 **동시에** 읽는다. 중복 조회 금지.

1. `git status --short` + `git branch --show-current` + `git log -5 --oneline` + `git stash list`
2. `.omc/plans/` 디렉터리 listing (존재 여부와 파일명만)
3. `.omc/state/session-resume-hint.json` (있으면)
4. `AGENTS.md` §Phase 현황 (Phase 테이블 블록만)

`.omc/state/sessions/`, `wiki/INDEX.md`는 필요 시에만 추가 조회 — 대부분의 분기 결정은 위 4종으로 충분하다.

## 판정에 쓰는 값

```
dirty_tree      = git status --short이 비어있지 않음
on_feature      = current branch != main
active_plan     = .omc/plans/ 안에 *.md 파일이 존재하고, 그 중 하나 이상에 미완료 체크박스("- [ ]")가 남아있다
hint_exists     = .omc/state/session-resume-hint.json 파일이 존재하고 JSON 파싱 성공
hint_age_days   = today - hint.last_session_date (hint_exists일 때만)
docs_only_dirty = dirty_tree이고, 모든 변경 파일이 *.md / wiki/ / AGENTS.md / CLAUDE.md / GEMINI.md / .gitignore
```

판정을 단순화하기 위해 "AGENTS.md의 Phase가 hint보다 앞섰는가"는 보지 않는다. 파싱 비용 대비 이익이 작다. 대신 시간 기반 stale만 쓴다.

## 모드 판정 — 우선순위 순

다음 순서로 평가하고, 처음 매치되는 모드를 선택한다. (여러 조건이 겹쳐도 위에서 끊어 내려온다.)

1. **stale-hint** — `hint_exists AND hint_age_days > 14` → 먼저 hint의 유효성을 의심한다. 상태 파일이 거짓말이면 다른 판정이 전부 어긋난다.
2. **resume** — `dirty_tree OR on_feature OR active_plan` → 진행 중이던 작업을 끊지 않는다.
3. **infra-only** — `docs_only_dirty` (resume보다 나중이지만 여기서도 걸림. 위 resume에서 먼저 잡히지 않게 하려면 docs_only_dirty일 때는 resume 조건에서 제외) — 즉 **resume 조건을 체크할 때 `docs_only_dirty`면 dirty_tree는 무시**한다.
4. **kickoff** — `hint_exists AND hint_age_days <= 14 AND !dirty_tree AND branch==main` → 깨끗한 main, 신선한 hint.
5. **ambiguous** — 위 어느 것도 만족하지 않음. 사용자에게 한 번 물어본다.

우선순위를 이렇게 잡은 이유: hint가 썩었을 때는 다른 조건이 무의미하기 때문에 **가장 먼저** stale을 걸러낸다. resume은 가장 흔한 "잘못된 자동 kickoff"의 원인이라 kickoff보다 앞선다.

## 모드별 흐름

### resume

1. 다음을 5줄 이내로 요약:
   - 현재 브랜치, 미커밋 파일 수, stash 개수
   - 활성 plan 파일 경로(첫 하나) — 없으면 생략
   - 마지막 커밋 2건 제목
2. 컨테이너는 건드리지 않는다. 사용자가 명시 요청하면 그때 `scripts/start-session.sh` 수동 호출.
3. 다음 액션을 **선택지**로 제시: "(a) plan 이어가기  (b) 새 방향  (c) 아직 모르겠음". (c)면 ambiguous로 다시 떨어진다.
4. `/oh-my-claudecode:deep-interview`는 호출하지 않는다.

plan 파일 포맷 가정: 체크박스(`- [ ]`/`- [x]`)가 있으면 그걸 썼고, 없으면 첫 5줄을 그대로 인용한다. 포맷이 정해져 있지 않으므로 깊게 파싱하지 않는다.

### kickoff

1. `bash scripts/start-session.sh` 실행. 사용자가 ROS2 필요를 명시하면 `--ros2` 플래그를 붙인다.
2. 종료코드 처리:
   - 0 → Step 0 통과
   - 1 → 사전조건 실패. 스크립트 stdout을 그대로 보여주고 중단.
   - 2 → 컨테이너 기동 실패. `docker compose -f docker/docker-compose.yml logs --tail 40` 실행해 요약.
   - 3 → MCP 타임아웃. `docker compose logs --since 5m` 실행해 요약.
3. MCP readiness 추가 확인 (S2 방어): `docker compose -f docker/docker-compose.yml logs --since 5m isaac-sim-streaming | grep -E "MCP server started|Full Streaming App is loaded"`. 두 문자열 중 하나라도 없으면 "TCP 포트는 열렸지만 MCP extension 로드 미확인" 경고를 띄운다.
4. 컨테이너가 스크립트 호출 이전부터 정상이었다면(E8) "이미 기동됨, Step 0 스킵"이라고 명시하고 3번 로그 확인만 수행.
5. Step 1 제안: `session-resume-hint.json`의 `kickoff_preflight_checklist[1]`에서 `command`와 `focus` 배열을 그대로 인용한다. 사용자가 명시적으로 "네, deep-interview 시작"이라고 답하기 전까지 deep-interview를 호출하지 않는다.

### stale-hint

1. 다음을 보여준다: hint의 `last_session_date`, hint age(일 단위), 가장 최근 커밋 날짜, hint가 지시하는 phase.
2. AGENTS.md §Phase 테이블을 **그대로** 인용 (파싱 없이).
3. 사용자에게 묻는다: "hint가 N일 전 상태입니다. 지금 작업은 (a) 같은 phase 이어가기 (b) 다음 phase로 진입 (c) 다른 작업 — 어느 쪽인가요?"
4. 답변으로 resume 또는 kickoff에 위임. (c)면 ambiguous로 떨어뜨리고 종료.
5. 세션 종료 시 hint를 갱신하라고 **기록만 남긴다** (실제 갱신은 이 스킬 밖 관심사).

### infra-only

1. 컨테이너 절대 건드리지 않음.
2. 변경 중인 md 파일 목록을 보여주고, "이 중 어느 것을 편집하시려는지"를 묻는다.
3. `/oh-my-claudecode:deep-interview`·kickoff 제안 금지.

### ambiguous

1. "resume / kickoff / infra-only / ad-hoc 중 하나를 골라주세요. 또는 구체적으로 뭘 하시려는지 한 줄로."라고 **한 번만** 묻는다.
2. 답을 받기 전엔 다른 액션 없음. 사용자가 자연어로 답하면 해당 모드로 위임.

## 정책 결정 (이전 열린 질문을 닫은 값)

- **버그 조사 신호(E2) 대응**: 사용자가 `/start` 직후 혹은 같은 메시지에서 "에러/깨짐/안 됨/안 켜짐" 같은 신호를 내면 **자동 위임하지 않고** "`superpowers:systematic-debugging` 스킬이 더 적합합니다. 이 스킬을 그대로 진행할까요, 디버깅으로 전환할까요?"라고 물어본다. 자동 스킬 체이닝은 하지 않는다.
- **stale threshold**: 14일로 고정. Phase 기간이 10일이라 이보다 짧으면 정상 세션도 stale로 오판, 이보다 길면 phase 전환을 놓친다. 추후 phase 평균 기간이 바뀌면 이 숫자를 수정하고 이 문서 커밋 메시지에 근거를 남긴다.

## 스크립트 계약

`scripts/start-session.sh`는 인프라만 담당한다. 이 스킬과 스크립트의 책임 분리:

- 스크립트: GPU·docker 사전조건 체크, 컨테이너 `up -d`, TCP readiness polling, 종료코드 리턴.
- 스킬(kickoff 모드): 스크립트 호출 + 로그 문자열 확인(S2) + 사용자 대화 + deep-interview 제안.

polling 도중 컨테이너가 죽는 경우(S6)는 스크립트 내부에서 `docker compose ps`를 주기 체크하거나, polling 타임아웃 후 스킬이 로그 요약으로 원인을 보여주는 것으로 충분하다. S6 방어를 스크립트에 녹일지 여부는 실사용 데이터 쌓이면 결정.

## OMC-first 규약 상기

- 스킬·커맨드 호출 시 네임스페이스 확인. 상세 매핑: `wiki/lessons_omc_skill_routing.md`.
- 메모리 destination: `wiki/lessons_*.md` / `.omc/project-memory.json` / `.omc/notepad.md` 중 하나. `~/.claude/projects/<slug>/memory/` 금지.
- `superpowers:*`는 OMC 동등물이 없을 때만 (예: `systematic-debugging`, `test-driven-development`).

## 성공 기준

- 사용자가 `/start` 직후 "이게 아닌데" 혹은 재지시를 해야 하는 횟수 0 수렴.
- kickoff 모드에서 사용자 추가 개입 없이 Step 0 완료까지 5분 이내(첫 빌드가 아닌 재기동 기준).
- deep-interview가 사용자의 "네" 없이 호출되는 일 0건.
- resume / infra-only에서 컨테이너가 기동되는 일 0건.

## 범용화 여지 (deferred)

본 스킬은 DATAFACTORY 고유 phase·컨테이너·포트를 참조한다. 다른 robot children 재사용은 `oh-my-claudecode:start-project`(가칭)로 별도 스킬화 — parameterization이 필요한 상태 감지 로직이 충분히 쌓인 후에.
