# Open Questions — robot datafactory

Tracked across plans/sessions. Append-only; check off when resolved.

## Generic research items (carry-over from abandoned role-scoped distillation plan)

The role-scoped distillation plan (commit `458de9b`, abandoned 2026-04-21 in favor of `omc-teams` pivot) surfaced the following **domain-research** questions. They are independent of the abandoned implementation approach and remain worth tracking.

- [ ] Robosynx / Isaac Monitor licensing + architecture — confirm license model + intended use before any "adopt / trial" decision on these as Isaac alternatives.
- [ ] `lpigeon/ros-mcp-server` vs `robotmcp/ros-mcp-server` differentiation — investigate: which is upstream, which is maintained, which supports ROS 2 Humble + rosbridge 9090 better.
- [ ] Anthropic Claude Code issues **#16177, #4476, #32514** roadmap signal — these track the MCP scope / isolation primitives. Periodic scan (`gh api repos/anthropics/claude-code/issues/16177 --jq '.state'`) useful for any future role-scoped work.
