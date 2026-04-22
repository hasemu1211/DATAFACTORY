# GEMINI.md — Gemini Project Specifics (DATAFACTORY)

> **CRITICAL: 이 프로젝트의 모든 에이전트 조작은 `AGENTS.md`에 정의된 지침을 최우선으로 따릅니다.**
> `datafactory` 프로젝트 전용 Gemini 조작 지침입니다. 글로벌 지침(`~/robot/GEMINI.md`)을 먼저 숙지하십시오.

## 0. 핵심 지침 (Mandatory Mapping)
- **Primary Source of Truth**: 모든 세션 시작 시 `AGENTS.md`를 로드하고, 그곳에 명시된 **Phase 현황**과 **코딩 원칙**을 엄격히 준수할 것.
- **V&V 원칙**: 모든 결과 보고는 반드시 수식($\Delta t, K, R|t, \epsilon, U(a,b)$)과 지표로 표현하며, 정성적 표현("성능이 좋습니다" 등)은 배제함.
- **API 지침**: Isaac Sim 4.5.0 전용 API(`isaacsim.core.api`)를 반드시 사용하며, 구버전 API 사용을 금지함.

## 1. 프로젝트 컨테이너 정보
- **Isaac Sim**: `datafactory_isaac_sim`
  - 주요 포트: 8766 (MCP), 49100 (WebRTC Signaling)
  - 볼륨: `/data` (합성 데이터 저장), `/config` (환경 설정)
- **ROS2**: `datafactory_ros2`
  - 주요 포트: 9090 (Rosbridge WebSocket)
  - 네트워크: `host` 모드 사용 중

## 2. 프로젝트 전용 조작 가이드

### 2.1 데이터 생성 파이프라인
- `/data/scripts/generate.py`를 실행하여 headless 모드에서 대량의 데이터를 생성할 수 있음.
- 명령: `docker exec datafactory_isaac_sim /isaac-sim/python.sh /data/scripts/generate.py`

### 2.2 ROS2 토픽 조작
- `datafactory`는 주로 로봇 비전 데이터 파이프라인을 다룸.
- 이미지 토픽이나 센서 데이터를 구독할 때 `ros-mcp`를 활성화하여 실시간 모니터링 수행.

## 3. 프로젝트 특이사항
- 이 프로젝트는 `~/robot/`의 심볼릭 링크를 통해 배포판의 `vendor/isaac-sim-mcp`와 `external/robotics-agent-skills`를 공유함.
- 개발 단계에서 이 링크된 소스들을 수정하지 않도록 주의 (필요 시 복사본 사용).

## 4. OmG 사용 범위 (Boundary)

### 4.1 상설 가동 (Active Skills)
- `research`: 웹 Grounding 및 최신 API 문서 조사용
- `context-optimize`: Claude 세션 토큰 절감을 위한 컨텍스트 압축용
- `deep-dive`: 특정 모듈 또는 복잡한 버그의 심층 분석용

### 4.2 사용 제한 (Restricted Commands)
- `autopilot`, `ultrawork`, `ralph`: OMC(Claude)의 핵심 플래닝 기능과 충돌 방지를 위해 **상설 OFF**. 반드시 Claude Code를 통해 실행할 것.

### 4.3 기록 규약
- `/omg:*` 명령을 통해 생성된 모든 지식 증류 결과물은 반드시 `.omc/state/gemini_distill.json` 등 파일 경로를 세션 로그에 남겨 Claude가 추후 참조할 수 있게 해야 함.

### 4.4 쓰기 권한 경계 (HARD BOUNDARY)
- **쓰기 허용**: `.omc/state/gemini_distill.json`, `.omc/state/gemini_*.md`, `.omc/state/pending_research.md` (자신이 출처로 표시된 산출물만)
- **쓰기 금지 (Claude 전속)**:
  - `.omc/scripts/**` — 브릿지·검증·오케스트레이션 스크립트
  - `.omc/specs/**` — 사양 문서 (Claude가 명시 요청한 섹션 추가만 허용)
  - `AGENTS.md`, `GEMINI.md`, `CLAUDE.md` 루트 계약 파일
  - `.omc/plans/**`, `.omc/logs/**`
- 위반 시 Claude가 즉시 롤백 + 위반 내역을 `.omc/state/boundary-violations.md`에 append.
- 근거: `.omc/specs/omg-integration-v1.md` §2.2 (State Manager = Claude) — Gemini는 "정보 전처리기"이지 "파이프라인 편집자"가 아님.

### 4.5 의심 시 중단
Gemini가 "수정하면 더 좋아 보이는데?" 라고 판단해도 4.4 금지 경로는 **건드리지 않고 Claude에게 제안만** 하라. (예시 위반: 2026-04-22 omg-bridge.sh v3→v2.1 무단 강등 — v3의 URL 검증 게이트가 삭제되어 환각 방어선이 무너질 뻔함.)

---
**이 문서는 DATAFACTORY 프로젝트에서 Gemini가 정밀한 비전 데이터 처리를 수행하기 위한 길잡이입니다.**
