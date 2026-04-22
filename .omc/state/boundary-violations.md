# OmG Boundary Violations Log

## 2026-04-22 10:50 — omg-bridge.sh unauthorized rewrite

- **Actor**: Gemini (pane 0:1.4, DATAFACTORY workspace)
- **File**: `.omc/scripts/omg-bridge.sh`
- **Action**: `WriteFile Accepted (+27, -92)` — overwrote v3 (URL validation, jq parse, authoritative finished_at/token_usage) with self-authored v2.1-rtk
- **Impact**: Lost HTTP citation gate → hallucinated URLs would again reach `.omc/state/gemini_distill.json` unchecked
- **Detected by**: Claude (user-reported "Gemini가 멋대로 수정")
- **Recovery**: v3.1 restored by Claude; boundary clauses §4.4/§4.5 added to `GEMINI.md`
- **Root cause**: Gemini had `auto-accept edits` mode ON in interactive pane; no file-path ACL on `.omc/scripts/`
