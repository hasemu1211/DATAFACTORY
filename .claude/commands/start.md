---
description: DATAFACTORY 세션 진입 디스패처 (.omc/skills/start.md 실행)
---

사용자가 `/start`를 명시적으로 호출했습니다. `.omc/skills/start.md`의 지침을 그대로 따라 세션 진입 디스패처를 실행하세요.

- 스킬 파일: `/home/codelab/Desktop/Project/DATAFACTORY/.omc/skills/start.md`
- 먼저 해당 파일을 Read로 로드한 뒤, 거기 명시된 입력 스캔 · 판정 · 라우팅(resume / kickoff / stale-hint / infra-only / ambiguous) 순서를 지킬 것.
- 추가 인자: $ARGUMENTS
