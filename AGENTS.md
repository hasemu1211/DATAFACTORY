# DATAFACTORY — Project Instructions

> 새 세션 에이전트가 가장 먼저 읽어야 할 파일입니다.
> 상세 내용은 `ENVIRONMENT_SETUP.md`, `QUICKSTART.md`, `.memory/` 참조.

---

## 프로젝트 개요

**V&V 기반 로봇 비전 합성 데이터 파이프라인 검증**
- 목표: Isaac Sim 4.5.0 + Claude Code MCP로 합성 데이터 생성 파이프라인 구축
- 핵심: 시각적 화려함보다 수학적·통계적 무결성 (Δt, K, R|t, ε, U(a,b))

## 하드웨어

- GPU: RTX 5060 (8GB VRAM, CUDA sm_120, Blackwell) — iray 미지원 경고 무시
- RAM: 16GB / CPU: i5-14400F (10코어)
- Storage: 여유 ~80GB (데이터 500장 미만, 캐시 주기적 정리)

---

## Phase 현황

| Phase | 내용 | 상태 |
|---|---|---|
| 1 | Docker + Isaac Sim + MCP + ROS2 환경 구축 | **완료** |
| 2 | 카메라 K행렬, 3D→2D 투영 오차 검증 (30점) | 미시작 |
| 3 | Omniverse Replicator 통계적 도메인 무작위화 (40점) | 미시작 |
| 4 | ROS2 시공간 동기화 Δt 측정 (30점) | 미시작 |
| 5 | 문서화 및 README 완성 | 미시작 |

---

## 환경 시작 방법

```bash
cd ~/Desktop/Project/DATAFACTORY/docker

# Isaac Sim + MCP (항상 필요)
docker compose --profile streaming up

# ROS2 + rosbridge (ros-mcp 사용 시 추가)
docker compose --profile ros2 up -d ros2
```

**준비 완료 확인:**
- Isaac Sim: `Isaac Sim MCP server started on localhost:8766` 로그 확인
- ROS2: `docker exec datafactory_ros2 bash -c "source /opt/ros/humble/setup.bash && ros2 topic list"`

---

## MCP 도구 (Claude Code 자동 활성화)

### isaac-sim MCP (포트 8766)
| 도구 | 용도 |
|---|---|
| `get_scene_info()` | 연결 확인 — **항상 먼저 호출** |
| `create_physics_scene(objects, floor, gravity)` | 물리 씬 + 오브젝트 생성 |
| `execute_script(code)` | Isaac Sim 내부 Python 실행 |
| `create_robot(robot_type, position)` | 로봇 스폰 |
| `transform(path, position, rotation)` | prim 위치/회전 변경 |

### ros-mcp (포트 9090, rosbridge)
| 도구 | 용도 |
|---|---|
| `connect_to_robot(ip="127.0.0.1", port=9090)` | rosbridge 연결 — **항상 먼저 호출** |
| `get_topics()` | ROS2 토픽 목록 |
| `subscribe_once(topic, msg_type)` | 토픽 1회 구독 |
| `publish_once(topic, msg_type, msg)` | 토픽 발행 |
| `call_service(service, type, args)` | 서비스 호출 |

---

## Isaac Sim 4.5.0 API (execute_script 작성 시 필수)

```python
# 구 API (사용 금지 — 4.2.0 기준)
from omni.isaac.core import World
from omni.isaac.core.prims import XFormPrim
from omni.isaac.nucleus import get_assets_root_path

# 신 API (4.5.0 — 반드시 사용)
from isaacsim.core.api import World
from isaacsim.core.prims import XFormPrim
from isaacsim.core.utils.nucleus import get_assets_root_path
from isaacsim.core.utils.prims import create_prim
from isaacsim.core.utils.stage import add_reference_to_stage
```

---

## 코딩 원칙

- 결과는 반드시 수식으로 표현 (Δt, K, R|t, ε, U(a,b))
- 정성적 표현("좋습니다") 사용 금지
- Isaac Sim Headless 해상도 640×480 우선
- 스토리지 절약 최우선

## 도구

- `context7`: Isaac Sim / ROS2 / NumPy API 문서
- `superpowers`: TDD, 디버깅, 코드 리뷰 워크플로우

---

## 핵심 파일 위치

```
DATAFACTORY/
├── docker/
│   ├── docker-compose.yml         # 전체 서비스 정의
│   ├── Dockerfile.ros2            # rosbridge 포함 ROS2 이미지
│   ├── entrypoint-mcp.sh          # Isaac Sim 커스텀 엔트리포인트
│   ├── enable_mcp.py              # MCP extension 활성화 스크립트
│   └── isaacsim.streaming.mcp.kit # 커스텀 Kit 앱 파일
├── ENVIRONMENT_SETUP.md           # 전체 환경 구축 절차
├── QUICKSTART.md                  # 실행 명령어 가이드
├── .mcp.json                      # MCP 서버 등록 (프로젝트 레벨)
└── .memory/                       # 세션 간 교훈 (lessons_*.md)

~/Desktop/Project/isaac-sim-mcp/   # MCP extension 소스 (별도 레포)
```

---

## 메모리 위치

`.memory/MEMORY.md` — 세션 시작 시 자동 로드됨
