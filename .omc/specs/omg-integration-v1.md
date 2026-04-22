# OmG Integration Specification v1.1 (DATAFACTORY)

## 1. Scope
본 문서는 DATAFACTORY 프로젝트에서 Claude Code(OMC)와 Gemini CLI(OmG) 간의 책임 분리(SoC) 및 상호운용성 프로토콜을 규정한다.

## 2. 책임 경계 및 운용 규약

### 2.1 중복 커맨드 충돌 회피 규칙
(v1.0과 동일, 생략 가능하나 무결성을 위해 유지)
| Command | Primary Lane | 근거 |
| :--- | :--- | :--- |
| `team` | **Claude** | 최종 의사결정 및 실행 오케스트레이션은 고정밀 추론 필요 |
| `ralph` | **Claude** | V&V 기반의 고정밀 논리 플래닝은 Claude가 우세 |
| `ultrawork` | **Gemini** | 대량의 리포 스캔 및 초안 생성 시 토큰 효율 극대화 |

### 2.2 역할 분담 (Role Matrix)
- **OmG (Gemini)**: Deep Scanner, Doc Grounder, Context Compressor, TDD Boilerplate.
- **OMC (Claude)**: Architect, Executor, Final Verifier, State Manager.

### 2.3 Skill vs Command 구분 규약
OmG 확장의 54개 항목 중 다음 9종은 커맨드가 아닌 **자동 활성화 Skill**임에 유의한다.
- **대상**: `research`, `context-optimize`, `deep-dive`, `execute`, `learn`, `omg-plan`, `plan`, `prd`, `ralplan`

### 2.4 Gemini 연구 트리거 정식 경로
OMC 세션에서 Gemini를 통한 연구/조사를 실행하는 경로는 다음 3가지로 제한한다.
| 경로 | 실행 방식 | 용도 |
| :--- | :--- | :--- |
| **(A) Skill Trigger** | 자연어 프롬프트 내 연구 키워드 포함 | 일상적인 정보 수집 및 API 조회 |
| **(B) Team Assembly** | `/omg:team-assemble` 커맨드 호출 | `researcher` 에이전트 레인 구성 및 팀 단위 과업 |
| **(C) Direct Persona** | `agents/researcher.md` 페르소나 직접 지정 | 특정 리서치 과업에 대한 정밀한 페르소나 주입 |

## 3. 핸드오프 프로토콜 (Handoff Protocol)
- 브릿지 스크립트 v2 사용: jq 파싱, URL HTTP 검증, 타임스탬프 강제 주입 포함.

## 4. Changelog
- **v1.1**: Skill/Command 구분 명시 및 연구 트리거 경로 3종(A/B/C) 확정. (2026-04-22)
