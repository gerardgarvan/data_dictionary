Start the next GSD milestone for this project non-interactively.

Use `.planning/MILESTONE_BRIEF_2018_2025.md` as the complete answer set for the new-milestone
questions. Do not ask anything.

1. Read PROJECT.md, ROADMAP.md, STATE.md, REQUIREMENTS.md, docs/DECISIONS.md and every
   `.planning/schemas/probe_*.md`.
2. Archive the current REQUIREMENTS.md per GSD conventions if the previous milestone is closed;
   if it is not closed, stop and report which phases are still open.
3. Write the new REQUIREMENTS.md from the brief (keep the requirement IDs PRB, RUN, NEW, MAP,
   PID, DD, XLS) and update PROJECT.md (current milestone, scope, out of scope).
4. Add the phases M1–M6 to ROADMAP.md, numbered continuing from the last existing phase, each
   with goal, depends-on, requirements and success criteria. M1 must finish (probe committed)
   before M2–M6 can be planned.
5. Register the open decisions new-1, new-2, new-3 in docs/DECISIONS.md at the next free PDD-D
   numbers with status OPEN and the defaults from the brief. Carry Price's naming sign-off.
6. Update STATE.md: current milestone, next step = "Gerard runs sas/probe_inputs.sas on the SAS
   machine and commits the probe (PENDING SAS RUN)".
7. Add the contents of `CLAUDE_md_addition.md` to CLAUDE.md (new sections, do not remove
   existing ones), then delete CLAUDE_md_addition.md.
8. Commit with message "milestone: PCNR_ 2018-2025, PECAN_ID, PCNR_Master_Data_Nov_2026".

Report the phase numbers you assigned and anything in the brief that conflicts with the
existing planning docs.
