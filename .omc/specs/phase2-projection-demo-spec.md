# [DEMO SPEC] Phase 2: 기구학 기반 3D 공간 정밀도 검증 명세서

> **ATTENTION: 이 문서는 에이전트 Gemini가 작성한 데모 명세서(Draft)입니다.**
> OMC(Open Mission Control) 표준 양식을 따르며, 사용자 승인 후 실제 작업에 투입됩니다.

## 1. Metadata
- **Spec ID**: `phase2-projection-demo-20260421`
- **Current Phase**: Phase 2 (Kinematics & Projection V&V)
- **Target Robot**: AgileX LIMO PRO
- **Ambiguity Score**: 0.15 (PASSED)
- **Status**: DRAFT (Review Required)

## 2. Clarity Breakdown (Self-Assessment)

| Dimension | Score | Rationale |
|---|---|---|
| **Goal Clarity** | 0.95 | LIMO PRO의 3D 공간 정밀도(mm) 검증 목표 명확함. |
| **Constraint Clarity** | 0.95 | Isaac Sim 4.5.0 API 및 Brown-Conrady 왜곡 모델 사용 명시됨. |
| **Success Criteria** | 0.90 | 5mm 이내 오차라는 수치적 기준 확정됨. |
| **Context Clarity** | 1.00 | 물류 AMR 직무 역량(3D Vision)과 완벽히 일치함. |

## 3. Goal (목표)
LIMO PRO의 Orbbec DaBai 카메라 모델을 수학적으로 정의하고, 시뮬레이션상의 3D 타겟(AprilTag) 좌표와 카메라 데이터를 통해 추정한 3D 좌표 간의 **유클리드 거리 오차($\text{Error}_{3D}$)**를 mm 단위로 검증한다. 이는 물류 AMR의 정밀 도킹(< 5mm)을 위한 데이터 신뢰성 보증의 핵심 단계이다.

## 4. Constraints (제약 조건)
- **API Compliance**: 반드시 `isaacsim.core.api` 및 `isaacsim.core.utils` (4.5.0 신규 API)를 사용하여 카메라 파라미터를 추출한다.
- **Mathematical Model**: 
    - 카메라 내부 파라미터 $K$ (Intrinsic Matrix)
    - 5계수 Brown-Conrady 왜곡 모델 $D$ (Radial: $k_1, k_2, k_3$, Tangential: $p_1, p_2$)
    - 카메라 외부 파라미터 $[R|t]$ (Extrinsic Matrix: World-to-Camera Transform)
- **Performance**: Orin Nano의 실제 가동 환경을 고려하여 대량의 루프 대신 NumPy 벡터 연산을 활용한다.
- **Environment**: Isaac Sim Headless 모드에서 렌더링된 이미지와 Ground Truth(GT) 데이터를 수집한다.

## 5. Success Criteria (AC - 수용 기준)
- [ ] **AC-1 (수치적 정밀도)**: 최소 10개의 무작위 지점에서 측정된 평균 3D 거리 오차 $\text{Error}_{3D} < 5.0\text{ mm}$ 달성.
- [ ] **AC-2 (왜곡 보정 증명)**: Brown-Conrady 왜곡 보정 전후의 픽셀 투영 오차($\epsilon$)를 비교 분석한 표(Table) 생성.
- [ ] **AC-3 (자동 검증 파이프라인)**: `ProjectionValidator` 클래스를 통해 씬(Scene) 구성 시 자동으로 V&V 리포트를 JSON 형식으로 저장.
- [ ] **AC-4 (수식 문서화)**: Linter 100점 달성을 위해 3D-to-2D 투영 및 Depth 기반 역투영(Back-projection) 수식을 마크다운으로 기술.

## 6. Ontology (핵심 엔티티)

| Entity | Role | Key Attributes |
|---|---|---|
| `ProjectionValidator` | 검증 주체 | `test_cases[]`, `calculate_error()`, `generate_report()` |
| `LimoProCamera` | 카메라 엔티티 | `K`, `D`, `R`, `t`, `resolution(640x480)` |
| `TagTarget` | 검증 대상 | `world_pos`, `local_pos`, `tag_id`, `corner_pixels[]` |
| `ErrorMetric` | 통계 모듈 | `pixel_eps`, `metric_error_mm`, `std_dev` |

## 7. Technical Context (기술적 맥락)
- **MCP Workflow**: `omni-mcp`의 `execute_script`를 사용하여 Isaac Sim 내부 Kit 앱의 `Viewport` 및 `Camera` Prim에서 Raw 데이터를 추출한다.
- **V&V Logic**: 
    1. Isaac Sim이 제공하는 GT 좌표 수집.
    2. 직접 구현한 투영 수식으로 2D 픽셀 좌표 산출.
    3. Stereo Depth 맵에서 해당 픽셀의 깊이값(Z) 추출.
    4. 역투영 수식을 통해 추정 3D 좌표($P_{est}$) 계산.
    5. $\text{Error}_{3D} = \| P_{est} - P_{gt} \|$ 검증.

---
**이 데모 명세서는 Phase 2의 성공적인 수행을 위한 기술적 나침반 역할을 수행합니다.**
