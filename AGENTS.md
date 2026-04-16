# DATAFACTORY — Project Instructions

## 프로젝트 개요
**V&V 기반 로봇 비전 합성 데이터 파이프라인 검증**
- 목표: 50일 내 Linter 평가 기준 100점 달성
- 핵심: 시각적 화려함보다 수학적·통계적 무결성

## 환경
- OS: Ubuntu 22.04
- GPU: NVIDIA RTX 3050 (VRAM 제한)
- Storage: 124GB (엄격한 관리 필요)
- 컨테이너: Docker + NVIDIA Container Toolkit

## 단계별 목표
- **Phase 1** (Day 1-10): Docker + Isaac Sim Headless 환경 구성
- **Phase 2** (Day 11-20): 카메라 K 행렬, 3D→2D 투영 오차 검증 (30점)
- **Phase 3** (Day 21-30): Omniverse Replicator 통계적 도메인 무작위화 (40점)
- **Phase 4** (Day 31-40): ROS 2 시공간 동기화 및 Δt 측정 (30점)
- **Phase 5** (Day 41-50): 문서화 및 README 완성

## 코딩 원칙
- 결과는 반드시 수식(Δt, K, R|t, ε, U(a,b))으로 표현
- 정성적 표현("좋습니다") 사용 금지
- 스토리지 절약 최우선 (데이터 500장 미만, 캐시 주기적 정리)
- Isaac Sim은 반드시 Headless 모드 (해상도 640×480)

## 도구
- context7: Isaac Sim / ROS 2 / NumPy API 문서
- NotebookLM: 논문·문서 참조 (`python3 -m notebooklm ask "질문"`)
  - 활성 노트북: Isaac Sim and Robotics Simulation DATAFACTORY
- superpowers: TDD, 디버깅, 코드 리뷰 워크플로우

## 메모리
- 위치: `/home/codelab/Desktop/Project/DATAFACTORY/.memory/`
