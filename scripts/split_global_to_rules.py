#!/usr/bin/env python3
"""Split a GLOBAL.md-style file into per-section Cursor Project Rules.

Follows the procedure in `.claude/skills/sync-agent-context/SKILL.md` under
"Cursor global rule as project rule":

- Parse sections at each single-`#` heading (not `##`).
- Slug the heading (lowercase, non-alphanumerics -> `-`).
- Write `<target>/.cursor/rules/global/<slug>.mdc` with:
    ---
    description: "<short summary>"
    alwaysApply: true
    ---
    <verbatim section body, heading included>

Idempotence:
- Replace files whose section content changed.
- Skip files that already match.
- Delete files under `.cursor/rules/global/` whose owning section no longer exists.

Sections whose heading matches `--skip-heading` (repeatable) are excluded and reported.
Default skip: `Context` (skill preamble in GLOBAL.md, not runtime guidance).

Usage:
    split_global_to_rules.py --source <GLOBAL.md> --target <repo-root>
        [--skip-heading <name>]... [--dry-run]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


HEADING_RE = re.compile(r"^# (?!#)(.+?)\s*$")

DEFAULT_SKIP_HEADINGS: tuple[str, ...] = ("Context",)


def slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")


def parse_sections(md: str) -> list[tuple[str, str]]:
    """Return list of (heading_text, section_body_including_heading)."""
    lines = md.splitlines(keepends=True)
    sections: list[tuple[str, list[str]]] = []
    current: list[str] | None = None
    current_heading: str | None = None
    for line in lines:
        m = HEADING_RE.match(line.rstrip("\n"))
        if m:
            if current is not None and current_heading is not None:
                sections.append((current_heading, current))
            current_heading = m.group(1).strip()
            current = [line]
        else:
            if current is not None:
                current.append(line)
    if current is not None and current_heading is not None:
        sections.append((current_heading, current))
    return [(h, "".join(body)) for h, body in sections]


def first_meaningful_line(body: str, heading: str) -> str:
    """Pick a short description from the section body.

    Strategy: first non-empty, non-heading line, trimmed to ~120 chars.
    Falls back to the heading itself if nothing usable.
    """
    for raw in body.splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith("#"):
            continue
        if line.startswith("- "):
            line = line[2:].strip()
        if len(line) > 120:
            line = line[:117].rstrip() + "..."
        return line
    return heading


def frontmatter(description: str) -> str:
    safe = description.replace('"', '\\"')
    return (
        "---\n"
        f'description: "{safe}"\n'
        "alwaysApply: true\n"
        "---\n\n"
    )


def render(section_body: str, description: str) -> str:
    return frontmatter(description) + section_body


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--source", required=True, help="Path to canonical GLOBAL.md")
    p.add_argument(
        "--target",
        required=True,
        help="Repo root that will receive .cursor/rules/global/",
    )
    p.add_argument(
        "--skip-heading",
        action="append",
        default=None,
        help=(
            "Heading text to skip (repeatable). "
            f"Defaults to: {', '.join(DEFAULT_SKIP_HEADINGS)}. "
            "Pass at least one --skip-heading to override the default entirely."
        ),
    )
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    skip_headings = tuple(args.skip_heading) if args.skip_heading is not None else DEFAULT_SKIP_HEADINGS
    skip_set = {h.strip().lower() for h in skip_headings}

    src = Path(args.source).expanduser().resolve()
    tgt_root = Path(args.target).expanduser().resolve()
    rules_dir = tgt_root / ".cursor" / "rules" / "global"

    if not src.is_file():
        print(f"ERROR: source not found: {src}", file=sys.stderr)
        return 2

    md = src.read_text(encoding="utf-8")
    sections = parse_sections(md)
    if not sections:
        print(f"ERROR: no top-level `#` sections found in {src}", file=sys.stderr)
        return 3

    expected_files: set[Path] = set()
    planned: list[tuple[str, str, str]] = []
    slug_owner: dict[str, str] = {}
    errors: list[str] = []
    for heading, body in sections:
        if heading.strip().lower() in skip_set:
            print(f"SKIP  heading '{heading}' (matched --skip-heading)")
            continue
        slug = slugify(heading)
        if not slug:
            errors.append(
                f"heading '{heading}' produces an empty slug after stripping non-alphanumerics"
            )
            continue
        if slug in slug_owner:
            errors.append(
                f"slug '{slug}' collides between headings '{slug_owner[slug]}' and '{heading}'"
            )
            continue
        slug_owner[slug] = heading
        planned.append((heading, body, slug))

    if errors:
        print("ERROR: split_global_to_rules aborted before writing any files:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        print(
            "Rename or restructure the offending headings in GLOBAL.md and re-run.",
            file=sys.stderr,
        )
        return 4

    for heading, body, slug in planned:
        desc = first_meaningful_line(body, heading)
        content = render(body, desc)
        out = rules_dir / f"{slug}.mdc"
        expected_files.add(out)

        if out.exists() and out.read_text(encoding="utf-8") == content:
            print(f"SKIP  current {out}")
            continue

        action = "REPLACE" if out.exists() else "CREATE"
        if args.dry_run:
            print(f"DRY-RUN {action} {out}")
        else:
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(content, encoding="utf-8")
            print(f"{action} {out}")

    if rules_dir.exists():
        for existing in sorted(rules_dir.glob("*.mdc")):
            if existing not in expected_files:
                if args.dry_run:
                    print(f"DRY-RUN DELETE {existing}")
                else:
                    existing.unlink()
                    print(f"DELETE {existing}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
