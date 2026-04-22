# Research Request: Phase 2 Projection Error Verification

## Objective
LIMO PRO 로봇의 카메라 K 행렬을 추출하고, Isaac Sim 4.5.0 환경에서 3D 공간 좌표가 2D 이미지 평면으로 투영될 때의 오차(ε)를 수학적으로 검증하기 위한 최신 레퍼런스를 수집하라.

## Key Questions
1. Isaac Sim 4.5.0에서 카메라 내역(Intrinsics)을 얻는 최신 Python API 호출 방법.
2. OpenCV 정합성을 위한 K 행렬 변환 공식 (Omniverse vs OpenCV).
3. 투영 오차 검증을 위한 지표(Reprojection Error) 측정 사례 3건.

## Constraints
- 반드시 Isaac Sim 4.5.0 (`isaacsim.core.api`) 기준일 것.
- 수식(LaTeX) 포함 권장.
