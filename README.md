# mayasaar

AI coding assistants over-build. mayasaar cuts their work back to the smallest,
plainest change that does what the task asked for, and shows what it cut and why.

## Modes

| Command | What it does |
|---|---|
| `/mayasaar jaam-naam` (or just `/mayasaar`) | Takes what the AI did on this branch and redoes it as the smallest readable change, then explains each cut. |
| `/mayasaar nav-aam <task>` | Writes new code the simple way, and tidies only the code it touches. |
| `/mayasaar nav-khaas` | Restructures the whole codebase so it's easy to find your way around, and cleans up the branch's AI change if there is one. Only when you ask. |

Results always go on a new `mayasaar/...` branch. Your branch is never touched.

## Rules it follows

- Readable beats short. No clever one-liners.
- Keep only what the task asked for. Every removal is listed with a reason.
- Tests run before and after. If they already fail, it stops.
- Uncommitted changes? It stops and never stashes or discards them.

## Install (Claude Code)

```
/plugin marketplace add abhinav0kumar/mayasaar
/plugin install mayasaar@mayasaar
```

From a local clone: `claude --plugin-dir /path/to/mayasaar`.

## Other tools

`skills/mayasaar/SKILL.md` is the single source. `python3 scripts/sync_adapters.py`
generates each tool's copy; `--check` fails if any is out of date.

| Tool | How |
|---|---|
| Codex, Qoder, Devin, GitHub Copilot | plugin manifests in `.codex-plugin/`, `.qoder-plugin/`, `.devin-plugin/`, `.github/plugin/`, loading `skills/` |
| Gemini CLI | extension `gemini-extension.json`, command `/mayasaar` in `commands/mayasaar.toml` |
| OpenCode | command `.opencode/command/mayasaar.md` |
| OpenClaw | skill `.openclaw/skills/mayasaar/` |
| Cursor, Windsurf, Kiro, Cline | copy `.cursor/rules/mayasaar.mdc`, `.windsurf/rules/mayasaar.md`, `.kiro/steering/mayasaar.md` or `.clinerules/mayasaar.md` into your project |
| pi and anything that reads `AGENTS.md` | `AGENTS.md` |

Only Claude Code is covered by the automated evals. The other tools haven't been
tried by hand yet.

## Results so far

Same bloated AI branch for everyone (a class, an unrequested setting, logging and a
30-line README section around a one-line task). Judge: Sonnet.

- **Neutral checks** (any tool can pass): bloat removed, unrelated code left alone,
  tests run first, plain readable code.
- **All checks** adds mayasaar's own promises: result on a new branch, cuts and
  rewritten tests explained, size compared, PR description. Competitors don't
  attempt these, so that column shows what mayasaar adds, not a fair contest.

| Contender | Neutral checks | All checks | Runs |
|---|---|---|---|
| **mayasaar** | **1.00** | **1.00** | 2 |
| code-simplifier (Anthropic plugin) | 1.00 | 0.63 | 1 |
| `/simplify` (built into Claude Code) | 0.63 | 0.44 | 2 |
| plain Claude | 0.63 | 0.38 | 2 |

Honest read: code-simplifier matched mayasaar on the neutral checks in its one
Sonnet-judged run (in an earlier run it kept the bloat). More runs are needed
before claiming mayasaar simplifies better; today its clear edge is the safety net
and the explanation: new branch, explained cuts, size comparison, PR text.
(Scores predate two checks added after review: rewritten tests named, original
branch untouched.)

Other mayasaar checks (Haiku judge, 2 runs, all 1.00): nav-aam builds test-first
with no extras; nav-khaas tidies the wider repo; stops when tests already fail;
stops on uncommitted changes without stashing them.

Run the evals: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Edit Write`.
Competitor run: `evals/compete.sh <plugin-dir>`. The evals currently assume macOS
(they point git at the Command Line Tools binary, because the eval sandbox blocks
`/usr/bin/git`).
