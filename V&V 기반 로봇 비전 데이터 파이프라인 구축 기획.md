# V&V 기반 LIMO PRO 물류 AMR 정밀 진입 비전 데이터 파이프라인 구축 기획 (Final Enriched)

본 기획안은 AgileX LIMO PRO 로봇의 **"물류 선반 하단 정밀 진입 및 도킹"** 성능을 보장하기 위한 수학적·통계적 V&V(Verification & Validation) 파이프라인 구축을 목표로 합니다. Orin Nano의 에지 컴퓨팅 자원과 Orbbec DaBai의 뎁스 데이터를 활용하여, 시뮬레이션 데이터의 물리적 타당성을 정량적으로 증명하고 Sim-to-Real 간극을 최소화합니다.

### 프로젝트 개요
*   **대상 기체**: AgileX LIMO PRO (NVIDIA Orin Nano, Orbbec DaBai Stereo Depth Camera)
*   **핵심 목표**: 3D 공간 정밀 도킹 오차 수치화 및 실시간 임베디드 추론 환경의 지연 최적화 검증
*   **핵심 지표**: 
    *   $\text{Error}_{3D}$ (3D 유클리드 거리 오차 < 5mm)
    *   $\Delta t$ (Inference + ROS 2 Latency < 15ms — **Rationale**: 1.0m/s 이동 시 15ms 지연은 15mm 오차 유발)
    *   $\text{Fidelity}_{SNR}$ (저조도 및 바닥 반사 환경의 센서 노이즈 강건성 지표)
*   **제약 조건**: RTX 3050/5060, 124GB 스토리지, Isaac Sim 4.5.0 Headless

---

### Phase 1: LIMO PRO 디지털 트윈 및 Isaac ROS 기반 인프라 구성 (Day 1 - Day 10)
*   **디지털 트윈 구축**: LIMO PRO의 4가지 주행 모드(Ackermann, Mecanum 등)와 Orbbec DaBai 카메라 스펙(FoV 67.9°)을 Isaac Sim에 정밀 구현합니다.
*   **Isaac ROS 환경 설정**: Orin Nano 환경을 고려하여 NVIDIA Isaac ROS(NITROS) 및 Zero-copy 전송 기반의 미들웨어 아키텍처를 구성합니다.
*   **데이터 거버넌스**: 124GB 제약 극복을 위한 캐시 자동 정리 스크립트(`clean_storage.sh`)를 가동합니다.

### Phase 2: Pillar A - 기구학 기반 3D 투영 및 왜곡 보정 검증 (Day 11 - Day 20)
*   **3D 공간 정밀도($\text{Error}_{3D}$) 검증**: RGB 투영($K, R|t$)과 Stereo Depth를 결합하여, AprilTag 타겟의 시뮬레이션 GT와 로봇 추정치 간의 mm 단위 유클리드 거리를 산출합니다.
*   **Brown-Conrady 왜곡 모델링**: 소형 로봇 광각 렌즈의 특성을 반영하여, 왜곡 보정(Undistortion)이 도킹 정밀도에 미치는 수치적 영향을 분석합니다.
*   **직무 역량**: 3D 좌표계 변환 및 투영 기하학(Projection Geometry)의 수학적 구현 역량 증명.

### Phase 3: Pillar B - 도메인 무작위화 및 에지 추론 최적화 검증 (Day 21 - Day 30)
*   **통계적 강건성(Robustness) 확보**: 창고 바닥 반사 및 저조도 환경을 PDF(확률 밀도 함수)로 모델링하고, 센서 노이즈가 주입된 500장의 고밀도 데이터를 생성합니다.
*   **TensorRT 추론 정량화**: Orin Nano의 GPU 자원을 활용하기 위해 인식 모델을 TensorRT(FP16)로 최적화하고, 지연 시간 단축 효과를 검증합니다.
*   **직무 역량**: Sim-to-Real gap 통제 및 에지 디바이스 환경의 딥러닝 최적화 역량 증명.

### Phase 4: Pillar C - 시공간 동기화($\Delta t$) 및 동적 오차 분석 (Day 31 - Day 40)
*   **실시간 동기화 검증**: `ApproximateTimeSynchronizer`와 `NITROS`를 활용하여, 로봇 이동 중 센서 데이터와 TF(Transform) 간의 동기화 지연을 측정합니다.
*   **동적 오차($\text{Error}_{dynamic}$) 정량화**: 로봇 주행 속도와 전송 지연($\Delta t$)의 상관관계를 분석하여, 15ms 지연이 유발하는 15mm 오차를 도킹 성공률 관점에서 평가합니다.
*   **직무 역량**: ROS 2 미들웨어의 실시간성 확보 및 이동 로봇의 시공간적 데이터 무결성 제어 역량 증명.

### Phase 5: V&V 기술 리포트 및 직무 최적화 포트폴리오 (Day 41 - Day 50)
*   **현업 지향형 README**: "왜 이 지표가 중요한가"에 대한 공학적 근거(Rationale)를 중심으로, 수학적 증명 과정과 통계 자료를 정제합니다.
*   **Linter 100점 달성**: 물류 로봇 R&D 직군에서 요구하는 기술적 깊이와 체계성을 갖춘 최종 V&V 리포트를 완성합니다.

---
**이 기획안은 LIMO PRO 플랫폼과 NVIDIA 기술 스택을 활용하여, 물류 로봇의 현장 투입 전 필수적인 '신뢰성 검증' 과정을 완벽히 구현하는 데이터 엔지니어링 프로젝트입니다.**
