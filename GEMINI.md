# GEMINI.md — Gemini Project Specifics (DATAFACTORY)

> `datafactory` 프로젝트 전용 Gemini 조작 지침입니다. 글로벌 지침(`~/robot/GEMINI.md`)을 먼저 숙지하십시오.

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

---
**이 문서는 DATAFACTORY 프로젝트에서 Gemini가 정밀한 비전 데이터 처리를 수행하기 위한 길잡이입니다.**
