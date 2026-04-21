# Open Questions — robot datafactory plans

Tracked across plans. Append-only; check off when resolved.

## Robot OMC Role-Scoped Distillation - 2026-04-20

### Closed by iteration 2 (Architect + Critic revision)

- [x] ~~Planner-tier behavior when `mcp__isaac-sim__execute_script` is called directly (AC-5 Case B): "warn + allow" vs "block"~~ — **closed: Option X chosen (block-via-scope, no warning mechanism). AC-5 Case B now expects hard-block "unknown tool" error from the planner cwd's empty `.mcp.json`.**
- [x] ~~`.omc/logs/` pre-distillation baseline retention window for AC-2 30% reduction claim~~ — **closed by AC-2 rewrite to Option Beta (absolute target `≤ 8k tokens` per servant call, N≥5 probes, 95% CI). Pre-distillation baseline no longer load-bearing.**
- [x] ~~YAML frontmatter schema ambiguity (`allowedTools:` + inline `mcpServers:` vs documented `tools:` comma-string)~~ — **closed pending empirical resolution: Phase A-0 probe runs both candidate schemas, outcome recorded in `wiki/mcp_lessons.md`. Schema enforcement is now empirically verified rather than assumed.**

### Still open

- [ ] Can `tiktoken` be installed in the planner env (e.g. `uv run`) to replace the byte-count heuristic for AC-1 secondary evidence? — bytes is authoritative; tiktoken is optional.
- [ ] Robosynx / Isaac Monitor licensing + architecture (spec L124) — confirm before any "trial" verdict in AC-8 Alternatives Audit.
- [ ] `lpigeon/ros-mcp-server` vs `robotmcp/ros-mcp-server` differentiation (spec L130) — investigate in Phase C-3.
- [ ] Anthropic #16177 / #4476 / #32514 roadmap signal — **weekly** `gh api repos/anthropics/claude-code/issues/16177 --jq '.state'` scan per R1; re-evaluate within 1 week of any `closed` state.
- [ ] Priority ordering of the deferred `/robot:*` custom skills (`isaac-api-guard`, `ros2-bridge-verify`, `robot-mcp-wire`) — revisit trigger: same failure class caught by human review twice within 2 phases.
- [ ] Should `docker-operator` servant be promoted from "optional, default off" to standard given `docker compose` dual-path collision history (setup-guide §13(h))? — decide after first Phase 2 long-running Replicator run.
- [ ] **(NEW, R8)** Symlink-cwd MCP path resolution: does `datafactory/.mcp.json` currently use absolute or relative paths for `isaac-sim-mcp`? If relative, does it resolve via the symlink target (`~/Desktop/Project/`) or via `~/robot/`? — Phase A-0 step 8 assertion captures this; if warning fires, migrate to absolute paths and document in `wiki/mcp_lessons.md`.
