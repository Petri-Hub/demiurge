#!/usr/bin/env python3
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
agents = {p.stem for p in (ROOT / "agents").glob("*.md")}
skills = {p.name for p in (ROOT / "skills").iterdir() if (p / "SKILL.md").is_file()}
builtins = {"Explore", "Plan", "general-purpose", "claude-code-guide", "statusline-setup"}
problems = []


def frontmatter(path):
    text = path.read_text()
    match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not match:
        problems.append(f"{path.relative_to(ROOT)}: missing frontmatter")
        return {}
    fields = {}
    for line in match.group(1).splitlines():
        key = re.match(r"^([A-Za-z-]+):\s*(.*)$", line)
        if key:
            fields[key.group(1)] = key.group(2)
    return fields


for path in sorted(ROOT.rglob("*.md")):
    relative = path.relative_to(ROOT)
    if relative.parts[0] not in {"agents", "skills"}:
        continue
    text = path.read_text()
    for name in re.findall(r"~/\.claude/skills/([A-Za-z0-9-]+)", text):
        if name not in skills and not name.endswith("-"):
            problems.append(f"{relative}: unknown skill path {name}")
    for group in re.findall(r"Agent\(([^)]*)\)", text):
        for name in (n.strip() for n in group.split(",")):
            if name and name not in agents and name not in builtins and not re.search(r"[{}<>*.]|^Name\d*$", name):
                problems.append(f"{relative}: unknown agent {name} in Agent(...)")

for path in sorted((ROOT / "agents").glob("*.md")):
    fields = frontmatter(path)
    for field in ("name", "description", "model", "tools"):
        if field not in fields:
            problems.append(f"agents/{path.name}: frontmatter lacks {field}")
    if "mode" in fields:
        problems.append(f"agents/{path.name}: OpenCode-only field 'mode'")

for name in sorted(skills):
    fields = frontmatter(ROOT / "skills" / name / "SKILL.md")
    if fields.get("name") != name:
        problems.append(f"skills/{name}: frontmatter name is {fields.get('name')!r}")

print(f"{len(agents)} agents, {len(skills)} skills")
print("\n".join(problems) or "all references resolve")
sys.exit(1 if problems else 0)
