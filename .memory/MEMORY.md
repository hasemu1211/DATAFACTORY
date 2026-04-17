# DATAFACTORY 프로젝트 메모리 인덱스

> 세션 간 교훈과 결정사항을 누적 기록합니다.
> 새 세션 시작 시 이 파일을 먼저 읽어 컨텍스트를 복원합니다.

## 교훈 (Lessons Learned)

- [환경 세팅 교훈](lessons_environment.md) — jq, 한국어 입력, xhost, Nerd Font, IBus autostart
- [Isaac Sim 교훈](lessons_isaac_sim.md) — 컨테이너 한계, WebRTC 구조, RTX 5060, ROS2 Bridge
- [Docker/Compose 교훈](lessons_docker.md) — profiles, 이름 충돌, 통신 구조
- [MCP 연동 교훈](lessons_mcp.md) — --exec Python API 활성화, 4.5.0 API 패치, mcp 1.27.0 호환

## 현재 프로젝트 상태 (2026-04-17)

### Phase 1 완료
- Ubuntu, Docker, NVIDIA Container Toolkit, Isaac Sim 4.5.0
- docker-compose.yml: streaming/headless/ros2 profile 분리
- ROS_DISTRO=humble 환경변수 추가
- GitHub 레포 init, .gitignore 구성
- 개발환경: WezTerm (use_ime=true), 한국어(IBus autostart), statusline(jq), Nerd Font
- Isaac Sim 시각 확인: WebRTC Streaming Client AppImage (127.0.0.1:49100)
- ENVIRONMENT_SETUP.md / QUICKSTART.md: 전체 환경 구축 절차 문서화
- **isaac-sim MCP 연동 완료**: Claude Code → Isaac Sim 씬 제어 검증
  - extension 로딩: `--exec enable_mcp.py` + `set_extension_enabled()` 방식
  - server.py 패치: mcp 1.27.0 호환 (FastMCP description 제거, 리턴 타입 수정)
  - 검증: `create_physics_scene`, `execute_script` 정상 동작 확인
- **ros-mcp 연동 완료**: Claude Code → rosbridge(9090) → ROS2 컨테이너
  - Dockerfile.ros2로 rosbridge 이미지 빌드
  - ros-mcp 프로젝트 MCP 등록 완료
  - 검증: `connect_to_robot`, `get_topics` 정상 동작 확인

### 다음 작업
- **Phase 2**: Isaac Sim Python API로 카메라 K행렬 추출 스크립트 작성
- **Phase 3**: Omniverse Replicator 도메인 무작위화 스크립트
- **Phase 4**: ROS2 시공간 동기화 검증

## MCP 구성 (프로젝트 레벨, .mcp.json)
- `isaac-sim`: uv run isaac_mcp/server.py → Isaac Sim 포트 8766
- `ros-mcp`: uvx ros-mcp → rosbridge 포트 9090

## 하드웨어 스펙
- GPU: RTX 5060 (8GB VRAM, CUDA sm_120, Blackwell)
- 스토리지 여유: ~80GB
- RAM: 16GB
- CPU: i5-14400F (10코어 20스레드)
