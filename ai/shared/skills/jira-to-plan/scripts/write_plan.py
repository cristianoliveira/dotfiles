#!/usr/bin/env python3
import argparse
import subprocess
from pathlib import Path

def extract_issue_key(url: str) -> str:
    result = subprocess.run(
        ["scripts/extract_issue_key.py", url],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())
    return result.stdout.strip()

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--jira-url", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument(
        "--template",
        default=str(Path(__file__).resolve().parent.parent / "templates" / "plan.md.tmpl"),
    )
    args = ap.parse_args()

    jira_url = args.jira_url.strip()
    issue_key = extract_issue_key(jira_url)
    issue_text = Path("/dev/stdin").read_text(encoding="utf-8", errors="replace")

    summary = issue_text.splitlines()[0][:120] if issue_text else "Unknown"

    rendered = Path(args.template).read_text(encoding="utf-8")
    rendered = rendered.replace("{{ISSUE_KEY}}", issue_key)
    rendered = rendered.replace("{{JIRA_URL}}", jira_url)
    rendered = rendered.replace("{{SUMMARY}}", summary)
    rendered = rendered.replace("{{PROBLEM_STATEMENT}}", "- (Derived from ticket)\n")
    rendered = rendered.replace("{{ACCEPTANCE_CRITERIA}}", "- (From ticket or clarified)\n")
    rendered = rendered.replace("{{CONSTRAINTS}}", "- (If any)\n")
    rendered = rendered.replace("{{QUESTIONS}}", "- (Asked before planning)\n")
    rendered = rendered.replace("{{ASSUMPTIONS}}", "- (Explicit assumptions)\n")
    rendered = rendered.replace("{{APPROACH}}", "- (High-level approach)\n")
    rendered = rendered.replace("{{COMMITS}}", "_(Filled by agent)_\n")
    rendered = rendered.replace("{{NON_GOALS}}", "- (Out of scope)\n")
    rendered = rendered.replace(
        "{{VALIDATION}}",
        "- Unit tests\n- Lint/format\n- Smoke test\n",
    )

    out = Path(args.out.replace("<ISSUE_KEY>", issue_key))
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(rendered, encoding="utf-8")
    print(out)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
