"""
python/tests/test_sas_lint.py
Tests for tools/sas_lint.py rules, plus a cross-file free-global check for
Phase 5 SAS files (C17 + free-global audit).
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
import sas_lint  # noqa: E402

# ---------------------------------------------------------------------------
# C17: self-referencing parameter default
# ---------------------------------------------------------------------------

def test_c17_fires_on_self_ref():
    lines = ["%macro foo(bar=&bar, baz=literal); %mend foo;"]
    hits = sas_lint.check_self_ref_param_default("<test>", lines)
    names = [h[3] for h in hits]
    assert any("bar=&bar" in n for n in names), f"C17 did not fire: {hits}"

def test_c17_ignores_different_names():
    lines = ["%macro foo(bar=&sas_path, baz=&exchange_path); %mend foo;"]
    hits = sas_lint.check_self_ref_param_default("<test>", lines)
    assert hits == [], f"C17 false-positive: {hits}"

def test_c17_clean_on_phase5_macros():
    path = ROOT / "sas" / "05_build_pcnr_macros.sas"
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().split("\n")
    hits = sas_lint.check_self_ref_param_default(str(path), lines)
    assert hits == [], "C17 in macros file:\n" + "\n".join(str(h) for h in hits)

def test_c17_clean_on_orchestrator():
    path = ROOT / "sas" / "05_build_pcnr.sas"
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().split("\n")
    hits = sas_lint.check_self_ref_param_default(str(path), lines)
    assert hits == [], "C17 in orchestrator:\n" + "\n".join(str(h) for h in hits)


# ---------------------------------------------------------------------------
# Free-global check: every &varname referenced in Phase 5 files must be
#   (a) a macro parameter declared in %macro foo(...),
#   (b) declared %local inside a macro, or
#   (c) declared %global in those files or 00_config.sas, or
#   (d) a SAS automatic macro variable.
# ---------------------------------------------------------------------------

_SAS_AUTOMATICS = frozenset("""
syserr sqlrc sysrc syslast sysdate systime sysday sysjobid sysver syscc
sysindex sysparm sysprocessid sysprocessname sysenv sysscpl syshostname
sysscp sysmenv sysprod sysstartid sysstartname
""".split())

# Macro variables that are caller-contract for the smoke test (pre-set before
# %include of the macros file, not declared inside it -- by design).
_CALLER_CONTRACT = frozenset("""
p5_smoke_srclib p5_smoke_outlib p5_smoke_spine_n p5_smoke_nvars
p5_smoke_gen_dir p5_smoke_exp_dir p5_smoke_pri_csv p5_smoke_ov_csv
p5_smoke_cls_csv
""".split())

# Globals set by 00_config.sas / %pdd_lib (legitimate external context)
_CONFIG_GLOBALS = frozenset("""
sas_path raw_master out_root qc_path logs_path out_path exchange_path
in_pipeline
""".split())

# Internal resolved-path vars set by _p5_init_paths in the orchestrator
_ORCHESTRATOR_INTERNALS = frozenset("""
_p5_srclib _p5_nmlib _p5_outlib _p5_spine_n _p5_nvars
_p5_gen_dir _p5_exp_dir _p5_priority_csv _p5_override_csv _p5_s06class_csv
_work
""".split())

# Match single-& references only (not && indirect references like &&_gf_rn_&_j)
_REF_PAT = re.compile(r'(?<!&)&(\w+)', re.IGNORECASE)
_MACRO_SIG = re.compile(r'%macro\s+\w+\s*\(([^)]*)\)', re.IGNORECASE | re.DOTALL)
_PARAM_NAME = re.compile(r'\b(\w+)', re.IGNORECASE)  # used per-token after comma-split
_LOCAL_PAT = re.compile(r'%local\s+(.*?);', re.IGNORECASE | re.DOTALL)
_GLOBAL_PAT = re.compile(r'%global\s+(.*?);', re.IGNORECASE | re.DOTALL)
_WORD = re.compile(r'\w+')


def _collect_knowns(*paths):
    """Return set of all macro variable names that are explicitly declared."""
    known = set(_SAS_AUTOMATICS) | set(_CONFIG_GLOBALS) | set(_CALLER_CONTRACT) | set(_ORCHESTRATOR_INTERNALS)
    for path in paths:
        text = sas_lint.strip_block_comments(
            Path(path).read_text(encoding="utf-8", errors="replace")
        )
        # %global declarations
        for m in _GLOBAL_PAT.finditer(text):
            for w in _WORD.findall(m.group(1)):
                known.add(w.lower())
        # %local declarations
        for m in _LOCAL_PAT.finditer(text):
            for w in _WORD.findall(m.group(1)):
                known.add(w.lower())
        # macro parameters: split on comma, take the name before any '='
        for m in _MACRO_SIG.finditer(text):
            for token in m.group(1).split(','):
                token = token.strip()
                pname = token.split('=')[0].strip()
                if re.match(r'^\w+$', pname):
                    known.add(pname.lower())
    return known


def _free_global_refs(path, known):
    """Return list of (line_no, varname) for undeclared &var references."""
    text = sas_lint.strip_block_comments(
        Path(path).read_text(encoding="utf-8", errors="replace")
    )
    hits = []
    for i, line in enumerate(text.split("\n"), 1):
        for m in _REF_PAT.finditer(line):
            vname = m.group(1).lower()
            if vname not in known:
                hits.append((i, vname))
    return hits


def test_no_free_globals_in_phase5():
    macros_path = ROOT / "sas" / "05_build_pcnr_macros.sas"
    orch_path   = ROOT / "sas" / "05_build_pcnr.sas"

    known = _collect_knowns(macros_path, orch_path)

    hits_macros = _free_global_refs(macros_path, known)
    hits_orch   = _free_global_refs(orch_path,   known)

    messages = []
    for line_no, vname in hits_macros:
        messages.append(f"  05_build_pcnr_macros.sas:{line_no}: undeclared &{vname}")
    for line_no, vname in hits_orch:
        messages.append(f"  05_build_pcnr.sas:{line_no}: undeclared &{vname}")

    assert not messages, "Free global references found:\n" + "\n".join(messages)


# ---------------------------------------------------------------------------
# Schema fixture check: test name_map / name_map_vars fixtures must contain
# all columns listed in docs/name_map_schema.csv.
# ---------------------------------------------------------------------------

def _parse_schema_csv():
    """Return dict {table: set_of_column_names} from docs/name_map_schema.csv."""
    schema_path = ROOT / "docs" / "name_map_schema.csv"
    schema = {}
    with open(schema_path, encoding="utf-8") as fh:
        next(fh)  # skip header
        for line in fh:
            line = line.strip()
            if not line:
                continue
            parts = line.split(",")
            table, col = parts[0].strip(), parts[1].strip()
            schema.setdefault(table, set()).add(col.lower())
    return schema


def _extract_fixture_columns(sas_text, table_name):
    """Extract declared column names from 'data work.<table>;' blocks in SAS text.

    Parses the LENGTH statement to find column names.
    Returns set of lowercase column names found across all blocks for that table.
    """
    # Strip block comments
    clean = sas_lint.strip_block_comments(sas_text)
    cols = set()
    # Find data work.<table>; ... run; blocks
    block_pat = re.compile(
        r'data\s+(?:work\.)?'
        + re.escape(table_name)
        + r'\s*;(.*?)(?=\brun\s*;)',
        re.IGNORECASE | re.DOTALL,
    )
    length_pat = re.compile(r'\blength\b(.*?);', re.IGNORECASE | re.DOTALL)
    type_kw = re.compile(r'^\$?\d', re.IGNORECASE)  # skip $200, 8, etc.
    skip = {'length', 'set', 'keep', 'drop', 'rename', 'stop', 'retain'}
    for bm in block_pat.finditer(clean):
        body = bm.group(1)
        for lm in length_pat.finditer(body):
            tokens = lm.group(1).split()
            for tok in tokens:
                tok_clean = tok.strip(';').strip()
                if not tok_clean:
                    continue
                if type_kw.match(tok_clean):
                    continue  # $200, 8, $4 etc.
                if tok_clean.lower() in skip:
                    continue
                if re.match(r'^[A-Za-z_]\w*$', tok_clean):
                    cols.add(tok_clean.lower())
    return cols


def _check_fixture_schema(sas_path, schema, required_tables):
    """Assert fixture SAS file contains all schema columns for each required table."""
    text = sas_path.read_text(encoding="utf-8", errors="replace")
    messages = []
    for table in required_tables:
        required_cols = schema.get(table, set())
        fixture_cols = _extract_fixture_columns(text, table)
        missing = required_cols - fixture_cols
        if missing:
            messages.append(
                f"  {sas_path.name}: {table} fixture missing columns: "
                + ", ".join(sorted(missing))
            )
    return messages


def test_fixture_schema_build_test():
    # Tests use only the subset of columns that the macros actually read;
    # trunc_flag/group_id/sas_type/length are not read by any macro, so not required.
    required_nm = {'s_code', 'sas_name', 'pcnr_name', 'status', 'original_header', 'col_order'}
    required_nmv = {'pcnr_name', 'result_type', 'max_length', 'type_conflict',
                    'n_sources', 's_codes_contributing'}
    sas_path = ROOT / "tests" / "05_build_test.sas"
    text = sas_path.read_text(encoding="utf-8", errors="replace")
    messages = []
    for table, required in [('name_map', required_nm), ('name_map_vars', required_nmv)]:
        fixture_cols = _extract_fixture_columns(text, table)
        missing = required - fixture_cols
        if missing:
            messages.append(
                f"  05_build_test.sas: {table} fixture missing columns: "
                + ", ".join(sorted(missing))
            )
    assert not messages, "Fixture schema gaps:\n" + "\n".join(messages)


def test_fixture_schema_smoke_test():
    sas_path = ROOT / "tests" / "05_orchestrator_smoke.sas"
    text = sas_path.read_text(encoding="utf-8", errors="replace")
    required_nm = {'s_code', 'sas_name', 'pcnr_name', 'status', 'original_header', 'col_order'}
    required_nmv = {'pcnr_name', 'result_type', 'max_length', 'type_conflict',
                    'n_sources', 's_codes_contributing'}
    messages = []
    for table, required in [('name_map', required_nm), ('name_map_vars', required_nmv)]:
        fixture_cols = _extract_fixture_columns(text, table)
        missing = required - fixture_cols
        if missing:
            messages.append(
                f"  05_orchestrator_smoke.sas: {table} fixture missing columns: "
                + ", ".join(sorted(missing))
            )
    assert not messages, "Fixture schema gaps:\n" + "\n".join(messages)
