# AGENTS.private.md — skeleton (local only; gitignored; never commit)

Personal/infra details for this machine. Copy this to
`AGENTS.private.md` (in `~/.pi/agent/`) and fill in values. **No real
secrets — only names, locations, and how to reach things.**

## Access

### <Issue tracker, e.g. ClickUp> API
- Credentials: `<env file path>` — token var `CLICKUP_API_TOKEN`
- Base URL: `https://api.<tracker>.com/api/v2`
- When to use: during PR reviews — the ticket link on a PR carries the
  Definition of Done, expected vs. actual behavior, root-cause analysis,
  and priority that the PR body often omits.
  - `GET /task/{id}?include_assignments=true&include_checklists=true&...`
  - `GET /task/{id}/comment`

### Databases (read-only patterns)
- How you connect (port-forwarding, auth tokens, reader replicas),
  which schemas/databases are safe demos, naming conventions,
  key read recipes.
- Conventions: read-only; avoid dumping PII; introspect before guessing
  columns.

### Cloud / logs
- Log group names, dashboards, regions, and the exact query chains that
  work for common lookups.
- SSO profile names and where sessions live; re-login procedure.

## Standing instructions (this org / employer)

- Anything that must always hold in this context: review checklists,
  branch rules, review-flow expectations, DoD expectations.

## Notes

- Personal defaults (model, port, home dir conventions) that differ from
  the general layer.
