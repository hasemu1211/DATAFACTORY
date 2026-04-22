#!/usr/bin/env bash
# omg-bridge.sh v3.1 — OMC↔OmG Handoff Bridge (Claude-owned, do not modify from Gemini)
#
# Flow:
#   1. Read .omc/state/pending_research.md
#   2. gemini -e none -m flash-lite -p "..." --output-format json  (no OmG fan-out)
#   3. Extract envelope.response → strip optional ```json fences → parse inner JSON
#   4. HTTP-validate each citation, partition into valid / citations_invalid[{url,http}]
#   5. Override finished_at (date -u) and token_usage (from envelope.stats) — Gemini cannot fake them
#   6. Write .omc/state/gemini_distill.json. Exit 2 if zero valid citations.
#
# Ownership: .omc/scripts/ is under Claude (OMC). Gemini MUST NOT edit this file.
# See .omc/specs/omg-integration-v1.md §2.2 (State Manager = Claude).
#
# Env vars:
#   OMG_BRIDGE_MODEL   (default: gemini-2.5-flash-lite; for heavy web grounding use gemini-3-flash-preview)
#   OMG_BRIDGE_TIMEOUT (default: 180s; extend for multi-source research)
#
# Template for input:  .omc/state/pending_research.md.template

set -euo pipefail

INPUT_FILE=".omc/state/pending_research.md"
OUTPUT_FILE=".omc/state/gemini_distill.json"
ENVELOPE="$OUTPUT_FILE.envelope.tmp"
TIMEOUT_SEC="${OMG_BRIDGE_TIMEOUT:-180}"
MODEL="${OMG_BRIDGE_MODEL:-gemini-2.5-flash-lite}"

for bin in gemini jq curl python3; do
    command -v "$bin" &>/dev/null || { echo "ERROR: $bin not installed." >&2; exit 1; }
done

[[ -f "$INPUT_FILE" ]] || { echo "INFO: No pending research at $INPUT_FILE"; exit 0; }

echo "Starting Gemini research (timeout=${TIMEOUT_SEC}s, model=$MODEL, -e none) for: $(head -n 1 "$INPUT_FILE")..."

PROMPT="단일 턴으로만 답하라. 도구 반복 루프 금지. 외부 검색은 최대 1회.
다음 연구 요청에 대해 JSON 객체 하나만 출력하라. 설명·마크다운 펜스·서술 문장 금지.
스키마: {\"summary\": \"<3-5문장 요약>\", \"citations\": [\"<url>\", ...], \"code_snippets\": [\"<code>\", ...]}
citations 규칙: 실제 접근 가능한 공식 문서 URL만. 확실하지 않으면 빈 배열. 추정·합성 금지.
문자열 규칙: LaTeX·수식은 일반 텍스트로 서술 (예: 'fx = f*W/w'). 역슬래시 사용 금지. JSON 이스케이프 규칙을 엄격히 지켜라.

요청:
$(cat "$INPUT_FILE")"

# -e none: disables OmG extension → avoids omg-researcher fan-out (15-20s amplification).
if ! timeout "${TIMEOUT_SEC}s" gemini -e none -m "$MODEL" -p "$PROMPT" --output-format json > "$ENVELOPE" 2>/dev/null; then
    echo "ERROR: gemini -p failed or timed out (${TIMEOUT_SEC}s)." >&2
    rm -f "$ENVELOPE"
    exit 1
fi

if ! jq -e . "$ENVELOPE" >/dev/null 2>&1; then
    echo "ERROR: gemini envelope is not valid JSON." >&2
    head -c 500 "$ENVELOPE" >&2; echo >&2
    rm -f "$ENVELOPE"
    exit 1
fi

RESPONSE=$(jq -r '.response // empty' "$ENVELOPE")
if [[ -z "$RESPONSE" ]]; then
    echo "ERROR: empty .response in gemini envelope." >&2
    rm -f "$ENVELOPE"
    exit 1
fi

# Strip optional markdown fences, extract first balanced JSON object.
# String-aware scanner (Python) — LaTeX like \frac{a}{b} inside string values
# would fool a naive brace counter.
INNER=$(printf '%s' "$RESPONSE" | sed -e 's/^```json//' -e 's/^```//' -e 's/```$//' | python3 -c '
import sys, re, json
s = sys.stdin.read()
# 1. Extract first balanced JSON object, string-aware
i = s.find("{")
if i < 0: sys.exit(1)
depth=0; in_str=False; esc=False; start=i; end=-1
for j in range(i, len(s)):
    c = s[j]
    if in_str:
        if esc: esc=False
        elif c == "\\": esc=True
        elif c == "\"": in_str=False
    else:
        if c == "\"": in_str=True
        elif c == "{": depth+=1
        elif c == "}":
            depth-=1
            if depth == 0:
                end = j+1; break
if end < 0: sys.exit(1)
raw = s[start:end]
# 2. Try strict parse; if it fails, repair invalid backslash escapes (LaTeX) and retry
def repair(t):
    # double any backslash not followed by a valid JSON escape char
    return re.sub(r"\\(?![\"\\/bfnrtu])", r"\\\\", t)
try:
    obj = json.loads(raw)
except json.JSONDecodeError:
    try:
        obj = json.loads(repair(raw))
    except json.JSONDecodeError as e:
        sys.stderr.write(f"repair-failed: {e}\n"); sys.exit(1)
print(json.dumps(obj, ensure_ascii=False))
')

if [[ -z "$INNER" ]] || ! printf '%s' "$INNER" | jq -e . >/dev/null 2>&1; then
    echo "ERROR: inner research JSON not parseable or empty." >&2
    echo "--- response (first 500 chars) ---" >&2
    printf '%s' "$RESPONSE" | head -c 500 >&2; echo >&2
    rm -f "$ENVELOPE"
    exit 1
fi

# HTTP validation of citations
VALID='[]'; INVALID='[]'
while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    code=$(curl -sSIL -o /dev/null -w "%{http_code}" --max-time 8 "$url" || echo "000")
    if [[ "$code" =~ ^[23] ]]; then
        VALID=$(jq --arg u "$url" '. + [$u]' <<<"$VALID")
    else
        echo "WARN: citation unreachable ($code): $url" >&2
        INVALID=$(jq --arg u "$url" --arg c "$code" '. + [{url:$u, http:$c}]' <<<"$INVALID")
    fi
done < <(printf '%s' "$INNER" | jq -r '.citations[]? // empty')

TOK_IN=$(jq '[.stats.models[]?.tokens.prompt // 0] | add // 0' "$ENVELOPE")
TOK_OUT=$(jq '[.stats.models[]?.tokens.candidates // 0] | add // 0' "$ENVELOPE")
SESSION_ID=$(jq -r '.session_id // ""' "$ENVELOPE")
FINISHED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

printf '%s' "$INNER" | jq \
    --argjson valid "$VALID" \
    --argjson invalid "$INVALID" \
    --argjson ti "$TOK_IN" --argjson to "$TOK_OUT" \
    --arg sid "$SESSION_ID" --arg ts "$FINISHED_AT" \
    '.citations = $valid
     | .citations_invalid = $invalid
     | .token_usage = {input:$ti, output:$to}
     | .provider = "gemini-cli"
     | .session_id = $sid
     | .finished_at = $ts' > "$OUTPUT_FILE"

rm -f "$ENVELOPE"

VN=$(jq '.citations | length' "$OUTPUT_FILE")
IN=$(jq '.citations_invalid | length' "$OUTPUT_FILE")
echo "SUCCESS: $OUTPUT_FILE (citations valid=$VN, invalid=$IN, tokens in=$TOK_IN out=$TOK_OUT, finished_at=$FINISHED_AT)"

if [[ "$VN" -eq 0 ]]; then
    echo "ERROR: No valid citations — distill rejected for V&V reasons." >&2
    exit 2
fi
