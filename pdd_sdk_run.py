"""pdd_sdk_run.py - headless GSD steps for the PeCAN Data Dictionary, billed to API credits.

Runs one step (a GSD slash command or a plain instruction) through the Claude Agent SDK,
which API promotional credits cover. Interactive Claude Code does not use those credits.

Usage (PowerShell, repo root C:\\data_dictionary, branch other than main/master):
    $env:ANTHROPIC_API_KEY = "sk-ant-..."
    python pdd_sdk_run.py sdk_test "Reply with the single word OK" --max-turns 1
    python pdd_sdk_run.py M_new "/gsd:new-milestone" --prompt-file .planning/prompts/new_milestone_headless.md
    python pdd_sdk_run.py plan_M1 "/gsd:plan-phase 12"
    python pdd_sdk_run.py ledger            # show spend so far

Safety:
  - refuses to run on main/master or with uncommitted changes
  - per-step hard budget (--step-budget, SDK max_budget_usd) and a total cap across steps
    (--cap, read from logs/api_runs/ledger.csv)
  - every step's messages and final result are logged as JSON lines in logs/api_runs/
"""

from __future__ import annotations

import argparse
import asyncio
import csv
import datetime as dt
import json
import os
import pathlib
import subprocess
import sys

from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ResultMessage,
    TextBlock,
    ToolUseBlock,
    query,
)

REPO = pathlib.Path(__file__).resolve().parent
LOG_DIR = REPO / "logs" / "api_runs"
LEDGER = LOG_DIR / "ledger.csv"

RULES = """HEADLESS RUN RULES (PeCAN Data Dictionary, milestone PCNR_ 2018-2025 / PECAN_ID / master xlsx):
- You are running non-interactively. Never ask questions or wait for answers. Take the documented
  default and record every assumption in the phase CONTEXT/SUMMARY under 'Assumptions (headless run)'.
- This Windows machine has NO P: drive and NO SAS. Never try to read P:\\, run SAS, or touch real data.
- Probe-first: facts about source files come only from .planning/schemas/probe_*.md. Never guess
  column names, file names, row counts, ID formats or encodings. If a fact is missing, write a
  PROBE REQUEST in the plan, mark it 'PENDING SAS RUN' in STATE.md, and continue with independent plans.
- At any step needing a SAS run: write the exact program(s) to run and the log/qc files to bring back,
  mark 'PENDING SAS RUN', continue with plans that do not depend on it.
- At decision gates (new PDD-D decisions, Price sign-off, near-match names): lay out options with
  probe evidence, mark 'PENDING DECISION', do not apply a choice. Locked PDD-D-01..23 stay closed.
- PECAN_ID is a rename of PCNR_ID (same values, no PCNR_ prefix). Values in the PCNR_ layer stay
  exactly as in source.
- Never write to the shared Master Data folder. Outputs go only to P:\\PeCAN Master Data\\Gerard\\data_dictionary
  via sas\\00_config.sas paths. No data in git. KEY sheet leftmost in every workbook.
- Follow the SAS pitfalls list in CLAUDE.md for every program you write.
- Commit to the current branch with clear messages. NEVER git push, never switch branches,
  never rewrite history.
- Run every subagent (Agent/Task tool) in the FOREGROUND (run_in_background: false) and wait
  for its result before ending your turn. Never end the step while a subagent is still running.
"""


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=REPO, capture_output=True, text=True, check=True).stdout.strip()


def ledger_total() -> float:
    if not LEDGER.exists():
        return 0.0
    with LEDGER.open(newline="", encoding="utf-8") as f:
        return sum(float(r["cost_usd"] or 0) for r in csv.DictReader(f))


def ledger_add(name: str, result: ResultMessage | None, log: pathlib.Path) -> None:
    new = not LEDGER.exists()
    with LEDGER.open("a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if new:
            w.writerow(["time", "step", "cost_usd", "turns", "is_error", "subtype", "log"])
        w.writerow([
            dt.datetime.now().isoformat(timespec="seconds"),
            name,
            f"{(result.total_cost_usd or 0) if result else 0:.4f}",
            result.num_turns if result else "",
            result.is_error if result else "no result",
            result.subtype if result else "",
            log.name,
        ])


def preflight(cap: float, allow_dirty: bool) -> None:
    if not os.environ.get("ANTHROPIC_API_KEY"):
        sys.exit("Set $env:ANTHROPIC_API_KEY first (key from the Console org that holds the credits).")
    branch = git("rev-parse", "--abbrev-ref", "HEAD")
    if branch in ("main", "master"):
        sys.exit(f"On '{branch}'. Create a work branch first, e.g.  git switch -c pdd-2018-2025-api")
    if not allow_dirty and git("status", "--porcelain", "--", ".", ":(exclude)logs", ":(exclude)__pycache__"):
        sys.exit("Uncommitted changes. Commit or stash them first (or pass --allow-dirty).")
    spent = ledger_total()
    if spent >= cap:
        sys.exit(f"Logged spend ${spent:.2f} has reached the cap ${cap:.2f}. Raise --cap to continue.")
    print(f"branch={branch}  logged spend so far=${spent:.2f}  cap=${cap:.2f}")


async def run(name: str, prompt: str, max_turns: int, step_budget: float, model: str | None) -> int:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    stamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    log = LOG_DIR / f"{name}_{stamp}.jsonl"
    options = ClaudeAgentOptions(
        cwd=str(REPO),
        permission_mode="bypassPermissions",
        max_turns=max_turns,
        max_budget_usd=step_budget,
        system_prompt={"type": "preset", "preset": "claude_code", "append": RULES},
        setting_sources=["user", "project", "local"],  # loads CLAUDE.md and the GSD commands
        model=model,
        # Headless runs otherwise stop background subagents 10 minutes after the last turn.
        env={"CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS": "0"},
    )
    result: ResultMessage | None = None
    print(f"=== {name} started {dt.datetime.now():%H:%M} (step budget ${step_budget:.2f}) ===")
    with log.open("w", encoding="utf-8") as out:
        try:
            async for msg in query(prompt=prompt, options=options):
                if isinstance(msg, AssistantMessage):
                    for block in msg.content:
                        if isinstance(block, ToolUseBlock):
                            detail = json.dumps(block.input)[:140]
                            print(f"  [tool] {block.name} {detail}")
                            out.write(json.dumps({"tool": block.name, "input": block.input}, default=str) + "\n")
                        elif isinstance(block, TextBlock):
                            out.write(json.dumps({"text": block.text}) + "\n")
                elif isinstance(msg, ResultMessage):
                    result = msg
                    out.write(json.dumps({
                        "result": msg.result, "is_error": msg.is_error, "subtype": msg.subtype,
                        "turns": msg.num_turns, "cost_usd": msg.total_cost_usd,
                        "session_id": msg.session_id,
                    }, default=str) + "\n")
        except Exception as exc:  # keep the ledger honest even if the run dies
            out.write(json.dumps({"exception": repr(exc)}) + "\n")
            print(f"{name}: run failed: {exc!r}")
    ledger_add(name, result, log)
    if result is None:
        print(f"{name}: no result message; see {log}")
        return 1
    print(f"{name}: is_error={result.is_error} subtype={result.subtype} turns={result.num_turns} "
          f"cost=${(result.total_cost_usd or 0):.2f}  total logged=${ledger_total():.2f}")
    print(result.result or "")
    return 1 if result.is_error else 0


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("name", help="step name for logs, or 'ledger' to show spend")
    ap.add_argument("prompt", nargs="?", help="prompt or slash command")
    ap.add_argument("--prompt-file", help="file whose text is appended to the prompt (or used alone)")
    ap.add_argument("--max-turns", type=int, default=250)
    ap.add_argument("--step-budget", type=float, default=25.0, help="hard USD limit for this step")
    ap.add_argument("--cap", type=float, default=150.0, help="refuse new steps once logged spend reaches this")
    ap.add_argument("--model", default=None, help="e.g. claude-sonnet-5-5 to save credits; default = account default")
    ap.add_argument("--allow-dirty", action="store_true")
    a = ap.parse_args()

    if a.name == "ledger":
        print(f"logged spend: ${ledger_total():.2f}")
        if LEDGER.exists():
            print(LEDGER.read_text(encoding="utf-8"))
        return

    parts = [p for p in [a.prompt] if p]
    if a.prompt_file:
        parts.append(pathlib.Path(a.prompt_file).read_text(encoding="utf-8-sig"))
    if not parts:
        sys.exit("Give a PROMPT and/or --prompt-file.")
    prompt = "\n\n".join(parts)

    preflight(a.cap, a.allow_dirty)
    remaining = a.cap - ledger_total()
    sys.exit(asyncio.run(run(a.name, prompt, a.max_turns, min(a.step_budget, remaining), a.model)))


if __name__ == "__main__":
    main()
