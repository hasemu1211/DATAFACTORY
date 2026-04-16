# NotebookLM CLI 활용 가이드 (DATAFACTORY 프로젝트)

## 현재 활성 노트북
- **Isaac Sim and Robotics Simulation DATAFACTORY** (`7cf81435-cc9d-419e-8dfa-fe88c02dfa42`)

## 기본 사용법

```bash
# 활성 노트북 확인
python3 -m notebooklm status

# 노트북 전환
python3 -m notebooklm use 7cf81435

# 질문하기
python3 -m notebooklm ask "질문 내용"
```

---

## 소스 관리

### 추가
```bash
# URL 추가
python3 -m notebooklm source add --url "https://..."

# 로컬 파일 업로드 (PDF, MD, TXT)
python3 -m notebooklm source add --file "paper.pdf"

# Google Drive 파일 연동
python3 -m notebooklm source add-drive "파일명"

# 웹 검색 후 자동 추가
python3 -m notebooklm source add-research "Isaac Sim ROS2 synchronization"
```

### 로컬로 가져오기
```bash
# 소스 목록 확인
python3 -m notebooklm source list

# 소스 전체 텍스트 추출 (로컬에서 읽기 가능)
python3 -m notebooklm source fulltext <SOURCE_ID>

# AI 요약 + 키워드 추출
python3 -m notebooklm source guide <SOURCE_ID>

# 소스 새로고침 (URL 업데이트 시)
python3 -m notebooklm source refresh <SOURCE_ID>
```

---

## 콘텐츠 생성 및 다운로드

### 생성
```bash
python3 -m notebooklm generate report      # 마크다운 리포트
python3 -m notebooklm generate mind-map    # 마인드맵 (JSON)
python3 -m notebooklm generate quiz        # 퀴즈
python3 -m notebooklm generate slide-deck  # 슬라이드 (PDF/PPTX)
python3 -m notebooklm generate data-table  # 데이터 테이블 (CSV)
python3 -m notebooklm generate audio       # 오디오 오버뷰
```

### 로컬 저장
```bash
python3 -m notebooklm download report      # → .md 파일
python3 -m notebooklm download mind-map    # → .json 파일
python3 -m notebooklm download data-table  # → .csv 파일
python3 -m notebooklm download slide-deck  # → .pdf/.pptx 파일
python3 -m notebooklm download audio       # → 오디오 파일
```

---

## 대화 및 노트 관리

```bash
# 대화 이력 확인
python3 -m notebooklm history

# 노트 생성
python3 -m notebooklm note create "내용"

# 노트 목록
python3 -m notebooklm note list
```

---

## DATAFACTORY 프로젝트 활용 시나리오

| Phase | 활용 방법 |
|---|---|
| Phase 1-4 개발 중 | `ask` 로 Isaac Sim 버전별 버그/API 자문 |
| 새 논문 발견 시 | `source add --url` 로 즉시 추가 |
| 소스 내용 Claude에게 전달 | `source fulltext` 로 텍스트 추출 후 참조 |
| Phase 5 문서화 | `generate report` → `download report` → README 보조 |
| 학습/리뷰 | `generate quiz`, `generate mind-map` |

---

## 주의사항
- 세션 인증: `~/.notebooklm/storage_state.json` (전역, 몇 주마다 재인증 필요)
- 무료 tier 쿼리 한도: ~50회/일
- 비공개 Google 내부 API 기반 → 언제든 변경 가능
- 긴 코드 응답은 잘릴 수 있음 → 검토 후 수정 필요

## Claude Code와 역할 분담

| 도구 | 역할 |
|---|---|
| **NotebookLM** | Isaac Sim 버전별 버그, 비공개 API, NVIDIA 포럼 이슈 |
| **Claude Code** | NumPy 행렬 연산, ROS 2 표준 코드, 수학 검증, 실행 |
| **context7** | NumPy, OpenCV 등 표준 라이브러리 최신 문서 |
