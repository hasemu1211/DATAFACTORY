# Plan: Robot OMC Role-Scoped Distillation (iteration 2)

- Plan ID: `robot-omc-role-scoped-distillation`
- Source spec: `/home/codelab/robot/datafactory/.omc/specs/deep-interview-robot-omc-role-scoped-distillation.md`
- Spec status: PASSED (revised) — Ambiguity 18%, 5 rounds, 3 Critical decisions locked
- Generated: 2026-04-20 (iter 1), revised 2026-04-20 (iter 2 — Architect + Critic feedback applied)
- Mode: consensus (RALPLAN-DR)
- Meta-criteria for every decision: (1) OMC-native (2) 장기유지 / drift 최소화 (3) 토큰 효율 (4) 개발 효율
- Related artifacts:
  - `/home/codelab/robot/.omc/plans/robot-setup-repo-plan.md` (iteration 1 baseline, 48 KB)
  - `/home/codelab/robot/.omc/research/skill-gap-analysis-20260420.md`
  - `/home/codelab/robot/wiki/ecosystem_survey.md`
  - `/home/codelab/robot/datafactory/robot-dev-omc-setup-guide.md` (§3–5, §11, §12, §13)
  - `/home/codelab/robot/datafactory/notebooklm-cli-guide.md`

### Iteration 2 change log (Architect + Critic fixes)

- **B1** Added Phase A-0 empirical schema probe (writes promotion-worthy `wiki/mcp_lessons.md` entry).
- **B2** AC-2 rewritten to absolute-target methodology (Option Beta); 30% directional claim dropped.
- **B3** AC-5 Case B unified to "block via scope" (Option X); no warning mechanism invented.
- **B4** AC-1 measurement fixed to extract `additionalContext` field only, and re-scoped to bytes + functional parity.
- **H5** R8 added: symlink MCP path resolution risk; pre-Phase-B assertion defined.
- **H6** ADR authored in §6 (with D-3 PROVISIONAL flag on Consequences-a, not stub-deferred).
- **H7** Return-value JSON schema hardened — servants MUST emit `## Result` fenced JSON block.
- **M8** R6 bootstrap AGENTS.md cleanup uses fenced markers instead of fragile `sed`.
- **M9** R1 mitigation gains concrete weekly trigger command + owner action.
- **L10** R4 drift audit gains concrete `diff` command + log location.
- **L11** KD2 Option C rejection steelmanned (not "4× drift surface").

### Session-2 amendments (2026-04-20, post-consensus, pre-execution)

- **AM-1 Schema discovery** — 정적 검사로 확인: OMC shipped agents 8/8는 `disallowedTools:` (Schema γ) 사용. allow-list α는 사용 예 0. β(`tools:`)는 docs/REFERENCE + SDK에서 canonical. Phase A-0 probe는 2-way(α/β) 대신 **3-way(α/β/γ)** 또는 **γ 직접 채택 + β 보조 실험**로 업데이트.
- **AM-2 Agent 정의 위치 변경** — `~/robot/.claude/agents/` 경로는 **세션 project 루트가 `~/robot/`일 때만 발견됨**. Parent에는 MCP(`.mcp.json`)가 없어 planner 세션을 parent에서 시작하면 isaac-sim/ros-mcp가 로드되지 않는다. 해결: **agent 정의를 유저 스코프(`~/.claude/agents/*.md`)로 이동**. 이식성 ◎ (모든 robot child에서 발견), OMC 내장 agent와 동급 계층.
- **AM-3 세션 시작 cwd 변경** — `cd ~/robot/datafactory && claude`로 시작. 이유: datafactory `.mcp.json`에 isaac-sim + ros-mcp. planner 세션이 이 MCPs를 가져야 servant 위임 시 도메인 MCP 접근 가능.
- **AM-4 AC-5 Case B 재정의** — 세션 cwd가 datafactory이므로 planner 쪽에서 `mcp__isaac-sim__*` 직접 호출은 **시스템 차원 차단 불가** (tool이 cwd에 등록되어 있음). 정책을 **"규율 기반"**으로 전환: planner는 isaac-sim/ros-mcp를 직접 호출하지 말고 servant에 delegate. 검증은 세션 transcript audit. 2회 위반 시 방식 Y(tmux pane 격리)로 escalate.
- **AM-5 Revisit trigger** — N-child 환경 또는 planner 규율 위반 2회 시 방식 Y(`omc-teams` tmux pane)로 마이그레이션 고려. Agent 정의는 유저 스코프 유지이므로 전환 비용 최소.
- **AM-6 Schema 최종 확정 (2026-04-21 세션 3 첫 턴)** — **γ 단독 채택**. β+γ 병용 기각. 근거: 4-meta-criteria(OMC-native, drift 최소화, 토큰 효율, 개발 효율) 모두 γ 단독 우세 + β+γ의 implicit-grant 방어는 **R4 Version Audit Log** (OMC bump마다 template diff)로 충분히 커버됨. Phase A-0 probe는 α/β 비교 생략, **γ-only 확인 probe 1회**로 축약 (실제 `disallowedTools:` declaratively 차단 확인). 미래 override 조건: 외부 compliance 증명 책임 발생 시 β+γ로 확장.
- **AM-7 docker-operator default 확정 (2026-04-21 세션 3 첫 턴)** — **default off (authored-only)**. open-questions #6의 자기-지연 지침("decide after first Phase 2 long-running Replicator run")을 그대로 존중. Phase A-1에서 `~/.claude/agents/docker-operator.md` 정의는 작성(R5 symlink path collision cleanup on-demand 용). 기본 워크플로우에서는 planner가 Bash로 `docker compose` 직접 실행 + `docker compose ls | jq 'length' == 1` pre-assert(R5 기재). Phase 2 Replicator 첫 장기 run 이후 재평가 → 실측 collision 재발 시 "standard" 승격.

---

## 1. Requirements Summary (from spec Goal + Constraints)

**Goal.** Produce an OMC-native profile for the robot parent (`~/robot/`) + children (datafactory + future) that asymmetrically separates MCPs / plugins / tools by role. Planning tier (main Claude) keeps only research-style tools (search / docs / NotebookLM CLI) hot; servant agents (Agent tool, tmux panes, optional custom class) receive a single domain MCP (isaac-sim **or** ros-mcp) and report **only through return value**.

**In-scope (this plan).**
- Translate the design in `robot-dev-omc-setup-guide.md` §3–5 / §11 into OMC-native contracts (Agent definitions + planner profile doc) for parent + `datafactory` child.
- Keep everything drop-in for future children via the existing `~/robot/scripts/bootstrap-child.sh`.
- Lock Round 3–5 Critical decisions:
  - **Docker = Bash-only** (no Docker MCP plugin).
  - **Git = planner phase/feature atomic commit** (servants do file edits only, no `git commit`).
  - **Cross-tier flow = Return-value only**; servants lose `notepad_*` / `wiki_*` / `shared_memory_*` / `project_memory_*`.

**Out-of-scope (spec Non-Goals, do NOT reopen).**
- `/robot:mcp-on/off` style slash commands (directory isolation is the toggle — setup-guide §11).
- New MCP plugins in servants (Docker MCP skip, git-mcp skip).
- Doc-driven config automation (AGENTS.md → .mcp.json auto-sync).
- CI/hook-based drift detection.
- A design that assumes Anthropic #16177 / #4476 / #32514 are fixed.
- Gazebo / MoveIt / PyBullet MCP authorship.

**Hard constraints inherited from spec + user message (plan MUST honor).**
- No `/robot:mcp-on/off` slash commands.
- No new MCP plugins (Docker MCP skip, git-mcp skip).
- Servants get zero persistence tools.
- Commits are end-of-phase atomic, by planning tier only.

---

## 2. Acceptance Criteria (refined, testable)

Each AC below cites the spec source line (`deep-interview-robot-omc-role-scoped-distillation.md`) plus a concrete verification lane (the same AC-id is used in §5 Verification).

### AC-1 — Token budget, SessionStart context (spec line 57)
- **Metric.** Record byte count of the `additionalContext` **field** emitted by the `SessionStart` hook in `~/robot/datafactory/.claude/settings.local.json` (strip the jq envelope — see fixed command in §5). Capture baseline once before distillation and again after.
- **Target.** Goal-direction `< 5k characters of additionalContext` at steady state. **Primary pass/fail gate** = zero functional regression, owned by AC-3 smoke. AC-1 by itself is directional — it flags excess, but does not block the phase.
- **Evidence file.** `~/robot/wiki/omc_robot_profile.md` → `## Token Budget` table (baseline chars, post chars, delta, methodology).

### AC-2 — Post-distillation servant-call token ceiling (spec line 58) — **Option Beta**
- **Metric.** Post-distillation **absolute** mean tokens per servant call, measured in a single instrumented probe run. Target set empirically: `mean_tokens_per_isaac-operator_call ≤ 8_000` and `mean_tokens_per_ros2-operator_call ≤ 8_000` across N≥5 canned probes per agent type, 95% confidence interval reported.
- **Why Option Beta.** `.omc/logs/` was verified non-existent at both `~/robot/.omc/logs/` and `~/robot/datafactory/.omc/logs/` at planning time (Critic finding), so a pre-distillation comparative baseline is unfalsifiable. Directional-improvement language is dropped.
- **Instrumentation.** Planner records token spend for each Agent call via the hook log line in `.claude/` transcripts (or the session JSONL), extracted post-call. Methodology, instrumentation exact-location, N, and CI documented in `wiki/omc_robot_profile.md` §Token Methodology (new sub-section under §Agent Call Cost).
- **Target adjustment rule.** If first probe's mean exceeds 8k tokens but is explained by payload (e.g. Isaac scene dump), raise the ceiling to observed + 10% and document the rationale in-table. The ceiling is a contract on the servant **contract bloat**, not on domain payload size.
- **Evidence file.** `~/robot/wiki/omc_robot_profile.md` → `## Agent Call Cost` table + `## Token Methodology` sub-section.

### AC-3 — Phase 1 smoke reproducibility (spec line 59)
- **Metric.** Re-run the existing DATAFACTORY Phase 1 smoke (Isaac Sim MCP on :8766 + rosbridge on :9090 + `execute_script` on Isaac 4.5.0 round-trip) under the **new** role-separated wiring. Pass = identical outcome to the recorded pass that precedes this plan (parent commit ancestors `f681100`, `5df7f8d`, `de395ca`; see setup-guide §10 "BLOCKING smoke").
- **Target.** `get_scene_info()` returns non-null; `connect_to_robot()` + `get_topics()` returns a non-empty list; `execute_script` round-trip matches 4.5 API (no `iray` crash) per `wiki/isaac_sim_api_patterns.md`.
- **Evidence file.** `wiki/mcp_lessons.md` → append a dated "post-distillation smoke" entry.

### AC-4 — `omc_robot_profile.md` contract complete (spec line 60)
- **Required sections** (must all exist, each non-empty):
  1. Planner tier tool/MCP list (with `superpowers` skills + OMC skills used).
  2. Servant agent matrix: `isaac-operator`, `ros2-operator`, optional `docker-operator` — each row gives `allowedTools[]` **or** `tools:` (per A-0 branch), `mcpServers{}` (if applicable), `model`, `cwd`.
  3. NotebookLM CLI block (active notebook ID, 5 canonical commands, "planner-only" rule).
  4. 3-Layer structure summary (`setup-guide §11`).
  5. Portability procedure (`bootstrap-child.sh` checklist).
  6. Token budget table (AC-1 evidence).
  7. Agent call cost table + Token Methodology sub-section (AC-2 evidence).
  8. MCP/skill alternative verdict table (AC-8 evidence).
  9. **Scope schema branch record** (A-0 output): which YAML frontmatter form proved declaratively enforcing.
  10. **Version Audit Log** (R4 evidence target).
- **Location.** `~/robot/wiki/omc_robot_profile.md` (parent wiki).

### AC-5 — Servant scope-violation tests (spec line 61, test table at spec L112–L114) — **session-2 AM-4: discipline-based for Case B**
- **Case A.** Invoke `isaac-operator` Agent with a request that requires `mcp__plugin_context7_context7__*` → servant must refuse / return error citing the frontmatter restriction (`disallowedTools` per Branch γ, or `tools:` per Branch β).
- **Case B (AM-4 재정의).** 세션 cwd는 `~/robot/datafactory/`라서 isaac-sim MCP가 planner tier에 로드되어 있음 — 시스템 차원 "unknown tool" 차단 **불가**. 정책은 **규율(discipline) 기반**: planner가 `mcp__isaac-sim__*` / `mcp__ros-mcp__*`를 직접 호출하지 말고 servant에 delegate해야 함. **검증**: Phase D 세션 transcript audit으로 직접 호출 건수 집계 (기대: 0). ≥1건 발견 시 `wiki/omc_robot_profile.md` §Discipline Violations에 로그 + revisit trigger(Y tmux pane migration) 카운트+1.
- **Case C.** Request `notepad_write_working` from inside `isaac-operator` → refused (frontmatter `disallowedTools`에 포함).
- **Evidence file.** `wiki/omc_robot_profile.md` → `## Scope Violation Tests` section with `PASS / FAIL` per case (Case B는 audit 건수로), plus exact refusal text for A/C.

### AC-6 — Portability smoke (spec line 62)
- **Metric.** Run `~/robot/scripts/bootstrap-child.sh scratch-lab --dry-run`, then a live run against `scratch-lab` (throwaway). Verify that (a) `scratch-lab/.claude/settings.json` contains both `SessionStart` and `PostCompact` hooks with `PARENT=$HOME/robot`, (b) `scratch-lab/.mcp.json` is the empty `{"mcpServers":{}}` scaffold, (c) `scratch-lab/wiki/INDEX.md` stub exists, (d) parent `AGENTS.md` now contains a `scratch-lab/` Children entry **between fenced markers** (see R6 in §4). MCP-level connectivity is **not** asserted (out of scope per spec).
- **Evidence file.** `wiki/omc_robot_profile.md` → `## Portability Smoke` (command trace + diff).

### AC-7 — NotebookLM CLI one-page capture (spec line 63)
- **Metric.** A one-page block inside `wiki/omc_robot_profile.md` (or a standalone `wiki/notebooklm_workflow.md` linked from `omc_robot_profile.md`) covering: active notebook ID `7cf81435-cc9d-419e-8dfa-fe88c02dfa42`, the 5 canonical commands (`status`, `use`, `ask`, `source add --url`, `source add-research`), the "planner-only" invocation rule, and rate-limit notes (`~50 queries/day`, session auth `~/.notebooklm/storage_state.json`).

### AC-8 — MCP/Skill alternatives verdict (spec line 64)
- **Required rows.**
  - Current Isaac MCP stay vs alternatives (NVIDIA-Omniverse/IsaacSim-MCP, `omni.kit.exec_script` thin wrapper, Robosynx / Isaac Monitor).
  - Current ros-mcp stay vs alternatives (`robotmcp/ros-mcp-server`, `lpigeon/ros-mcp-server`, direct rclpy, `hijimasa/isaac-ros2-control-sample`).
  - Shortlist of ≥ 3 new skills/MCPs NOT yet adopted (bucketed `adopt / trial / watch`) — candidates from `wiki/ecosystem_survey.md` §T4–T5: `superpowers:test-driven-development` (adopt), `oh-my-claudecode:visual-verdict` (trial), `oh-my-claudecode:configure-notifications` (trial), Exa MCP (trial), Docker MCP Toolkit (skip — locked by Critical-3), filesystem-mcp per-child (watch).
- **Cross-checks required.** NVIDIA forum MCP tutorial diff vs `wiki/mcp_lessons.md` §MCP extension 활성화; `context7.resolve-library-id("isaac-sim")` + `("ros2")` coverage audit.
- **Evidence file.** `wiki/omc_robot_profile.md` → `## Alternatives Audit` table.

---

## 3. Implementation Steps

Four phases (A with new A-0 sub-phase, then B-D), executed in order. Each phase is a **single atomic commit by the planning tier** (Critical decision #2). No servant agent commits.

### Phase A — Agent definitions + Planner-tier profile scaffold (satisfies AC-4 skeleton, preps AC-5)

#### A-0. Empirical schema probe — **(NEW, BLOCKER fix B1; session-2 updated to 3-way)**

Before writing any servant definitions, determine which YAML frontmatter schema is actually **declaratively** enforced by this Claude Code runtime. Three candidate schemas identified (session-2 AM-1 amendment):

- **Schema α (original plan assumption):** `allowedTools:` YAML list + inline `mcpServers: {...}` object inside frontmatter. **Static evidence: 사용 예 0** in OMC / superpowers / skill-creator / docs as of 2026-04-20. Likely cosmetic or unsupported.
- **Schema β (documented default):** `tools: Read, Edit, Bash` comma-separated string in frontmatter + cwd-scoped `.mcp.json` at invocation directory. **Static evidence:** `docs/REFERENCE.md:193`, `TIERED_AGENTS_V2.md:265`, `src/agents/AGENTS.md:112`, SDK `cli.js:4118`. Documented and runtime-referenced.
- **Schema γ (OMC convention):** `disallowedTools: Write, Edit` comma-separated deny-list. **Static evidence:** OMC shipped agents 8/8 (architect/explore/critic/analyst/scientist/code-reviewer/security-reviewer/document-specialist). This is the actually-shipped OMC pattern.

Recommended default: **Schema γ** (OMC-native convention — matches shipped agents, zero drift, maximum portability). β can be combined for allow-list hardening if needed. α skipped (no evidence of support).

**Protocol.**
1. Write `~/robot/.claude/agents/probe-scope-alpha.md` using Schema α:
   ```yaml
   ---
   name: probe-scope-alpha
   description: SCHEMA PROBE (alpha) — do not use for real work. Tests allowedTools + inline mcpServers enforcement.
   model: haiku
   allowedTools:
     - Read
   mcpServers: {}
   ---
   ```
   Body: "If asked to use any tool other than Read, attempt it and honestly report the error raised."
2. Write `~/robot/.claude/agents/probe-scope-beta.md` using Schema β:
   ```yaml
   ---
   name: probe-scope-beta
   description: SCHEMA PROBE (beta) — do not use for real work. Tests tools: + cwd-scoped .mcp.json enforcement.
   model: haiku
   tools: Read
   ---
   ```
   Body: identical instruction.
3. Invoke each probe from planner tier with prompt: "Call `mcp__context7__resolve-library-id('isaac-sim')` and report what happens."
4. Classify the response:
   - **Declarative refusal** = schema parsed the restriction; Claude explicitly reports "tool not in `allowedTools`" / "tool not in `tools:`".
   - **Absent / silent** = tool was simply not registered at this cwd; no evidence the frontmatter list actively blocked anything (false-positive enforcement).
5. **Branch.**
   - **Branch α (Schema α declarative):** Proceed with A-1 using `allowedTools:` + inline `mcpServers`. (Low prior — no static evidence of support.)
   - **Branch β (Schema β declarative):** Rewrite A-1 to use `tools: <comma-list>` + cwd-scoped `.mcp.json`.
   - **Branch γ (Schema γ declarative — RECOMMENDED):** Use `disallowedTools: <deny-list>` + cwd-scoped `.mcp.json`. Matches OMC shipped convention.
   - **Branch β+γ (both declarative):** Combine — `tools:` (allow-list) + `disallowedTools:` (explicit deny-list for clarity). Belt-and-suspenders.
   - **Branch STOP (none declarative — all silent):** Escalate to user. The role-boundary policy rests on declarative enforcement; without it, AC-5 is untestable.
6. Delete probe agent files after the experiment (they are throwaway).
7. **Record outcome** in `wiki/mcp_lessons.md` under new heading `## 2026-04-20 — Agent frontmatter scope enforcement probe` with the exact refusal text (or its absence) from each probe. This entry is **promotion-worthy**: it documents a previously ambiguous Claude Code behavior.
8. **Pre-B-0 symlink MCP path assertion (NEW, HIGH fix H5).** Before Phase B, run:
   ```bash
   test -e "$(cd ~/robot/datafactory && cd .. && pwd)/isaac-sim-mcp" \
     || echo "WARNING: MCP path resolution ambiguous — datafactory is a symlink; relative MCP paths in .mcp.json resolve via symlink target, not ~/robot/"
   ```
   Mitigation (if warning fires): document in `wiki/mcp_lessons.md` that MCP paths in `.mcp.json` of symlinked children must be absolute (or relative-from-symlink-target). Extend setup-guide §13h (currently Docker-only) with an MCP note.

#### A-1. Author servant agent definitions (conditional on A-0 branch; session-2 AM-2: **user-scope path**)

**Location**: `~/.claude/agents/` (USER SCOPE, not `~/robot/.claude/agents/`). 이유: datafactory 세션에서 parent 경로는 discovery 안 됨. 유저 스코프는 모든 robot child에서 발견되며 OMC 내장 agent와 동급 계층.

**If Branch γ (RECOMMENDED — OMC convention).**
- Write `~/.claude/agents/isaac-operator.md`:
  ```yaml
  ---
  name: isaac-operator
  description: Isaac Sim domain servant. Delegated for execute_script, scene probing, RTX renderer ops. Reports via return value only.
  model: sonnet
  disallowedTools: Write, mcp__plugin_context7_context7__resolve-library-id, mcp__plugin_context7_context7__query-docs, mcp__ros-mcp__*, mcp__github-mcp-server__*, WebSearch, WebFetch, mcp__plugin_oh-my-claudecode_t__notepad_write_manual, mcp__plugin_oh-my-claudecode_t__notepad_write_priority, mcp__plugin_oh-my-claudecode_t__notepad_write_working, mcp__plugin_oh-my-claudecode_t__wiki_add, mcp__plugin_oh-my-claudecode_t__wiki_delete, mcp__plugin_oh-my-claudecode_t__wiki_ingest, mcp__plugin_oh-my-claudecode_t__shared_memory_write, mcp__plugin_oh-my-claudecode_t__shared_memory_delete, mcp__plugin_oh-my-claudecode_t__project_memory_add_directive, mcp__plugin_oh-my-claudecode_t__project_memory_add_note, mcp__plugin_oh-my-claudecode_t__project_memory_write
  ---
  ```
- `ros2-operator.md`: mirror structure with `mcp__ros-mcp__*` **not** in disallowedTools, but `mcp__isaac-sim__*` in disallowedTools.
- `docker-operator.md`: disallow everything except Bash + Read (no MCP, no git commit).

**If Branch β (allow-list).**
- Use `tools: Read, Edit, Bash, Grep, Glob, mcp__isaac-sim__*` (isaac-operator). MCP tokens in `tools:`.

**If Branch β+γ (combined — hardening).**
- Both `tools:` (allow-list) AND `disallowedTools:` (explicit deny for research/persistence tools).

**If Branch α (unlikely per static evidence, but possible).**
- Original plan text retained: `allowedTools:` + inline `mcpServers:`.

**Common to both branches.**
- Body describes: domain scope (Isaac 4.5.0 APIs only for isaac-operator; ROS 2 + rosbridge for ros2-operator), forbidden tools (explicit deny list mirroring spec L109: `mcp__context7__*`, `mcp__ros-mcp__*` (for isaac), `notepad_*`, `wiki_*`, `shared_memory_*`, `project_memory_*`, `git commit`, `docker compose up/down`).
- **Return-value contract (HARDENED per H7).** Servant MUST end its output with exactly two fenced blocks:
  ```
  ## Result
  ```json
  {"status": "success|fail", "artifact_paths": ["..."], "next_action": "..."}
  ```

  ## Evidence
  <free-form markdown: commands run, outputs, observations>
  ```
  Planner parses `## Result` JSON via a one-line `awk`/`jq` extractor; `## Evidence` is human-read only. If the JSON block is missing or unparseable, planner re-prompts once; on second failure, escalates.
- Target files (session-2 AM-2: **user scope**):
  - `~/.claude/agents/isaac-operator.md`
  - `~/.claude/agents/ros2-operator.md`
  - `~/.claude/agents/docker-operator.md`

#### A-2. Create planner-tier profile document.
- Create `/home/codelab/robot/wiki/omc_robot_profile.md` with the 10-section skeleton enumerated in AC-4 (§2). At this phase only the sections that do not yet need measurement get populated (1, 2, 3, 4, 5, 9). Empty tables for Token Budget (AC-1), Agent Call Cost + Token Methodology (AC-2), Scope Tests (AC-5), Portability (AC-6), Alternatives (AC-8), Version Audit Log (R4) are stubbed with `TBD (Phase X)` row placeholders.
- Include in section 1 (Planner tier) the explicit list: OMC skills `wiki`, `remember`, `external-context`, `ralplan`, `plan`, `verify`, `cancel`, `learner`, `skillify`, `trace`, `deep-interview`; superpowers `test-driven-development`, `receiving-code-review`, `finishing-a-development-branch`, `using-git-worktrees`; plus Bash, Read/Edit/Write, WebSearch/WebFetch, and NotebookLM CLI.
- Section 9 (scope schema branch record) is populated now with the A-0 outcome.
- Cross-link from `/home/codelab/robot/wiki/INDEX.md` (append one line).

#### A-3. Register profile in 2-Tier wiki hook.
- Verify `omc_robot_profile.md` is picked up by the parent `SessionStart` hook (it reads `~/robot/wiki/INDEX.md`, so only the INDEX link is needed — no hook change).

#### A-4. Atomic commit.
- Planner stages `~/robot/.claude/agents/{isaac,ros2,docker}-operator.md`, `~/robot/wiki/omc_robot_profile.md`, `~/robot/wiki/INDEX.md`, `~/robot/wiki/mcp_lessons.md` (A-0 outcome entry).
- Commit message style matches `f681100` / `de395ca`: `feat(omc): role-scoped agent definitions + scope schema probe + planner profile scaffold`.

### Phase B — Role-boundary enforcement test + Phase 1 smoke re-run (satisfies AC-3, AC-5)

**B-1. Session cwd 확인 (AM-3)**: 세션은 `~/robot/datafactory/` cwd에서 시작됨. datafactory `.mcp.json`의 isaac-sim + ros-mcp가 planner 세션에 로드. Parent `~/robot/.mcp.json`는 없거나 비어있음. Context7/github-mcp는 플러그인 레벨에서 제공.

**B-2. Execute AC-5 scope-violation probes (AM-4: discipline-based Case B).**
- **Case A** — spawn `isaac-operator` with the prompt "call `mcp__plugin_context7_context7__resolve-library-id` to look up isaac-sim docs". Expected: servant refuses because `context7` tool is in `disallowedTools`.
- **Case B (AM-4)** — Planner는 datafactory cwd에서 직접 `mcp__isaac-sim__execute_script`를 호출 **가능**(tool이 세션에 로드). 시스템 차단 불가. 대신 **세션 내 transcript audit**으로 planner의 직접 MCP 호출 건수 측정. 기대: 0건 (항상 servant로 delegate). 1건 이상이면 §Discipline Violations에 기록 + revisit trigger(Y migration) counter +1.
- **Case C** — spawn `isaac-operator` with "write a working-memory note via `notepad_write_working`". Expected: refusal.
- Log outcomes into `wiki/omc_robot_profile.md` §Scope Violation Tests with `PASS / FAIL` + exact refusal text (Case A/C), `audit count` (Case B).

**B-3. Re-run Phase 1 smoke under the new wiring.**
- From planner tier (`cd ~/robot/datafactory`) delegate to `isaac-operator` with prompt: "verify Isaac Sim 4.5 via `get_scene_info` then run a trivial `execute_script` round-trip" → capture return value, parse `## Result` JSON.
- Delegate to `ros2-operator` with prompt: "run `connect_to_robot` + `get_topics`" → capture return value, parse `## Result` JSON.
- Append `wiki/mcp_lessons.md` with a dated "post-distillation Phase 1 smoke" entry (planner does the write; servants never touch wiki).

**B-4. Atomic commit.**
- Planner stages `wiki/mcp_lessons.md` update + the §Scope Violation Tests section in `wiki/omc_robot_profile.md`.
- Commit message: `test(omc): role-boundary probes + post-distillation Phase 1 smoke`.

### Phase C — Portability smoke + alternatives audit (satisfies AC-6, AC-7, AC-8)

**C-1. Run `bootstrap-child.sh scratch-lab` smoke.**
- First `--dry-run`, capture stdout for evidence.
- Then real run (allow it, because `scratch-lab` is throwaway). Verify the 4 assertions in AC-6.
- Do **not** ask the script to connect an MCP server — out of scope (spec L62).
- **AGENTS.md fenced markers (per M8 fix).** `bootstrap-child.sh` must wrap its appended Children entry with:
  ```
  <!-- BOOTSTRAP_BEGIN:scratch-lab -->
  - `scratch-lab/` — ...
  <!-- BOOTSTRAP_END:scratch-lab -->
  ```
  Cleanup uses a fence-aware extraction (`sed -i '/<!-- BOOTSTRAP_BEGIN:scratch-lab -->/,/<!-- BOOTSTRAP_END:scratch-lab -->/d' ~/robot/AGENTS.md`) rather than fragile line-grep. If `bootstrap-child.sh` does not yet emit fences, Phase C-1 adds that feature (single-line edit) as part of the smoke.

**C-2. Populate NotebookLM CLI block (AC-7).**
- Inside `omc_robot_profile.md`, add the 1-page block: active notebook ID, 5 canonical commands (`status`, `use`, `ask`, `source add --url`, `source add-research`), planner-only rule, quota + auth note.
- Source: `/home/codelab/robot/datafactory/notebooklm-cli-guide.md` (distillation only).

**C-3. Populate Alternatives Audit table (AC-8).**
- Fill in Isaac / ROS2 alternative rows using `wiki/ecosystem_survey.md` §T2 + spec table at L118–L143 as baseline.
- Add ≥ 3 new skill/MCP shortlist rows, aligned with `.omc/research/skill-gap-analysis-20260420.md`.
- Execute the two required cross-checks:
  - NVIDIA forum MCP tutorial diff: use `document-specialist` (haiku) agent to fetch the forum thread, diff against `wiki/mcp_lessons.md` `§MCP extension 활성화`.
  - Coverage audit: from planner tier call `mcp__plugin_context7_context7__resolve-library-id("isaac-sim")` and `("ros2")`; record top candidate IDs.

**C-4. Open-questions flush.**
- Any residual investigation items go to `/home/codelab/robot/datafactory/.omc/plans/open-questions.md`.

**C-5. Atomic commit.**
- Stage `wiki/omc_robot_profile.md`, `wiki/ecosystem_survey.md` (if updated), `.omc/plans/open-questions.md`.
- Commit message: `docs(omc): portability smoke + NotebookLM capture + alternatives audit`.

### Phase D — Token-budget measurement + doc closure (satisfies AC-1, AC-2, AC-4)

**D-1. AC-1 measurement (fixed per B4).**
- Run the corrected hook-output extractor:
  ```bash
  cd ~/robot/datafactory
  BYTES=$(bash -c "$(jq -r '.hooks.SessionStart[0].hooks[0].command' .claude/settings.local.json)" \
    | jq -r '.hookSpecificOutput.additionalContext' \
    | wc -c)
  echo "additionalContext_bytes=$BYTES"
  ```
  (Note: this extracts the `additionalContext` **field only**, eliminating the jq envelope overcount that iteration 1 had.)
- Record pre-distillation snapshot (from git HEAD before this plan's Phase A commit — reconstruct by `git stash` or reading `.claude/settings.local.json` at that commit) and post-distillation snapshot.
- If `tiktoken` is available, record an optional token estimate alongside bytes; otherwise bytes is the authoritative unit for AC-1.

**D-2. AC-2 measurement (absolute-target, Option Beta).**
- Run N≥5 probes per servant:
  - `isaac-operator` on canonical prompt: "run `get_scene_info` then a 10-line `execute_script` that prints `isaacsim.__version__`".
  - `ros2-operator` on canonical prompt: "run `connect_to_robot` then `get_topics`".
- For each probe, capture total token spend of the Agent call from session JSONL / hook log.
- Compute mean + 95% CI per servant type.
- Assert `mean ≤ 8_000 tokens` (or raise ceiling with in-table justification per AC-2 adjustment rule).
- Document instrumentation exact location (session JSONL path / hook log entry field name), N, and CI method in `omc_robot_profile.md` §Token Methodology.

**D-3. Fill in tables.**
- `## Token Budget` table populated (AC-1 numeric evidence).
- `## Agent Call Cost` + `## Token Methodology` populated (AC-2 evidence).
- `## Version Audit Log` gets its first entry (OMC version at time of plan completion, chosen schema branch from A-0).
- All 10 sections in `omc_robot_profile.md` now non-empty → AC-4 closed.
- Remove PROVISIONAL flag on ADR Consequences-(a) — now measured.

**D-4. `superpowers:finishing-a-development-branch`.**
- Planner invokes `superpowers:finishing-a-development-branch` to present integration options (in-place commit to `main` vs PR). Default = atomic commit on `main` per existing repo style.
- Final commit message: `feat(omc): role-scoped distillation complete (AC-1..AC-8)`.

---

## 4. Risks and Mitigations

| # | Risk | Likelihood | Impact | Mitigation | Owner / phase |
|---|---|---|---|---|---|
| R1 | Anthropic issues #16177 / #4476 / #32514 ship while this plan is mid-flight, obsoleting the inline `mcpServers` + directory-isolation workaround | Low (roadmap uncommitted as of 2026-04) | Medium (would shrink the role matrix) | **Concrete trigger (M9 fix):** weekly `gh api repos/anthropics/claude-code/issues/16177 --jq '.state'` scan in planner's checklist; on `closed`, planner re-evaluates `.mcp.json` scope vs new official mechanism within 1 week and logs decision in `wiki/omc_robot_profile.md` §Version Audit Log. Plan's agent definitions are self-contained → in-place upgrade path preserved. | Planner, weekly + Phase D-4 |
| R2 | NotebookLM CLI session auth (`~/.notebooklm/storage_state.json`) expires or hits ~50 queries/day quota | Medium (~weekly re-auth) | Low (only AC-7 block + opportunistic research affected) | Document quota + re-auth command in AC-7 block. Planner-only rule prevents servants from silently exhausting quota. Fallback = `context7` + WebFetch. Do not block Phase 1 smoke on NotebookLM. | Planner, Phase C-2 |
| R3 | Servant return-value parsing drift — free-text markdown may be inconsistent between runs | Medium | Medium (planner re-runs → token waste) | **Hardened contract (H7 fix):** servant MUST emit `## Result` as fenced JSON (`{status, artifact_paths, next_action}`) followed by `## Evidence` free text. Planner `jq`-parses `## Result`; if missing/unparseable, re-prompts once then escalates. Parsing failures logged in `omc_robot_profile.md` §Servant Contract Drift. Servant `learner` / `skillify` are planner-side only. | Planner, Phase A-1 + B-3 |
| R4 | `isaac-operator` / `ros2-operator` drift from OMC upstream (`skill-creator` templates); future `omc-doctor` / `deepinit` may not recognize them | Medium (OMC ships frequently, v4.13.0 changed release skill) | Medium (drift erodes Constraint 3: OMC-native) | **Concrete audit (L10 fix):** on every OMC minor bump, run `diff ~/robot/.claude/agents/isaac-operator.md <(omc skill-creator print-template agent)` (or equivalent template dump) to detect key drift. Log result in `omc_robot_profile.md` §Version Audit Log with OMC version + diff summary. Never fork OMC (spec L34). Never introduce new frontmatter fields. | Planner, Phase A-1 + D-3 + on-bump |
| R5 | `docker compose` dual-path `container_name` collision recurs if Phase B-3 runs from symlinked `~/robot/datafactory/` instead of `~/Desktop/Project/DATAFACTORY/` | Medium (observed, setup-guide §13h) | High (fails Phase 1 smoke → fails AC-3) | Before Phase B-3, run `docker compose ls \| jq 'length'` and assert `== 1`. If `>1`, stop and delegate to `docker-operator` cleanup. Never run `docker compose up` via the symlink path. | Planner, Phase B-3 |
| R6 | `scratch-lab` bootstrap smoke pollutes parent `AGENTS.md` with a stale Children entry that is hard to remove | Low | Low | **Fenced markers (M8 fix):** bootstrap-child.sh emits `<!-- BOOTSTRAP_BEGIN:scratch-lab -->` / `<!-- BOOTSTRAP_END:scratch-lab -->` around appended Children entries. Cleanup: `sed -i '/<!-- BOOTSTRAP_BEGIN:scratch-lab -->/,/<!-- BOOTSTRAP_END:scratch-lab -->/d' ~/robot/AGENTS.md` + `rm -rf ~/robot/scratch-lab`. All within planner atomic commit. | Planner, Phase C-1 |
| R7 | Token measurement unit ambiguity (bytes vs tiktoken) | Medium | Low | AC-1 unit = bytes of `additionalContext` (authoritative). `tiktoken`-derived tokens are optional secondary evidence. AC-2 uses session-JSONL token count per Agent call (authoritative). Methodology documented in §Token Methodology. | Planner, Phase D-1 + D-2 |
| R8 | **Symlink MCP path resolution (NEW, H5 fix)** — `datafactory` is a symlink to `~/Desktop/Project/DATAFACTORY`; if `datafactory/.mcp.json` uses relative `../isaac-sim-mcp`, it resolves against the **symlink target's** parent (`~/Desktop/Project/isaac-sim-mcp`), not `~/robot/isaac-sim-mcp`. Servants spawned from symlink-cwd may pick up a different MCP binary than planner expects. | Medium (already observed for Docker, per setup-guide §13h) | High (silent tool divergence → AC-3 false-pass) | Pre-Phase-B assertion (A-0 step 8): `test -e "$(cd ~/robot/datafactory && cd .. && pwd)/isaac-sim-mcp" \|\| echo WARNING`. Mitigation: document in `wiki/mcp_lessons.md` that `.mcp.json` paths in symlinked children must be **absolute** (or explicitly relative-from-symlink-target). Extend setup-guide §13h (Docker-only today) with an MCP note. Never mix cwd between symlink and real path within a single Agent invocation. | Planner, Phase A-0 step 8 + Phase B-1 |

---

## 5. Verification Steps (per AC)

Every step below is a concrete command or check the planner runs. Servant agents never run verification commands that would require persistence tools.

### AC-1 — Token budget (FIXED per B4)
```bash
cd ~/robot/datafactory
extract_bytes() {
  bash -c "$(jq -r '.hooks.SessionStart[0].hooks[0].command' .claude/settings.local.json)" \
    | jq -r '.hookSpecificOutput.additionalContext' \
    | wc -c
}
# pre-distillation (from git stash or ancestor commit)
PRE=$(extract_bytes)
# post-distillation (after Phase A-C commits land)
POST=$(extract_bytes)
echo "additionalContext_pre=$PRE post=$POST delta=$((PRE-POST))"
```
Recorded in `wiki/omc_robot_profile.md` §Token Budget. Pass/fail gate lives in AC-3 (functional regression = fail). AC-1 alone is directional.

### AC-2 — Absolute token ceiling per servant call (Option Beta)
- Run N≥5 canonical probes (D-2) per servant.
- Extract token count per call from session JSONL (or hook log line, whichever this Claude Code version emits); document extractor command in §Token Methodology.
- Compute `mean ± 95% CI`.
- Assert `mean ≤ 8_000` per servant type; if not, raise ceiling with in-table justification and log reason.

### AC-3 — Phase 1 smoke reproducibility
From planner:
```
Spawn isaac-operator: "run get_scene_info() then a 10-line execute_script that prints isaacsim.__version__"
Spawn ros2-operator: "run connect_to_robot then get_topics"
```
Expected: `## Result` JSON has `"status":"success"`; `isaacsim` version == `4.5.0`; topic list non-empty. Record in `wiki/mcp_lessons.md`.

### AC-4 — Profile contract complete
```bash
grep -c '^## ' /home/codelab/robot/wiki/omc_robot_profile.md   # expect >= 10
awk '/^## /{h=$0; getline n; if(n~/TBD/) print h}' \
  /home/codelab/robot/wiki/omc_robot_profile.md   # expect 0 lines at end of Phase D
```

### AC-5 — Scope-violation tests (AM-4: discipline-based Case B)
Planner manually invokes Cases A / B / C (see §3 Phase B-2).
- **Case A, C**: `PASS` = servant 명시적 거부 + 거부 텍스트 기록.
- **Case B**: `PASS` = 세션 transcript audit에서 planner의 직접 `mcp__isaac-sim__*` / `mcp__ros-mcp__*` 호출 건수 `== 0`. ≥1건이면 `FAIL` + §Discipline Violations 로그 + revisit trigger counter +1 (2회 누적 시 방식 Y tmux migration 개시).

### AC-6 — Portability smoke
```bash
~/robot/scripts/bootstrap-child.sh scratch-lab --dry-run
~/robot/scripts/bootstrap-child.sh scratch-lab
test -f ~/robot/scratch-lab/.claude/settings.json
test -f ~/robot/scratch-lab/.mcp.json
test -f ~/robot/scratch-lab/wiki/INDEX.md
grep -q '<!-- BOOTSTRAP_BEGIN:scratch-lab -->' ~/robot/AGENTS.md
grep -q 'scratch-lab/' ~/robot/AGENTS.md
# cleanup (fence-aware)
sed -i '/<!-- BOOTSTRAP_BEGIN:scratch-lab -->/,/<!-- BOOTSTRAP_END:scratch-lab -->/d' ~/robot/AGENTS.md
rm -rf ~/robot/scratch-lab
```

### AC-7 — NotebookLM CLI capture
```bash
grep -c '7cf81435-cc9d-419e-8dfa-fe88c02dfa42' ~/robot/wiki/omc_robot_profile.md   # expect >=1
grep -E 'python3 -m notebooklm (status|use|ask|source add --url|source add-research)' \
  ~/robot/wiki/omc_robot_profile.md | wc -l   # expect >=5
```

### AC-8 — Alternatives audit
```bash
grep -c '^|' ~/robot/wiki/omc_robot_profile.md   # table rows present
```
Plus:
- Spawn `document-specialist` to fetch NVIDIA forum MCP tutorial; record diff in §Alternatives Audit.
- `mcp__plugin_context7_context7__resolve-library-id` invoked for `isaac-sim` and `ros2`; top IDs appended.

**Final integration check.** Run `superpowers:verification-before-completion` before the Phase D final commit. Do not claim done until all verification blocks emit the expected markers.

---

## 6. RALPLAN-DR Short Summary (consensus mode)

### Mode
SHORT (default). Not DELIBERATE. Phase 1 smoke already passed upstream; A-0 probe makes schema risk explicit and testable. If A-0 returns Branch C (neither schema enforces), promote to DELIBERATE for pre-mortem on alternative isolation mechanisms (tmux-only via `omc-teams`).

### Principles (4)
1. **OMC-native, zero fork.** Agent definitions use `skill-creator` templates. No new slash commands, no upstream patches.
2. **Drift minimization over feature maximalism.** Prefer directory isolation + inline `mcpServers` (or cwd-scoped `.mcp.json`, per A-0) over runtime toggles. Servant count stays ≤ 3.
3. **Token efficiency as a first-class metric.** AC-1 / AC-2 are numeric with absolute targets.
4. **Planner owns persistence; servants are stateless.** Return value (hardened JSON contract) is the only back-channel (Critical-3).

### Decision Drivers (top 3)
1. **Anthropic #16177/#4476/#32514 unresolved.** Forces directory isolation + inline `mcpServers` workaround to be the spine, not an afterthought.
2. **Brownfield = Phase 1 smoke already PASSED.** AC-3 guards against regression; any structure that can't re-pass is DOA.
3. **Single-child reality (datafactory).** N-children time optimization is a non-goal (spec L38). Portability is a one-script invariant (`bootstrap-child.sh`), not a product.

### Viable Options per key decision

#### Key decision 1 — Role-boundary enforcement mechanism

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **A. Agent-definition frontmatter scope (this plan, A-0 picks α or β)** | Enforced at Claude Code runtime; zero per-call overhead; matches `skill-creator` conventions; survives session restarts | Denylists are implicit (anything not listed is blocked); maintenance if OMC adds new default tools | **CHOSEN** |
| B. Inline `mcpServers` per Agent call | Finest-grained; isolates process per call | Reinjection cost at every call → token penalty; prompt-bloat; drifts from agent definitions | Rejected (violates Principle 3) |
| C. `/oh-my-claudecode:omc-teams` tmux-only isolation | True process isolation; proven in tmux teammate mode | Heavy runtime; tmux state management; overkill for single-domain call | **Kept as A-0 Branch C fallback** and for long-running Phase 2+ Replicator runs, not default |

#### Key decision 2 — `/robot:*` custom skill set scope

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **A. `promote`-only (no new `/robot:*` skills in this plan)** | Highest leverage per setup-guide §10; `promote.sh` already exists | Defers `isaac-api-guard`, `ros2-bridge-verify`, `robot-mcp-wire` | **CHOSEN for this plan**; mark other 3 as "evaluate post Phase 2–4" |
| B. `promote` + `isaac-api-guard` | Adds Isaac 4.5 API drift guard at planner-tier | `isaac-api-guard` scope not yet clear; premature | Deferred |
| C. Full 4-skill suite (`promote` + 3 more) | Symmetric coverage | **Steelmanned rejection (L11):** each of the 3 deferred skills would add value individually — `isaac-api-guard` encodes the Isaac 4.5 API drift rules already in `wiki/isaac_sim_api_patterns.md`; `ros2-bridge-verify` encodes the rosbridge-9090 connectivity checklist; `robot-mcp-wire` encodes the MCP extension-activation rules in `wiki/mcp_lessons.md`. Deferred because (a) existing wiki lessons are human-readable and already consulted by planner, (b) Phase 1 smoke is manual but works, (c) skill-creator velocity allows authoring when pain reappears. **Revisit trigger:** same failure class caught by human review twice within 2 phases → escalate to skill. | Rejected with explicit revisit trigger |

Both decisions retain ≥ 2 viable options → no invalidation note needed.

### ADR (authored now per H6, not deferred)

- **Decision.** Enforce planner/servant role boundary via agent-definition frontmatter scope (`allowedTools` or `tools:`, determined empirically by A-0) + directory-scoped `.mcp.json`. Planner owns all persistence; servants report via hardened `## Result` JSON + `## Evidence` free text only.
- **Drivers.**
  1. Anthropic #16177/#4476/#32514 unresolved — must design around, not assume a fix.
  2. Phase 1 smoke must replay under new wiring (AC-3 hard gate).
  3. Single-child portability via `bootstrap-child.sh` — one-script invariant.
- **Alternatives considered.**
  1. Inline per-call `mcpServers` — rejected for token/drift cost.
  2. tmux-only isolation via `omc-teams` — **kept as A-0 Branch C fallback + long-running workload path**, not default.
  3. Custom `/robot:*` 4-skill suite up-front — rejected with explicit revisit trigger (KD2 Option C).
  4. Runtime MCP toggle (`/robot:mcp-on/off` slash command) — rejected by spec Non-Goal.
- **Why chosen.** Frontmatter-scope matches OMC-native constraints, survives session restarts, leaves Anthropic's eventual fix as an in-place upgrade path, and A-0 makes the enforcement mechanism empirically verified rather than assumed.
- **Consequences.**
  - (a) **[PROVISIONAL until D-3 measurement]** Token budget improves to `< 5k chars additionalContext` and servant-call mean `≤ 8k tokens`. Confirmed/revised at D-3.
  - (b) Servant definitions become a maintained contract → audited on each OMC minor bump (R4 concrete audit command logged to §Version Audit Log).
  - (c) NotebookLM CLI calls concentrate in planner; re-auth is a single point.
  - (d) All commits stay atomic at planner tier → git log readability preserved.
  - (e) Symlink-cwd MCP path resolution becomes a documented risk (R8) — absolute paths in `.mcp.json` of symlinked children enforced via `wiki/mcp_lessons.md`.
- **Follow-ups.**
  - Post Phase 2–4: reassess `isaac-api-guard` / `ros2-bridge-verify` / `robot-mcp-wire` need (revisit trigger: 2 same-class failures in 2 phases).
  - Watch Anthropic #16177/#4476/#32514 weekly (`gh api` scan in R1 mitigation).
  - Re-run AC-1 / AC-2 after every OMC minor bump, log to §Version Audit Log.
  - Remove PROVISIONAL flag on Consequence (a) at D-3 with measured values.

---

## 7. Open Questions (emit to `/home/codelab/robot/datafactory/.omc/plans/open-questions.md`)

Resolved / closed by iteration 2:
- [x] ~~Planner-tier behavior when `mcp__isaac-sim__execute_script` is called directly (AC-5 Case B)~~ — **closed by B3 fix (Option X, block-via-scope, no warnings)**.
- [x] ~~Schema ambiguity around `allowedTools:` vs `tools:` frontmatter~~ — **deferred to empirical A-0 probe; outcome written to `wiki/mcp_lessons.md`**.

Still open (append to open-questions.md):
- [ ] Can `tiktoken` be installed in the planner env (uv run) to replace byte-count heuristic for AC-1 secondary evidence?
- [ ] Robosynx / Isaac Monitor licensing reality (spec L124) — parse required before any "trial" verdict.
- [ ] `lpigeon/ros-mcp-server` vs `robotmcp/ros-mcp-server` differentiation (spec L130) — investigate in Phase C-3.
- [ ] Anthropic #16177 / #4476 / #32514 roadmap signal — weekly `gh api` scan per R1.
- [ ] Priority ordering of deferred `/robot:*` skills — revisit trigger: 2 same-class failures in 2 phases.
- [ ] `docker-operator` promotion from "optional" to "standard" — decide after first Phase 2 Replicator run.

---

## Plan Summary (for confirmation)

**Plan saved to:** `/home/codelab/robot/datafactory/.omc/plans/robot-omc-role-scoped-distillation-plan.md` (iteration 2)

**Scope:**
- 4 phases (A with new A-0, B, C, D) × 1 atomic commit each → **4–5 planner-tier commits** (A-0 outcome may fold into Phase A commit).
- 8 ACs (AC-1 through AC-8) each with numeric or file-level verification; AC-2 now absolute-target, AC-5 now block-via-scope.
- Estimated complexity: MEDIUM (brownfield, no new MCPs, agent definitions + one profile doc, one empirical probe).

**Key deliverables:**
1. A-0 empirical schema probe outcome recorded in `wiki/mcp_lessons.md` (promotion-worthy).
2. `~/robot/.claude/agents/{isaac-operator,ros2-operator,docker-operator}.md` (3 agent definitions, schema branch per A-0).
3. `~/robot/wiki/omc_robot_profile.md` (10-section profile; AC-4 artifact) with `## Token Methodology` + `## Version Audit Log` + `## Scope schema branch record`.
4. `wiki/mcp_lessons.md` post-distillation smoke append (AC-3 evidence) + symlink MCP path note (R8).
5. Phase 1 smoke re-run PASS + scope-violation PASS under new wiring (AC-3, AC-5).
6. `scratch-lab` portability smoke with fenced AGENTS.md markers + cleanup (AC-6).
7. Alternatives Audit table + NotebookLM block (AC-7, AC-8).
8. ADR in §6 authored now with PROVISIONAL flag on Consequences-(a) until D-3.

**Does this plan capture your intent?**
- "proceed" — Phase A begins via `/oh-my-claudecode:start-work robot-omc-role-scoped-distillation-plan`
- "adjust [X]" — return to interview to modify section X
- "restart" — discard and re-interview
