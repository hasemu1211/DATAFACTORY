# QUICKSTART — 컨테이너 실행 가이드

## 사전 조건

- NVIDIA 드라이버 설치 확인: `nvidia-smi`
- NGC 로그인 완료: `docker login nvcr.io`
- X11 소켓 허용: `~/.xprofile`에 등록되어 **로그인 시 자동 실행**됩니다.
  수동으로 즉시 적용하려면:
  ```bash
  xhost +local:docker
  ```

---

## 실행 명령어

모든 명령어는 `docker/` 디렉토리에서 실행합니다.

```bash
cd ~/Desktop/Project/DATAFACTORY/docker
```

---

### 스트리밍 모드 + MCP (Phase 1~3 개발)

Isaac Sim + MCP extension을 띄우고 Claude Code에서 자연어로 제어합니다.

**1단계: 컨테이너 실행**

```bash
docker compose --profile streaming up
```

아래 메시지가 나타나면 준비 완료입니다 (첫 실행 시 2~4분, 이후 20초):

```
Isaac Sim MCP server started on localhost:8766
Isaac Sim Full Streaming App is loaded.
```

**2단계: WebRTC 클라이언트 연결 (시각 확인 필요 시)**

```bash
cd ~/Desktop/Project/DATAFACTORY
./isaacsim-webrtc-streaming-client-1.0.6-linux-x64.AppImage
```

창이 뜨면 서버 주소에 `127.0.0.1` 입력 → **Connect** 클릭

> FUSE 에러 발생 시: `sudo apt-get install -y libfuse2`

**3단계: Claude Code에서 MCP 사용**

Claude Code에서 isaac-sim MCP 도구가 자동으로 활성화됩니다.

```
# 예시: 씬 확인
get_scene_info()

# 예시: 물리 씬 생성
create_physics_scene(objects=[{"type": "Cube", "position": [0,0,50]}])

# 예시: Python 스크립트 실행
execute_script(code="...")
```

---

### ROS2 모드 (rosbridge + ros-mcp)

Claude Code에서 ROS2 토픽/서비스를 자연어로 제어합니다.

**최초 1회: 이미지 빌드**

```bash
docker compose --profile ros2 build ros2
```

**실행**

```bash
docker compose --profile ros2 up -d ros2
```

rosbridge가 포트 9090에서 대기합니다. Claude Code 재시작 후 ros-mcp 도구가 활성화됩니다.

```
# 예시: 로봇 연결
connect_to_robot(ip="127.0.0.1", port=9090)

# 예시: 토픽 목록 확인
get_topics()
```

---

### Phase 4 — Isaac Sim + ROS2 동시 실행 (시공간 동기화 검증)

```bash
docker compose --profile streaming --profile ros2 up
```

Isaac Sim ↔ ROS2 통신은 `network_mode: host` + DDS로 자동 연결됩니다.

---

### Headless 모드 (배치 데이터 생성 — Phase 3)

```bash
docker compose --profile headless up
```

스크립트 경로: `data/scripts/generate.py`

---

## 중지 / 재시작

```bash
# 중지 (컨테이너 유지 — 재시작 빠름)
docker compose stop

# 재시작 (셰이더 캐시 재사용)
docker compose --profile streaming start

# 완전 종료 (컨테이너 삭제)
docker compose down
```

---

## MCP 서버 구성

| MCP | 연결 대상 | 포트 |
|---|---|---|
| `isaac-sim` | Isaac Sim MCP extension | 8766 |
| `ros-mcp` | rosbridge WebSocket | 9090 |

---

## 스토리지 정리 (주기적으로)

```bash
bash ~/Desktop/Project/DATAFACTORY/scripts/clean_storage.sh
```

Isaac Sim 셰이더 캐시(`~/.cache/ov`)와 미사용 Docker 레이어를 삭제합니다.
