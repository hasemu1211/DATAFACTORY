---
type: lesson
title: Isaac Sim 관련 교훈
date: 2026-04-17
---

# Isaac Sim 4.5.0 관련 교훈

## 컨테이너 = 스트리밍 전용, X11 네이티브 창 불가
- Isaac Sim 4.5.0 Docker 이미지의 모든 실행 스크립트는 스트리밍 모드로 귀결
- `isaac-sim.sh`, `runapp.sh`, `isaac-sim.selector.sh` 모두 마찬가지
- X11 네이티브 창이 필요하면 **호스트 직접 설치** 필요

## WebRTC 스트리밍 포트 구조
- `49100` — WebRTC 시그널링 (WebSocket, HTTP 아님)
- `8211` — 웹 클라이언트 HTML (OmniGibson 전용, 순수 Isaac Sim에는 없음)
- 브라우저로 `http://localhost:49100` 접속 시 HTTP 501 → 정상, WebSocket 프로토콜이기 때문
- 연결하려면 **Isaac Sim WebRTC Streaming Client** standalone AppImage 필요

## WebRTC Streaming Client 사용법 (해결됨)
1. 컨테이너에서 `runheadless.sh` 실행 → 포트 49100으로 스트리밍 대기
2. 호스트에서 AppImage 다운로드 후 `chmod +x *.AppImage`로 권한 부여
3. AppImage 실행 → 서버 `127.0.0.1` 입력 → Connect
4. 다운로드: https://github.com/isaac-sim/IsaacSim-WebRTC-Streaming-Client/releases
5. Ubuntu 22.04+에서 FUSE 2 필요: `sudo apt-get install libfuse2`
- **주의**: `isaac-sim.selector.sh`, `isaac-sim.sh` 등도 스트리밍 모드지만 `runheadless.sh`가 공식 권장

## Omniverse Launcher 2025년 10월부로 Deprecated
- 공식 지원 종료, 설치하지 말 것
- Streaming Client는 별도 standalone 앱으로 받아야 함

## RTX 5060 (sm_120, Blackwell) iray 미지원
- Isaac Sim 4.5.0이 RTX 5060 출시 전 릴리즈 → iray photoreal 미지원 경고
- **프로젝트 영향 없음:** 합성 데이터 생성(SDG)은 Omniverse RTX Renderer 사용
- iray는 선택적 초고화질 오프라인 렌더러, Phase 2~4와 무관

## ROS2 Bridge 실패 해결 — 내장 라이브러리 활성화
- Isaac Sim 내부에 ROS2 Humble 라이브러리 내장
- docker-compose.yml에 환경변수 추가로 해결:
```yaml
- RMW_IMPLEMENTATION=rmw_fastrtps_cpp
- LD_LIBRARY_PATH=/isaac-sim/exts/isaacsim.ros2.bridge/humble/lib
```

## 실행 스크립트 역할 정리
| 스크립트 | 역할 |
|---------|------|
| `isaac-sim.sh` | 스트리밍 앱 (기본) |
| `runapp.sh` | `isaac-sim.sh` 래퍼 |
| `isaac-sim.docker.gui.sh` | 호스트에서 docker run 하는 스크립트 (컨테이너 안에서 실행하면 안 됨) |
| `runheadless.sh` | 헤드리스 스트리밍 |
| `python.sh` | Python 스크립트 실행용 |
| `isaac-sim.selector.sh` | Selector UI (역시 스트리밍) |

## Phase별 GUI 필요 여부
- Phase 2 (K행렬), Phase 3 (Replicator), Phase 4 (ROS2): Python API로 가능
- 시각 확인: 생성된 이미지 파일을 호스트에서 열어서 확인 가능
