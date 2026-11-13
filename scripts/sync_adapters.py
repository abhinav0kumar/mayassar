#!/usr/bin/env python3
"""Generate every non-Claude tool's copy of mayassar from skills/mayassar/SKILL.md.

    python3 scripts/sync_adapters.py          # write the files
    python3 scripts/sync_adapters.py --check  # exit 1 if any file is out of date

SKILL.md is the only file to edit by hand. Tools that can read the skills/ folder
through a plugin manifest get a manifest; tools that only read rules or commands
get a copy of the instructions with their own header.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL = ROOT / "skills" / "mayassar" / "SKILL.md"
PLUGIN = json.loads((ROOT / ".claude-plugin" / "plugin.json").read_text())

DESCRIPTION = PLUGIN["description"]
ON_DEMAND = (
    "Only follow these instructions when the user asks for mayassar "
    "(jaam-naam, nav-aam or nav-khaas). Otherwise ignore this file.\n\n"
)


def skill_body() -> str:
    text = SKILL.read_text()
    # drop the YAML frontmatter: everything up to the second '---' line
    _, _, rest = text.split("---\n", 2)
    return rest.lstrip()


def manifest(**extra) -> str:
    data = {"name": PLUGIN["name"], "version": PLUGIN["version"], "description": DESCRIPTION}
    data.update(extra)
    return json.dumps(data, indent=2) + "\n"


def outputs() -> dict:
    body = skill_body()
    rule = ON_DEMAND + body
    return {
        # plugin manifests that load skills/ directly
        ".codex-plugin/plugin.json": manifest(skills="./skills/"),
        ".qoder-plugin/plugin.json": manifest(skills="./skills/"),
        ".devin-plugin/plugin.json": manifest(skills="./skills/"),
        ".github/plugin/plugin.json": manifest(skills="./skills/"),
        # Gemini CLI extension + command
        "gemini-extension.json": manifest(),
        "commands/mayassar.toml": (
            f'description = "{DESCRIPTION}"\n'
            f'prompt = """\nArguments: {{{{args}}}}\n\n{body}"""\n'
        ),
        # OpenCode command
        ".opencode/command/mayassar.md": (
            f"---\ndescription: {DESCRIPTION}\n---\n\nArguments: $ARGUMENTS\n\n{body}"
        ),
        # OpenClaw skill (same format as Claude's)
        ".openclaw/skills/mayassar/SKILL.md": SKILL.read_text(),
        # rules files, copied into a project; on-demand where the tool allows it
        ".cursor/rules/mayassar.mdc": (
            f"---\ndescription: {DESCRIPTION} Use when the user asks for mayassar.\n"
            f"globs:\nalwaysApply: false\n---\n\n{rule}"
        ),
        ".windsurf/rules/mayassar.md": (
            f"---\ntrigger: model_decision\ndescription: {DESCRIPTION}\n---\n\n{rule}"
        ),
        ".kiro/steering/mayassar.md": f"---\ninclusion: manual\n---\n\n{rule}",
        ".clinerules/mayassar.md": rule,
        # pi and other tools that read AGENTS.md
        "AGENTS.md": rule,
    }


def main() -> int:
    check = "--check" in sys.argv
    stale = []
    for rel, content in outputs().items():
        path = ROOT / rel
        if path.exists() and path.read_text() == content:
            continue
        if check:
            stale.append(rel)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
            print(f"wrote {rel}")
    if stale:
        print("out of date, run scripts/sync_adapters.py:\n  " + "\n  ".join(stale))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
