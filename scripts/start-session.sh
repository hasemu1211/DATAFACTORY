#!/usr/bin/env bash
# DATAFACTORY 세션 시작 헬퍼
# 사용: ./scripts/start-session.sh [--ros2] [--no-wait]
#   --ros2      : rosbridge (ros2) profile도 함께 기동
#   --no-wait   : MCP readiness polling 스킵 (기동만 시작하고 즉시 종료)
# 종료 코드: 0=모두 OK, 1=사전조건 실패, 2=기동 실패, 3=MCP 타임아웃

set -u
cd "$(dirname "$0")/.." || exit 1

WITH_ROS2=0
NO_WAIT=0
for arg in "$@"; do
  case "$arg" in
    --ros2) WITH_ROS2=1 ;;
    --no-wait) NO_WAIT=1 ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "unknown: $arg" >&2; exit 1 ;;
  esac
done

hr() { printf '%0.s─' $(seq 1 60); echo; }
ok() { printf '  \033[32m✔\033[0m %s\n' "$*"; }
fail() { printf '  \033[31m✘\033[0m %s\n' "$*"; }
info() { printf '  \033[36m→\033[0m %s\n' "$*"; }

hr; echo "[1/4] 사전조건"; hr
if ! command -v nvidia-smi >/dev/null; then fail "nvidia-smi 없음"; exit 1; fi
GPU=$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader | head -1)
ok "GPU: $GPU"
if ! docker info >/dev/null 2>&1; then fail "docker 데몬 응답 없음"; exit 1; fi
ok "docker 데몬 OK"

hr; echo "[2/4] 컨테이너 기동"; hr
cd docker || exit 2
if docker compose --profile streaming ps --format '{{.Service}}\t{{.State}}' 2>/dev/null | grep -q "running"; then
  ok "isaac-sim-streaming 이미 running"
else
  info "isaac-sim-streaming 기동 중... (첫 실행 2-4분)"
  docker compose --profile streaming up -d || { fail "streaming 기동 실패"; exit 2; }
  ok "streaming up -d 완료"
fi
if [ $WITH_ROS2 -eq 1 ]; then
  if docker ps --format '{{.Names}}' | grep -q datafactory_ros2; then
    ok "ros2 이미 running"
  else
    info "rosbridge 기동 중..."
    docker compose --profile ros2 up -d ros2 || { fail "ros2 기동 실패"; exit 2; }
    ok "ros2 up -d 완료"
  fi
fi
cd ..

if [ $NO_WAIT -eq 1 ]; then
  hr; ok "--no-wait 지정 — readiness 스킵"; exit 0
fi

hr; echo "[3/4] MCP readiness polling"; hr
info "Isaac Sim MCP :8766 대기 (최대 240s)..."
DEADLINE=$(( $(date +%s) + 240 ))
while :; do
  if (echo > /dev/tcp/127.0.0.1/8766) >/dev/null 2>&1; then
    ok "isaac-sim MCP :8766 TCP 응답"; break
  fi
  if ! docker compose -f docker/docker-compose.yml ps --format '{{.Service}} {{.State}}' 2>/dev/null | grep -q "isaac-sim-streaming running"; then
    fail "isaac-sim-streaming 컨테이너가 running이 아님 (polling 중 종료)"; exit 3
  fi
  [ "$(date +%s)" -ge $DEADLINE ] && { fail "MCP :8766 타임아웃 240s"; exit 3; }
  sleep 3
done
info "MCP extension 로드 로그 확인..."
if docker compose -f docker/docker-compose.yml logs --since 5m isaac-sim-streaming 2>/dev/null | grep -qE "MCP server started|Full Streaming App is loaded"; then
  ok "MCP extension 로드 로그 확인됨"
else
  fail "TCP는 열렸으나 MCP 로드 문자열 미확인 — Isaac Sim 부팅이 더 걸릴 수 있음, 또는 extension 실패"
fi
if [ $WITH_ROS2 -eq 1 ]; then
  info "rosbridge :9090 대기 (최대 60s)..."
  DEADLINE=$(( $(date +%s) + 60 ))
  while :; do
    if (echo > /dev/tcp/127.0.0.1/9090) >/dev/null 2>&1; then
      ok "rosbridge :9090 응답"; break
    fi
    [ "$(date +%s)" -ge $DEADLINE ] && { fail "rosbridge :9090 타임아웃"; exit 3; }
    sleep 2
  done
  if docker exec datafactory_ros2 bash -c 'source /opt/ros/humble/setup.bash && ros2 topic list' >/dev/null 2>&1; then
    ok "ros2 topic list 정상"
  else
    fail "ros2 topic list 실패 (rosbridge 기동 직후 일시적일 수 있음)"
  fi
fi

hr; echo "[4/4] 요약"; hr
ok "세션 시작 준비 완료"
echo
echo "다음 스텝:"
echo "  /start 슬래시 커맨드로 Claude에게 Phase 2 kickoff을 요청하거나,"
echo "  직접 \`/oh-my-claudecode:deep-interview @'V&V 기반 로봇 비전 데이터 파이프라인 구축 기획.md'\` 실행"
