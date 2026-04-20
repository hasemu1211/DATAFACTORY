# DATAFACTORY 개발환경 구축 가이드

> Isaac Sim 4.5.0 + ROS2 Humble + Claude Code MCP 통합 환경
> RTX 5060 (CUDA sm_120, Blackwell) / Ubuntu 22.04 / Docker 기반

---

## Prerequisites 체크리스트

이 중 빠지면 무음 실패가 빈번합니다:

- [ ] **NVIDIA 드라이버** (≥ 470 권장): `nvidia-smi`로 확인
- [ ] **Docker Engine** + **NVIDIA Container Toolkit** (1단계 참조)
- [ ] **NGC 로그인**: `docker login nvcr.io` (Isaac Sim 이미지 pull 권한)
- [ ] **jq** (≥ 1.6): Claude Code statusline + SessionStart 훅 JSON 처리
- [ ] **xclip + xsel**: wezterm/tmux X11 클립보드 연동. 미설치 시 복사 무음 실패
- [ ] **libfuse2**: AppImage 실행 필수 (Ubuntu 22.04+는 별도 설치 필요)
- [ ] **tmux 3.2+**: `tmux -V`로 확인. 3.0 미만은 일부 바인딩 문법 차이
- [ ] **IBus autostart**: `~/.xprofile`에 IBus 환경변수 + `xhost +local:docker`
- [ ] **WezTerm `use_ime=true`**: 한국어 입력. `~/.config/wezterm/wezterm.lua`
- [ ] **Node.js 20+, Claude Code CLI, OMC 플러그인**: `/plugin install oh-my-claudecode`

한 줄 설치 (Ubuntu 22.04):
```bash
sudo apt-get install -y jq xclip xsel libfuse2 tmux
```

---

## 아키텍처 개요

```
호스트 (Ubuntu 22.04)
├── NVIDIA 드라이버 + NVIDIA Container Toolkit
├── Docker Engine (overlay2)
├── Claude Code + isaac-sim MCP 서버 (stdio, uv run)
└── WebRTC Streaming Client (AppImage)

컨테이너
├── datafactory_isaac_sim   # Isaac Sim 4.5.0
│   ├── streaming 프로파일: Kit 직접 실행 + WebRTC + MCP extension
│   └── headless  프로파일: python.sh + 배치 생성
└── datafactory_ros2        # ROS2 Humble (Phase 4 전용)
    └── ros2 프로파일: 시공간 동기화 검증용
```

**핵심 원칙:**
- 호스트에 CUDA Toolkit 직접 설치 금지 — 컨테이너로 격리
- `network_mode: host` + `ipc: host` → ROS2 DDS 자동 발견, 복사 오버헤드 제거
- 셰이더 캐시 Docker Volume으로 유지 → 재시작 시 빠름

---

## 1단계: 호스트 환경 구성

### Docker 설치

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER   # 재로그인 후 적용
```

### NVIDIA Container Toolkit 설치

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Docker 로그 용량 제한 (`/etc/docker/daemon.json`)

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" },
  "storage-driver": "overlay2"
}
```

```bash
sudo systemctl daemon-reload && sudo systemctl restart docker
```

### 개발 도구

```bash
sudo apt-get install -y jq          # Claude Code statusline 파싱 필수
sudo apt-get install -y libfuse2    # AppImage 실행 필수
```

### X11 자동화 (`~/.xprofile` — 로그인 시 자동 실행)

```bash
# 한국어 입력 (IBus)
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

# Isaac Sim 컨테이너 X11 소켓 허용
xhost +local:docker &>/dev/null
```

> `.bashrc`에 넣으면 WezTerm 등 빠른 앱이 먼저 뜰 때 적용 안 됨 → `.xprofile` 필수
> WezTerm 한국어 입력: `~/.config/wezterm/wezterm.lua`에 `config.use_ime = true` 필수

### NGC 로그인 (Isaac Sim 이미지 pull 권한)

```bash
docker login nvcr.io
# Username: $oauthtoken
# Password: NGC API KEY
```

---

## 2단계: Isaac Sim MCP 연동 환경 구성

### 레포 클론

```bash
cd ~/Desktop/Project
git clone https://github.com/omni-mcp/isaac-sim-mcp
```

> 심링크는 컨테이너 entrypoint에서 생성하므로 호스트에서 별도 생성 불필요

### Isaac Sim 4.5.0 API 패치

`isaac-sim-mcp`는 Isaac Sim 4.2.0 기준. 4.5.0에서는 아래 import 경로 변경 필요.

`isaac.sim.mcp_extension/isaac_sim_mcp_extension/extension.py` 상단:

```python
# 변경 전 (4.2.0)
from omni.isaac.nucleus import get_assets_root_path
from omni.isaac.core.prims import XFormPrim
from omni.isaac.core import World

# 변경 후 (4.5.0)
from isaacsim.core.utils.nucleus import get_assets_root_path
from isaacsim.core.prims import XFormPrim        # ← core.prims (api.prims 아님)
from isaacsim.core.api import World
```

`extension.py` 내부 함수(`create_robot` 등)에도 lazy import 존재:

```python
# 변경 전
from omni.isaac.core.utils.prims import create_prim
from omni.isaac.core.utils.stage import add_reference_to_stage, is_stage_loading
from omni.isaac.nucleus import get_assets_root_path

# 변경 후
from isaacsim.core.utils.prims import create_prim
from isaacsim.core.utils.stage import add_reference_to_stage, is_stage_loading
from isaacsim.core.utils.nucleus import get_assets_root_path
```

`isaac.sim.mcp_extension/config/extension.toml`:

```toml
[dependencies]
"isaacsim.core.api" = {}
"isaacsim.core.utils" = {}
"omni.kit.uiapp" = {}
```

### MCP 서버 의존성 설치 (호스트)

```bash
cd ~/Desktop/Project/isaac-sim-mcp
uv venv
uv pip install "mcp[cli]"
```

### Claude Code MCP 등록

```bash
claude mcp add isaac-sim -- uv --directory ~/Desktop/Project/isaac-sim-mcp run isaac_mcp/server.py
```

### mcp 1.27.0 호환성 패치 (중요)

`isaac-sim-mcp` 업스트림은 `mcp<1.0` 기준으로 작성됨. 설치된 `mcp>=1.27.0`에서는 `FastMCP` 생성자 시그니처와 도구 리턴 타입이 변경됨 → 패치 없이 서버 실행 시 `TypeError`.

**`isaac_mcp/server.py` 수정 필요:**

```python
# 변경 전 (mcp < 1.0 / FastMCP 레거시)
mcp = FastMCP(
    name="isaac-sim",
    description="Isaac Sim MCP server",  # 1.27에서 제거됨
)

# 변경 후 (mcp >= 1.27)
mcp = FastMCP(name="isaac-sim")  # description 인수 삭제
```

도구 함수 리턴 타입도 `dict` → `list[TextContent]`로 변환 필요 (FastMCP 내부에서 자동 wrapping 되던 동작이 변경).

```python
# 변경 전
return {"status": "ok", "payload": data}

# 변경 후
from mcp.types import TextContent
return [TextContent(type="text", text=json.dumps({"status": "ok", "payload": data}))]
```

> 이 패치는 업스트림 PR 대기 중. 업그레이드 후 `isaac_mcp/server.py` 재확인 필요.

---

## 3단계: Docker Compose 아키텍처

### 커스텀 Kit 앱 파일 (`docker/isaacsim.streaming.mcp.kit`)

Isaac Sim 기본 streaming 앱을 래핑. extension 활성화는 `--exec` Python 스크립트로 처리.

```toml
[package]
title = "Isaac Sim Streaming + MCP"
description = "isaacsim.exp.full.streaming with local MCP extension"
version = "1.0.0"

[dependencies]
"isaacsim.exp.full.streaming" = {}
```

### MCP Extension 활성화 스크립트 (`docker/enable_mcp.py`)

Kit의 `[dependencies]` / `[settings.app.exts.enabled]` 는 모두 registry 조회를 함.
로컬 전용 extension은 앱 초기화 후 Python API로 직접 활성화해야 함.

```python
import carb
import omni.kit.app

manager = omni.kit.app.get_app().get_extension_manager()
if not manager.is_extension_enabled("isaac_sim_mcp_extension"):
    manager.set_extension_enabled("isaac_sim_mcp_extension", True)
    carb.log_info("[MCP] isaac_sim_mcp_extension enabled via startup script")
else:
    carb.log_info("[MCP] isaac_sim_mcp_extension already enabled")
```

### 커스텀 엔트리포인트 (`docker/entrypoint-mcp.sh`)

Isaac Sim 이미지 ENTRYPOINT가 `runheadless.sh`로 고정 → `entrypoint:` 오버라이드 필수.
컨테이너 내부에서 직접 심링크 생성 (호스트 심링크 bind mount 의존 X).

```bash
#!/bin/sh
# 컨테이너 내부에서 직접 심링크 생성 (호스트 심링크 의존 X)
ln -sfn /opt/isaac-sim-mcp/isaac.sim.mcp_extension /isaac-sim/exts/isaac_sim_mcp_extension

/isaac-sim/license.sh && /isaac-sim/privacy.sh && \
exec /isaac-sim/kit/kit \
  /opt/kit/isaacsim.streaming.mcp.kit \
  --ext-folder /isaac-sim/exts \
  --ext-folder /isaac-sim/apps \
  --exec /opt/kit/enable_mcp.py \
  --merge-config="/isaac-sim/config/open_endpoint.toml" \
  --/persistent/isaac/asset_root/default="$OMNI_SERVER" \
  --allow-root \
  --no-window
```

> `/isaac-sim/exts/`는 Kit 기본 스캔 폴더. 여기에 심링크를 두면 registry 조회 없이 발견됨.

### docker-compose.yml 전체 구조

```yaml
services:
  ros2:
    image: ros:humble
    container_name: datafactory_ros2
    profiles: ["ros2"]                  # Phase 4 전까지 불필요
    network_mode: host
    ipc: host
    environment:
      - ROS_DOMAIN_ID=0
    volumes:
      - ../data:/data
      - ./ros2_ws:/ros2_ws
    command: ["/bin/bash"]

  isaac-sim-streaming:
    image: nvcr.io/nvidia/isaac-sim:4.5.0
    container_name: datafactory_isaac_sim
    profiles: ["streaming"]
    runtime: nvidia
    network_mode: host
    ipc: host
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,graphics,utility
      - ACCEPT_EULA=Y
      - ROS_DISTRO=humble
      - RMW_IMPLEMENTATION=rmw_fastrtps_cpp
      - LD_LIBRARY_PATH=/isaac-sim/exts/isaacsim.ros2.bridge/humble/lib
    volumes:
      - ../data:/data
      - ../config:/config
      - isaac_cache:/root/.cache/ov
      - ../../isaac-sim-mcp:/opt/isaac-sim-mcp:ro
      - ./isaacsim.streaming.mcp.kit:/opt/kit/isaacsim.streaming.mcp.kit:ro
      - ./entrypoint-mcp.sh:/entrypoint-mcp.sh:ro
      - ./enable_mcp.py:/opt/kit/enable_mcp.py:ro
    entrypoint: ["/bin/sh", "/entrypoint-mcp.sh"]
    command: []

  isaac-sim-headless:
    image: nvcr.io/nvidia/isaac-sim:4.5.0
    container_name: datafactory_isaac_sim
    profiles: ["headless"]
    runtime: nvidia
    network_mode: host
    ipc: host
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,graphics,utility
      - ACCEPT_EULA=Y
      - RMW_IMPLEMENTATION=rmw_fastrtps_cpp
      - LD_LIBRARY_PATH=/isaac-sim/exts/isaacsim.ros2.bridge/humble/lib
    volumes:
      - ../data:/data
      - ../config:/config
      - isaac_cache:/root/.cache/ov
    command: ["/isaac-sim/python.sh", "/data/scripts/generate.py"]

volumes:
  isaac_cache:
    driver: local
```

---

## 4단계: WebRTC Streaming Client

Isaac Sim 컨테이너는 네이티브 X11 창을 지원하지 않음. WebRTC 스트리밍 방식으로만 GUI 접근 가능.

```bash
# 다운로드: https://github.com/isaac-sim/IsaacSim-WebRTC-Streaming-Client/releases
# 프로젝트 루트에 AppImage 배치 후:
chmod +x isaacsim-webrtc-streaming-client-*.AppImage
./isaacsim-webrtc-streaming-client-*.AppImage
# → 서버: 127.0.0.1 → Connect
```

**포트 구조:**
- `49100` — WebRTC 시그널링 (WebSocket, HTTP 아님 → 브라우저 직접 접속 불가)
- `8766` — MCP extension TCP 소켓 (Isaac Sim ↔ MCP 서버)

---

## 주요 교훈 및 트러블슈팅

### Isaac Sim 4.5.0 API 변경

| 구 API (4.2.0) | 신 API (4.5.0) |
|---|---|
| `omni.isaac.core` | `isaacsim.core.api` |
| `omni.isaac.core.prims` | `isaacsim.core.prims` |
| `omni.isaac.nucleus` | `isaacsim.core.utils.nucleus` |
| `omni.isaac.core.utils.*` | `isaacsim.core.utils.*` |

> `isaacsim.core.api.prims`는 존재하지 않음 — `isaacsim.core.prims`가 올바른 경로

### Kit Extension 로딩 방식 비교

| 방법 | 결과 | 원인 |
|---|---|---|
| `--enable <name>` | 실패 (exit 55) | registry 조회 후 없으면 앱 종료 |
| `[dependencies]`에 직접 선언 | 실패 (exit 55) | 동일하게 registry 조회 |
| `[settings.exts."name"].enabled = true` | 실패 (silent) | extension 자체 설정 네임스페이스, 활성화 명령 아님 |
| `[settings.app.exts.enabled."++".0]` | 실패 (silent) | registry 조회 발생 |
| `--exec enable_mcp.py` + `manager.set_extension_enabled()` | **성공** | registry 우회, Python API 직접 호출 |

### Extension 발견 방법

Kit은 `--ext-folder` 경로의 하위 디렉토리를 스캔하여 `config/extension.toml`을 찾음.
- `/isaac-sim/exts/`는 Kit 기본 스캔 폴더
- 컨테이너 entrypoint에서 `ln -sfn`으로 심링크 생성 → bind mount 심링크 의존성 제거
- 폴더명 = extension.toml `name` 필드 일치 필수 (`isaac.sim.mcp_extension` → `isaac_sim_mcp_extension`)

### 컨테이너 재시작 빠르게 하기

```bash
# 캐시 보존하며 재시작 (권장)
docker compose --profile streaming stop
docker compose --profile streaming up

# 완전 초기화 (캐시 삭제 — 첫 실행처럼 오래 걸림)
docker compose --profile streaming down -v
```

### ROS2 Bridge 내장 라이브러리 활성화

```yaml
environment:
  - RMW_IMPLEMENTATION=rmw_fastrtps_cpp
  - LD_LIBRARY_PATH=/isaac-sim/exts/isaacsim.ros2.bridge/humble/lib
```

### RTX 5060 (CUDA sm_120, Blackwell) 호환성

- **iray photoreal 렌더러:** 미지원 (경고 출력되나 무시 가능)
- **Omniverse RTX Renderer (합성 데이터 생성용):** 정상 동작

### 무시 가능한 경고/에러

| 메시지 | 원인 | 영향 |
|---|---|---|
| `omni.anim.navigation.recast` interface v2.3 vs v3.2 | Isaac Sim 내부 버전 불일치 | 없음 (navigation 미사용) |
| `OmniHub is inaccessible` | NVIDIA 클라우드 미연결 | 없음 (로컬 사용) |
| `IOMMU is enabled` | 커널 설정 | 없음 |
| `ROS_DISTRO not found` | ROS2 미소싱 | Phase 4 전까지 무관 |
| `iray photoreal` GPU 미지원 | RTX 5060 출시 전 릴리즈 | 없음 |

---

## 스토리지 관리

| 이미지 | 용량 | 비고 |
|---|---|---|
| `nvcr.io/nvidia/isaac-sim:4.5.0` | 15GB | 필수 |
| `ros:humble` | 756MB | Phase 4 필수 |

```bash
# 셰이더 캐시 + 미사용 Docker 레이어 삭제
bash ~/Desktop/Project/DATAFACTORY/scripts/clean_storage.sh
```
