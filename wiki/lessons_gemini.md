# Lessons Gemini — DATAFACTORY 실전 조작 가이드

> Gemini CLI가 DATAFACTORY 환경에서 Isaac Sim과 ROS2를 직접 조작하며 얻은 특수 교훈.

## 1. 프로젝트 전용 MCP 통신 (Port 8766)

- **연결 확인**: 8766 포트는 `datafactory_isaac_sim` 컨테이너 내의 Isaac Sim MCP 익스텐션이 점유함. 
- **시행착오**: 호스트에서 `uv run isaac_mcp/server.py`를 실행할 때, 컨테이너 부팅 후 약 1~2분이 지나야 `Connected to Isaac at localhost:8766` 메시지를 볼 수 있음. 
- **조작**: `get_scene_info` 호출 시 Isaac Sim이 완전히 `Playing` 상태가 아니더라도 장면의 Hierarchy(World/defaultGroundPlane 등) 정보는 가져올 수 있음.

## 2. ROS2 토픽 조작 실전 (Port 9090)

- **직접 조회**: `docker exec datafactory_ros2 bash -c "source /opt/ros/humble/setup.bash && ros2 topic list"`
- **활성 토픽**: `/client_count`, `/connected_clients` 등이 보인다면 `rosbridge`가 정상적으로 외부 MCP와 통신할 준비가 된 것임.

## 3. 환경 특수성 (RTX 5060)

- **성능**: RTX 5060(Blackwell) 환경에서 컨테이너 기반 Isaac Sim의 초기 부팅 시 익스텐션 로딩(Downloading/Unpacking)에 다소 시간이 걸리나, 일단 로드되면 MCP 응답 속도는 매우 빠름 (밀리초 단위).

---
**Last Updated: 2026-04-21 (Gemini CLI)**
