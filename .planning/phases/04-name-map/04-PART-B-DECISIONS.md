# Phase 4 Part B — Decision handling for docs/name_map_decisions.csv

B1. SAME closure: merge groups transitively (union-find), so A=B and B=C yields one group.
    Final group_id = smallest group_id in the merged set.
B2. DIFFERENT split: if both sides of a DIFFERENT decision are currently in the same
    automatic group, split them into separate groups (side b's row, and any rows that matched
    the group only through side b's cleaned name, get a new group_id); log each split to the
    log and a QC dataset. If they are already in different groups, no-op (logged).
B3. Decision matching (exists -- verify): identify each side's group by (s_code, col_order)
    membership, not by the group's representative row. Fail if a side's (s_code, col_order)
    does not exist in import_spec, or if header_x does not match that row's original_header.
B4. RENAME checks (exists -- verify): new_name must be V7-valid, <=32 chars including the
    PCNR_ prefix, unique case-insensitively across all final names, and a group may receive
    only one new_name. Fail otherwise.
B5. Same-file guard: after all decisions are applied (B1/B2/B4), assert that no group contains
    two rows from the same s_code. Fail with a list of offending group_id/s_code/col_order.
B6. Decisions header: done (5c701c5). Python template writer must emit the same 11-column header.
B7. Suffix re-elision (exists -- verify): in stage1_suffix, if a suffixed name exceeds the
    limit, re-elide via %elide_middle with target length = limit minus suffix length; after
    suffixing, assert no final name contains "___".
B8. Synthetic test tests/04_decisions_test.sas: standalone-runnable on a small synthetic
    import_spec (no PHI, no P: data), printing PASS/FAIL per case:
      a. SAME chain A=B, B=C -> one group
      b. DIFFERENT on two rows in one automatic group -> two groups
      c. valid RENAME -> applied
      d. RENAME too long -> fail;  RENAME duplicate name -> fail
      e. SAME merging two rows from the same s_code -> fail (B5)
      f. decision with nonexistent (s_code, col_order) -> fail (B3)
      g. bad header -> fail;  header with UTF-8 BOM -> pass;  correct header -> no ERROR

Order: save this doc and commit; implement B1, B2, B5 (one commit each); verify/extend B3,
B4, B7; then B8. Push after each commit. Then run tests/04_decisions_test.sas and
cmd /c run_pipeline.cmd 4 and report PASS/FAIL per case, elided, suffixes, collisions,
and Phase 4 exit status.
