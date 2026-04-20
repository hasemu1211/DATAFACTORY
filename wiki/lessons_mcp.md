---
name: Isaac Sim MCP 연동 교훈
description: isaac-sim-mcp를 Isaac Sim 4.5.0 Docker 환경에 연동할 때 겪은 실패와 해결책
type: project
---

# Isaac Sim MCP 연동 교훈

## Extension 로딩: 모든 kit 파일 방법은 registry 조회함

| 방법 | 결과 |
|---|---|
| `--enable <name>` | 실패 (exit 55) — registry 조회 |
| `[dependencies] "name" = {}` | 실패 (exit 55) — registry 조회 |
| `[settings.exts."name"].enabled = true` | 실패 (silent) — extension 자체 설정 네임스페이스, 활성화 명령 아님 |
| `[settings.app.exts.enabled."++".0]` | 실패 (silent) — registry 조회 발생 |
| `--exec enable_mcp.py` + `manager.set_extension_enabled()` | **성공** — registry 완전 우회 |

**Why:** Kit의 dependency/enabled 시스템은 항상 registry를 거침. 로컬 전용 extension은 앱 초기화 후 Python API로만 안전하게 활성화 가능.

**How to apply:** `--exec <script.py>` + `omni.kit.app.get_app().get_extension_manager().set_extension_enabled()` 조합 사용.

---

## Extension 발견: /isaac-sim/exts/ 심링크

**Why:** Kit이 ext-folder 스캔 시 호스트 bind mount의 심링크를 따라가지 않을 수 있음. 컨테이너 내부에서 직접 생성하는 것이 확실함.

```bash
# entrypoint-mcp.sh에서 컨테이너 내부 심링크 생성
ln -sfn /opt/isaac-sim-mcp/isaac.sim.mcp_extension /isaac-sim/exts/isaac_sim_mcp_extension
```

`/isaac-sim/exts/`는 Kit 기본 스캔 폴더라 `--ext-folder` 추가 불필요.

**How to apply:** 로컬 extension은 entrypoint에서 `/isaac-sim/exts/`에 심링크 생성.

---

## Isaac Sim 4.5.0 API 경로 (확정)

```python
# 4.2.0 → 4.5.0
from omni.isaac.nucleus import ...           → from isaacsim.core.utils.nucleus import ...
from omni.isaac.core.prims import XFormPrim  → from isaacsim.core.prims import XFormPrim
from omni.isaac.core import World            → from isaacsim.core.api import World
from omni.isaac.core.utils.prims import ...  → from isaacsim.core.utils.prims import ...
from omni.isaac.core.utils.stage import ...  → from isaacsim.core.utils.stage import ...
```

**주의:** `isaacsim.core.api.prims`는 존재하지 않음 — `isaacsim.core.prims`가 올바름.

---

## Isaac Sim Docker ENTRYPOINT 오버라이드 필수

ENTRYPOINT가 `runheadless.sh`로 고정 → `entrypoint:` 오버라이드 + `license.sh`, `privacy.sh` 수동 호출.

```yaml
entrypoint: ["/bin/sh", "/entrypoint-mcp.sh"]
command: []
```

---

## 첫 실행 시 ext cache 재다운로드 (느림)

커스텀 kit 파일은 새 app context 생성 → 첫 실행 약 90~250초. 이후 정상 (~20초).

---

## 현재 MCP 연동 상태 (2026-04-17 완료)

- **Extension 로딩:** 성공 — `Isaac Sim MCP server started on localhost:8766` 확인
- **미해결:** `extension.py` 내부 함수(`create_robot`)의 lazy import 일부 미패치
  - `from omni.isaac.core.utils.prims import create_prim` → 수정 필요
  - `from omni.isaac.core.utils.stage import ...` → 수정 필요
  - 서버 시작에는 영향 없음, `create_robot` 호출 시 런타임 에러 발생
