# save-memory

현재 세션의 진행사항, 교훈, 결정사항을 메모리 파일에 저장합니다.
컴팩트 직전이나 세션 종료 전에 호출하세요.

## 저장 대상 판단 기준

저장할 것:
- 이번 세션에서 새로 발견한 환경/API/툴 quirk (코드나 git history에 없는 것)
- Phase 상태 변화 (완료, 진행 중, 블로커 발생)
- 중요한 결정과 그 이유
- 반복되는 실수 패턴 → 다음 세션에서 피해야 할 것

저장하지 않을 것:
- 코드 패턴 (코드 자체에 있음)
- AGENTS.md나 git history로 복원 가능한 것
- 이번 세션의 일시적 작업 상태

## 메모리 파일 위치

**프로젝트 메모리** (프로젝트 루트 기준, `git rev-parse --show-toplevel`로 확인):
- `.memory/MEMORY.md` — 인덱스 + 현재 프로젝트 상태 (날짜 업데이트 필수)
- `.memory/lessons_environment.md` — Ubuntu/Docker/개발환경 교훈
- `.memory/lessons_isaac_sim.md` — Isaac Sim API/컨테이너 교훈
- `.memory/lessons_docker.md` — Docker Compose 교훈
- `.memory/lessons_mcp.md` — MCP 연동 교훈
- 새 카테고리가 필요하면 `.memory/lessons_<카테고리>.md` 생성

**Claude Code 자동 메모리** (머신마다 경로가 다름, 아래 명령으로 확인):
```bash
ls ~/.claude/projects/$(echo -n "$(git rev-parse --show-toplevel)" | python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read(),'').replace('%','\\x').lower())" 2>/dev/null || echo "<경로 수동 확인 필요>")/memory/
```
또는 `~/.claude/projects/` 아래에서 현재 프로젝트에 해당하는 디렉토리를 찾아 `memory/` 서브디렉토리를 사용하세요.

## 실행 절차

1. 현재 세션 대화를 검토하여 저장할 내용 목록 작성
2. 기존 메모리 파일 읽기 (중복 방지)
3. 각 정보를 적절한 파일에 추가/수정
4. `.memory/MEMORY.md` 인덱스의 날짜와 "현재 프로젝트 상태" 섹션 업데이트
5. 저장한 내용 요약 보고

## Claude Code 자동 메모리 파일 형식

```markdown
---
name: 메모리 이름
description: 한 줄 설명 (미래 세션에서 관련성 판단에 사용)
type: user | feedback | project | reference
---

내용. feedback/project 타입은 아래 구조 사용:

**Why:** 이유
**How to apply:** 적용 방법
```

저장할 내용이 없으면 "이번 세션에서 새로 저장할 내용 없음"이라고 명확히 보고합니다.
