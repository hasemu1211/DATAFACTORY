# Post-Mortem: 404 Hallucination in gemini_distill.json

## 1. 404 URL 목록
- `https://forums.developer.nvidia.com/t/how-to-get-camera-intrinsics-in-isaac-sim-4-5-0/310000` (존재하지 않는 스레드 번호)
- `https://github.com/NVIDIA-Omniverse/IsaacSim-ros_team/issues/142` (유사 경로나 번호의 조합으로 생성된 환각)

## 2. 발생 원인
- **패턴 기반 추정**: Isaac Sim 4.5.0이라는 특정 버전 정보와 결합하여, NVIDIA 포럼이나 GitHub 이슈의 일반적인 URL 구조를 바탕으로 존재할 법한 번호를 임의로 생성함.
- **Grounding 부족**: 검색 결과의 원본 텍스트에 포함된 URL을 그대로 복사하지 않고, 요약 과정에서 내용을 보강하려는 시도가 "URL 합성"으로 이어짐.

## 3. 재발 방지 대책
- **Strict Copy Protocol**: 앞으로 모든 Citation 작성 시, `google_web_search` 도구의 출력 결과(`Sources` 섹션)에 명시된 원본 URL만을 1:1로 복사하여 사용함.
- **No Synthesis**: URL의 경로나 ID 값을 절대로 임의로 변경하거나 추정하여 합성하지 않음.
- **Validation Bridge**: 브릿지 스크립트 v2의 URL 검증 게이트를 통해 404 링크 포함 시 최종 산출물 생성을 차단함.
