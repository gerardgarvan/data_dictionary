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


# ---------------------------------------------------------------------------
# C23: WHERE statement in a DATA step that reads via INFILE
# ---------------------------------------------------------------------------

def test_c23_fires_on_infile_where():
    lines = [
        "data work.x;",
        "  infile 'foo.csv' dsd dlm=',' firstobs=2;",
        "  input file $ column $;",
        "  where strip(file) = 'bar';",
        "run;",
    ]
    hits = sas_lint.check_infile_where("<test>", lines)
    assert any("C23" in h[2] for h in hits), f"C23 did not fire: {hits}"


def test_c23_no_fire_when_set_present():
    lines = [
        "data work.x;",
        "  set work.y;",
        "  infile 'foo.csv' dsd dlm=',' firstobs=2;",
        "  input val $;",
        "  where val = 'bar';",
        "run;",
    ]
    hits = sas_lint.check_infile_where("<test>", lines)
    assert hits == [], f"C23 false-positive (has SET): {hits}"


def test_c23_no_fire_on_proc_sql_where():
    lines = [
        "proc sql;",
        "  select * from work.x where a = 1;",
        "quit;",
    ]
    hits = sas_lint.check_infile_where("<test>", lines)
    assert hits == [], f"C23 false-positive (PROC SQL): {hits}"


def test_c23_no_fire_on_subsetting_if():
    lines = [
        "data work.x;",
        "  infile 'foo.csv' dsd dlm=',' firstobs=2;",
        "  input file $ column $;",
        "  if strip(file) = 'bar';",
        "run;",
    ]
    hits = sas_lint.check_infile_where("<test>", lines)
    assert hits == [], f"C23 false-positive (subsetting IF): {hits}"


def test_c23_clean_on_phase5_macros():
    sas_path = ROOT / "sas" / "05_build_pcnr_macros.sas"
    lines = sas_path.read_text(encoding="utf-8", errors="replace").split("\n")
    hits = sas_lint.check_infile_where(str(sas_path), lines)
    assert hits == [], "C23 in macros file:\n" + "\n".join(str(h) for h in hits)


# ---------------------------------------------------------------------------
# D-24 guard: BUILD_STATUS DATA step in 04_name_map.sas must not reference
# variables absent from the documented _headers_aug schema.
# _headers_aug columns (from the PROC SQL that creates it):
#   s_code, col_order, col_name, sas_type, length, original_header,
#   trunc_flag, key_column_type, col_class, duplicate_study_id
# ---------------------------------------------------------------------------

_HEADERS_AUG_COLS = {
    "s_code", "col_order", "col_name", "sas_type", "length",
    "original_header", "trunc_flag", "key_column_type", "col_class",
    "duplicate_study_id",
}

def _extract_build_status_block(text):
    """Return lines of the DATA step inside %macro build_status ... that sets status."""
    lines = text.split("\n")
    in_macro = False
    in_data = False
    block = []
    for line in lines:
        if re.search(r'%macro\s+build_status\b', line, re.IGNORECASE):
            in_macro = True
            continue
        if in_macro and re.search(r'%mend\b', line, re.IGNORECASE):
            break
        if in_macro:
            if re.search(r'^\s*data\s+work\.\w', line, re.IGNORECASE):
                in_data = True
            if in_data:
                block.append(line)
            if in_data and re.search(r'^\s*run\s*;', line, re.IGNORECASE):
                in_data = False
    return block


def test_build_status_only_references_headers_aug_cols():
    """No variable in the BUILD_STATUS DATA step references a name absent from _headers_aug."""
    sas_path = ROOT / "sas" / "04_name_map.sas"
    text = sas_path.read_text(encoding="utf-8", errors="replace")
    block = _extract_build_status_block(text)
    assert block, "Could not locate BUILD_STATUS DATA step block in 04_name_map.sas"

    # Extract bare word tokens that look like SAS variable references
    # (alphabetic, not SAS keywords, not quoted strings)
    keywords = {
        "data", "set", "run", "if", "then", "else", "do", "end",
        "length", "status", "in", "and", "or", "not", "output",
        "upcase", "strip", "put", "input", "call", "symputx",
        "work", "name_map_status",
    }
    # Strip block comments before tokenizing
    block_text = "\n".join(block)
    block_text = re.sub(r'/\*.*?\*/', '', block_text, flags=re.DOTALL)
    suspicious = []
    for line in block_text.split("\n"):
        # Remove quoted strings
        cleaned = re.sub(r"'[^']*'|\"[^\"]*\"", "", line)
        # Find bare identifiers
        for tok in re.findall(r'\b([a-z_][a-z0-9_]*)\b', cleaned, re.IGNORECASE):
            tl = tok.lower()
            if tl in keywords:
                continue
            if tl in _HEADERS_AUG_COLS:
                continue
            # Allow status (output var) and all known _headers_aug cols
            if tl in {"status", "col_name", "original_header", "col_class",
                      "duplicate_study_id", "key_column_type", "s_code",
                      "trunc_flag", "sas_type", "col_order"}:
                continue
            # Flag anything that looks like orig_col_name (known bad pattern)
            if "orig" in tl and "col" in tl:
                suspicious.append(f"line: {line.strip()!r}  token: {tok!r}")

    assert not suspicious, (
        "BUILD_STATUS DATA step references variable(s) not in _headers_aug schema:\n"
        + "\n".join(suspicious)
    )


# ---------------------------------------------------------------------------
# C24: CALL EXECUTE with bare SQL (no proc sql wrapper)
# ---------------------------------------------------------------------------

def test_c24_fires_on_bare_sql_in_call_execute():
    lines = [
        "data _null_;",
        "  call execute(cats('insert into work.x select ''', name, ''' from pdd.pcnr where missing(', name, ');'));",
        "run;",
    ]
    hits = sas_lint.check_call_execute_bare_sql("<test>", lines)
    assert any("C24" in h[2] for h in hits), f"C24 did not fire: {hits}"


def test_c24_no_fire_when_proc_sql_wrapped():
    lines = [
        "data _null_;",
        "  call execute(cats('proc sql; insert into work.x select 1; quit;'));",
        "run;",
    ]
    hits = sas_lint.check_call_execute_bare_sql("<test>", lines)
    assert hits == [], f"C24 false-positive: {hits}"


def test_c24_clean_on_phase5_macros():
    sas_path = ROOT / "sas" / "05_build_pcnr_macros.sas"
    lines = sas_path.read_text(encoding="utf-8", errors="replace").split("\n")
    hits = sas_lint.check_call_execute_bare_sql(str(sas_path), lines)
    assert hits == [], "C24 in macros file:\n" + "\n".join(str(h) for h in hits)


# ---------------------------------------------------------------------------
# C26: literal 'pdd.' libref inside a macro body
# ---------------------------------------------------------------------------

def test_c26_fires_on_literal_pdd():
    lines = ["%macro foo;", "  set pdd.pcnr;", "%mend foo;"]
    hits = sas_lint.check_literal_pdd_in_macro("05_build_pcnr_macros.sas", lines)
    assert any("C26" in h[2] for h in hits), f"C26 did not fire: {hits}"


def test_c26_no_fire_outside_macro():
    lines = ["/* open code */", "libname pdd 'P:\\path';", "data work.x; set pdd.pcnr; run;"]
    hits = sas_lint.check_literal_pdd_in_macro("05_build_pcnr_macros.sas", lines)
    assert hits == [], f"C26 false-positive outside macro: {hits}"


def test_c26_clean_on_phase5_macros():
    sas_path = ROOT / "sas" / "05_build_pcnr_macros.sas"
    lines = sas_path.read_text(encoding="utf-8", errors="replace").split("\n")
    hits = sas_lint.check_literal_pdd_in_macro(str(sas_path), lines)
    assert hits == [], "C26 in macros file:\n" + "\n".join(str(h) for h in hits)


# ---------------------------------------------------------------------------
# C11d: bare %macroname in %put text or double-quoted put string
# ---------------------------------------------------------------------------

def test_c11d_fires_on_put_text_bare_macro():
    lines = ["%put NOTE: [06_profile] %pdd_profile starting;"]
    hits = sas_lint.check_bare_macro_in_text("<test>", lines)
    codes = [h[2] for h in hits]
    assert 'C11d' in codes, f"C11d did not fire on %put bare macro: {hits}"

def test_c11d_fires_on_put_string_bare_macro():
    lines = ['    put "/* Generated by %p6_classify_vars -- do not edit */";']
    hits = sas_lint.check_bare_macro_in_text("<test>", lines)
    codes = [h[2] for h in hits]
    assert 'C11d' in codes, f"C11d did not fire on put string bare macro: {hits}"

def test_c11d_ignores_safe_functions():
    lines = [
        "%put NOTE: value is %sysfunc(date());",
        "%put NOTE: %str(this is literal);",
        '  put "some %superq(var) text";',
    ]
    hits = sas_lint.check_bare_macro_in_text("<test>", lines)
    assert hits == [], f"C11d false-positive on safe functions: {hits}"

def test_c11d_ignores_macro_with_parens():
    # C11b catches this; C11d should not double-fire (parens excluded)
    lines = ["%put NOTE: %somemacro();"]
    hits = sas_lint.check_bare_macro_in_text("<test>", lines)
    assert hits == [], f"C11d should not fire when parens present: {hits}"

def test_c11d_clean_on_phase6_macros():
    path = ROOT / "sas" / "06_profile_macros.sas"
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().split("\n")
    hits = sas_lint.check_bare_macro_in_text(str(path), lines)
    assert hits == [], "C11d in 06_profile_macros.sas:\n" + "\n".join(str(h) for h in hits)

def test_c11d_clean_on_phase6_orchestrator():
    path = ROOT / "sas" / "06_profile.sas"
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().split("\n")
    hits = sas_lint.check_bare_macro_in_text(str(path), lines)
    assert hits == [], "C11d in 06_profile.sas:\n" + "\n".join(str(h) for h in hits)

# ---------------------------------------------------------------------------
# C15: /* inside double-quoted string (block-comment opener in macro context)
# ---------------------------------------------------------------------------

def test_c15_fires_on_slash_star_in_dquote():
    lines = ['      put "NOTE: char *_date/*_dttm variable: " name;']
    hits = sas_lint.check_comment_in_dquote("<test>", lines)
    codes = [h[2] for h in hits]
    assert 'C15' in codes, f"C15 did not fire: {hits}"

def test_c15_ignores_no_slash_star():
    lines = ['      put "NOTE: char *_date / *_dttm variable: " name;']
    hits = sas_lint.check_comment_in_dquote("<test>", lines)
    assert hits == [], f"C15 false-positive: {hits}"

def test_c15_clean_on_phase6_macros():
    path = ROOT / "sas" / "06_profile_macros.sas"
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().split("\n")
    hits = sas_lint.check_comment_in_dquote(str(path), lines)
    assert hits == [], "C15 in 06_profile_macros.sas:\n" + "\n".join(str(h) for h in hits)


# ---------------------------------------------------------------------------
# C26b: %do/%end balance per macro
# ---------------------------------------------------------------------------

def test_c26b_fires_on_unbalanced_do():
    lines = [
        "%macro foo;",
        "  %if 1 %then %do;",
        "  /* no %end */",
        "%mend foo;",
    ]
    hits = sas_lint.check_do_end_balance("<test>", lines)
    codes = [h[2] for h in hits]
    assert 'C26b' in codes, f"C26b did not fire: {hits}"

def test_c26b_ignores_balanced():
    lines = [
        "%macro foo;",
        "  %if 1 %then %do;",
        "  %end;",
        "%mend foo;",
    ]
    hits = sas_lint.check_do_end_balance("<test>", lines)
    assert hits == [], f"C26b false-positive: {hits}"

def test_c26b_slash_star_in_put_string_not_comment():
    """/* inside a double-quoted put string must NOT be treated as block comment."""
    lines = [
        "%macro foo;",
        "  %if 1 %then %do;",
        '    put "/* this is literal text */";',
        "  %end;",
        "%mend foo;",
    ]
    hits = sas_lint.check_do_end_balance("<test>", lines)
    assert hits == [], f"C26b false-positive on put string: {hits}"

def test_c26b_clean_on_phase6_macros():
    path = ROOT / "sas" / "06_profile_macros.sas"
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().split("\n")
    hits = sas_lint.check_do_end_balance(str(path), lines)
    assert hits == [], "C26b in 06_profile_macros.sas:\n" + "\n".join(str(h) for h in hits)


def test_c11d_fires_on_all_five_original_offenders():
    offenders = [
        'put "/* Generated by %p6_classify_vars -- do not edit */";',
        'put "/* Generated by %p6_freq_lowcard -- do not edit */";',
        'put "/* Generated by %p6_freq_highcard -- do not edit */";',
        '%put NOTE: [06_profile] %pdd_profile starting: lib=&lib;',
        '%put NOTE: [06_profile] %pdd_profile complete for family=&family;',
    ]
    for line in offenders:
        hits = sas_lint.check_bare_macro_in_text("<test>", [line])
        codes = [h[2] for h in hits]
        assert 'C11d' in codes, f"C11d did not fire on: {line!r} -- hits={hits}"


# ---------------------------------------------------------------------------
# C27: LIKE in DATA step IF expression
# ---------------------------------------------------------------------------

def test_c27_fires_on_like_in_datastep_if():
    lines = [
        "data work.test;",
        "  set work.src;",
        "  if upcase(name) like '%_DATE' then x = 1;",
        "run;",
    ]
    hits = sas_lint.check_like_in_datastep("<test>", lines)
    codes = [h[2] for h in hits]
    assert 'C27' in codes, f"C27 did not fire: {hits}"

def test_c27_ignores_like_in_where_clause():
    lines = [
        "data work.test;",
        "  set work.src;",
        "  where upcase(name) like '%_DATE';",
        "run;",
    ]
    hits = sas_lint.check_like_in_datastep("<test>", lines)
    assert hits == [], f"C27 false-positive on WHERE: {hits}"

def test_c27_ignores_like_in_proc_sql():
    lines = [
        "proc sql noprint;",
        "  select * from work.src where name like '%_DATE';",
        "quit;",
    ]
    hits = sas_lint.check_like_in_datastep("<test>", lines)
    assert hits == [], f"C27 false-positive on PROC SQL: {hits}"

def test_c27_clean_on_phase6_macros():
    path = ROOT / "sas" / "06_profile_macros.sas"
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().split("\n")
    hits = sas_lint.check_like_in_datastep(str(path), lines)
    assert hits == [], "C27 in 06_profile_macros.sas:\n" + "\n".join(str(h) for h in hits)


# ---------------------------------------------------------------------------
# W9: DATA/PROC reading &lib..&ds inside a %do variable loop
# ---------------------------------------------------------------------------

def test_w9_fires_on_set_in_do_loop():
    lines = [
        "%do %while (&i <= &n);",
        "  data work.tmp; set &lib..&ds; run;",
        "%end;",
    ]
    hits = sas_lint.check_ds_read_in_varloop("<test>", lines)
    assert len(hits) == 1, f"W9 should fire once: {hits}"
    assert hits[0][2] == "W9"


def test_w9_fires_on_data_eq_in_do_loop():
    lines = [
        "%do i = 1 %to &n;",
        "  proc means data=&mylib..&myds; run;",
        "%end;",
    ]
    hits = sas_lint.check_ds_read_in_varloop("<test>", lines)
    assert len(hits) == 1, f"W9 should fire once: {hits}"


def test_w9_exempt_suppresses():
    lines = [
        "%do %while (&i <= &n);",
        "  data work.tmp; set &lib..&ds; /* W9-exempt */ run;",
        "%end;",
    ]
    hits = sas_lint.check_ds_read_in_varloop("<test>", lines)
    assert hits == [], f"W9-exempt should suppress: {hits}"


def test_w9_ignores_read_outside_loop():
    lines = [
        "data work.tmp; set &lib..&ds; run;",
    ]
    hits = sas_lint.check_ds_read_in_varloop("<test>", lines)
    assert hits == [], f"W9 outside loop should not fire: {hits}"


def test_w9_clean_on_phase6_macros():
    path = ROOT / "sas" / "06_profile_macros.sas"
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().split("\n")
    hits = sas_lint.check_ds_read_in_varloop(str(path), lines)
    assert hits == [], "W9 in 06_profile_macros.sas:\n" + "\n".join(str(h) for h in hits)


# ---------------------------------------------------------------------------
# C20: TRIMMED in PROC SQL SELECT list


def _c20_hits(code):
    return sas_lint.check_sql_select_trimmed("test.sas", code.split("\n"))


def test_c20_fires_on_trimmed_in_select_list():
    code = """
proc sql noprint;
  select put(modate, 16.) trimmed, nobs
  into :mv1 trimmed, :mv2 trimmed
  from dictionary.tables;
quit;
"""
    hits = _c20_hits(code)
    assert hits, "C20 should fire when TRIMMED appears in SELECT list"
    assert hits[0][2] == "C20"


def test_c20_clean_when_trimmed_only_in_into():
    code = """
proc sql noprint;
  select put(modate, 16.), nobs
  into :mv1 trimmed, :mv2 trimmed
  from dictionary.tables;
quit;
"""
    hits = _c20_hits(code)
    assert hits == [], f"C20 false positive: {hits}"


def test_c20_clean_on_07_build_profile():
    path = ROOT / "sas" / "07_build_profile.sas"
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().split("\n")
    hits = sas_lint.check_sql_select_trimmed(str(path), lines)
    assert hits == [], "C20 in 07_build_profile.sas:\n" + "\n".join(str(h) for h in hits)


# ---------------------------------------------------------------------------
# C30: semicolon inside %put text or %fail_out(msg=%str(...))
# ---------------------------------------------------------------------------

def test_c30_fires_on_semicolon_in_put():
    lines = ["%put NOTE: [x] check ok (expected; that is fine);"]
    hits = sas_lint.check_semicolon_in_put_text("<test>", lines)
    assert any(h[2] == "C30" for h in hits), hits


def test_c30_fires_on_semicolon_in_fail_out_str():
    lines = ["%fail_out(msg=%str(PENDING DECISION -- a; b));"]
    hits = sas_lint.check_semicolon_in_put_text("<test>", lines)
    assert any(h[2] == "C30" for h in hits), hits


def test_c30_fires_on_multiline_fail_out_str():
    lines = ["%fail_out(msg=%str(first line", "  second; third));"]
    hits = sas_lint.check_semicolon_in_put_text("<test>", lines)
    assert any(h[2] == "C30" for h in hits), hits


def test_c30_clean_cases():
    lines = [
        "%put NOTE: [x] plain text, with a comma;",
        "%put NOTE: first; %let y = 1;",
        "%fail_out(msg=%str(PENDING DECISION -- a, b (c)));",
    ]
    assert sas_lint.check_semicolon_in_put_text("<test>", lines) == []


# ---------------------------------------------------------------------------
# C31: SET ... POINT= without STOP
# ---------------------------------------------------------------------------

def test_c31_fires_on_point_without_stop():
    lines = ["data work.x;", "  do i = 1 to 3;", "    set work.y point=i;",
             "    output;", "  end;", "run;"]
    hits = sas_lint.check_set_point_no_stop("<test>", lines)
    assert any(h[2] == "C31" for h in hits), hits


def test_c31_fires_on_point_macro_without_stop():
    lines = ["data _null_;", "  %p16_shorten(nm=a, abbrev=b);", "run;"]
    hits = sas_lint.check_set_point_no_stop("<test>", lines)
    assert any(h[2] == "C31" for h in hits), hits


def test_c31_clean_cases():
    with_stop = ["data work.x;", "  set work.y point=i;", "  output;", "  stop;", "run;"]
    with_set = ["data work.x;", "  set work.z;", "  set work.y point=i;", "run;"]
    no_point = ["data work.x;", "  set work.z;", "run;"]
    in_text = ['data _null_;', '  put "point=1";', 'run;']
    for lines in (with_stop, with_set, no_point, in_text):
        assert sas_lint.check_set_point_no_stop("<test>", lines) == [], lines


# ---------------------------------------------------------------------------
# C32: PROC SQL reserved word as column name
# ---------------------------------------------------------------------------

def test_c32_fires_on_case_column_in_sql_file():
    lines = ["data work.t;", "  length case $20;", "  case = 'a';", "run;",
             "proc sql;", "  select count(*) from work.t where case = 'a';", "quit;"]
    hits = sas_lint.check_sql_reserved_column("<test>", lines)
    assert any(h[2] == "C32" for h in hits), hits


def test_c32_clean_cases():
    case_when = ["proc sql;", "  select case when a = 1 then 'x' else 'y' end as z",
                 "  from work.t;", "quit;"]
    no_sql = ["data work.t;", "  case = 'a';", "run;"]
    renamed = ["data work.t;", "  tcase = 'a';", "run;", "proc sql;",
               "  select tcase from work.t;", "quit;"]
    for lines in (case_when, no_sql, renamed):
        assert sas_lint.check_sql_reserved_column("<test>", lines) == [], lines


def test_c31_fires_when_only_if0_set_present():
    lines = ["data work.t;", "  if 0 then set work.a nobs=n;",
             "  %p16_shorten(nm=nm, abbrev=work.a)", "  output;", "run;"]
    hits = sas_lint.check_set_point_no_stop("<test>", lines)
    assert any(h[2] == "C31" for h in hits), hits


# ---------------------------------------------------------------------------
# C33 member name length, C34 %if &cond without %unquote, C35 GROUP BY no summary
# ---------------------------------------------------------------------------

def test_c33_fires_on_long_stem_and_long_member():
    long_stem = ["%p17_backup_table(ds=pdd.x, stem=pecan_id_registry);"]
    long_member = ["data pdd.pecan_id_registry_prelink_20260101_010101;"]
    for lines in (long_stem, long_member):
        hits = sas_lint.check_member_name_length("<test>", lines)
        assert any(h[2] == "C33" for h in hits), lines


def test_c33_clean_cases():
    for lines in (["%p17_backup_table(ds=pdd.x, stem=pidreg);"],
                  ["%p17_backup_table(ds=pdd.x, stem=pidreg_prelink);"],
                  ["data pdd.pecan_id_registry_next;"],
                  ["data p17bak.&_p17_last_backup;"]):
        assert sas_lint.check_member_name_length("<test>", lines) == [], lines


def test_c34_fires_without_unquote():
    hits = sas_lint.check_if_quoted_param("<test>", ["  %if &cond %then %put x;"])
    assert any(h[2] == "C34" for h in hits), hits


def test_c34_clean_cases():
    for lines in (["  %if %unquote(&cond) %then %put x;"],
                  ["  %if &_res = PASS %then %put x;"]):
        assert sas_lint.check_if_quoted_param("<test>", lines) == [], lines


def test_c35_fires_on_group_by_without_summary():
    lines = ["proc sql;", "  create table w as select a, b from t group by a, b;", "quit;"]
    hits = sas_lint.check_group_by_no_summary("<test>", lines)
    assert any(h[2] == "C35" for h in hits), hits


def test_c35_clean_cases():
    ok1 = ["proc sql;", "  select a, count(*) as n from t group by a;", "quit;"]
    ok2 = ["proc sql;", "  select a from t group by a having count(*) > 1;", "quit;"]
    ok3 = ["proc sql;", "  select distinct a, b from t order by a;", "quit;"]
    for lines in (ok1, ok2, ok3):
        assert sas_lint.check_group_by_no_summary("<test>", lines) == [], lines


# C36 called p16_/p17_ macro must be defined or included
def test_c36_fires_when_macro_not_included(tmp_path):
    f = tmp_path / "prod.sas"
    f.write_text('%include "&sas_path.\other_macros.sas";\n%p17_topcode(in=a);\n', encoding="utf-8")
    (tmp_path / "other_macros.sas").write_text("%macro p17_other;\n%mend p17_other;\n", encoding="utf-8")
    hits = sas_lint.check_macro_defined_or_included(str(f), f.read_text(encoding="utf-8").split("\n"))
    assert any(h[2] == "C36" for h in hits), hits


def test_c36_passes_when_included_or_defined(tmp_path):
    (tmp_path / "m_macros.sas").write_text("%macro p17_topcode(in=);\n%mend p17_topcode;\n", encoding="utf-8")
    f = tmp_path / "prod.sas"
    f.write_text('%include "&sas_path.\m_macros.sas";\n%macro p16_x;\n%mend p16_x;\n%p17_topcode(in=a);\n%p16_x;\n',
                 encoding="utf-8")
    assert sas_lint.check_macro_defined_or_included(str(f), f.read_text(encoding="utf-8").split("\n")) == []


# ---------------------------------------------------------------------------
# C37 &macrovar in single quotes, C38 where text without %unquote
# ---------------------------------------------------------------------------

def test_c37_fires_on_macrovar_in_single_quotes():
    for lines in (["infile 'C:\tmp\&_dec';"],
                  ["put 'NOTE: n=&n';"]):
        hits = sas_lint.check_macrovar_in_single_quotes("<test>", lines)
        assert any(h[2] == "C37" for h in hits), lines


def test_c37_clean_cases():
    for lines in (['infile "C:\tmp\&_dec";'],
                  ["_line = cat('  ', ' = \"&s_code\";');"],
                  ["where memname like 'QC_%';", "x = \"&a\";"],
                  ["%put NOTE: it's &x;"],
                  ["%let q = %str(%')&x;"]):
        assert sas_lint.check_macrovar_in_single_quotes("<test>", lines) == [], lines


def test_c38_fires_without_unquote():
    hits = sas_lint.check_where_param_no_unquote(
        "<test>", ["select a from &ds where &where;"])
    assert any(h[2] == "C38" for h in hits), hits


def test_c39_fires_on_char_length_over_32767():
    for lines in (["length _pv $65540 _ps $64;"],
                  ["data x;", "  length a $", "    40000;", "run;"],
                  ['put "length _pv $32768;";']):
        hits = sas_lint.check_char_length_over_max("<test>", lines)
        assert any(h[2] == "C39" for h in hits), lines


def test_c39_clean_cases():
    for lines in (["length _pv $32767 _ps $64 _pl 8;"],
                  ["length n 8;", "x = lengthn(y);"],
                  ["infile f length=_ln lrecl=1048576;"],
                  ["put _pv $varying32767. _pk @;"]):
        assert sas_lint.check_char_length_over_max("<test>", lines) == [], lines


def test_c40_fires_on_large_lrecl_with_infile_var():
    lines = ["data _null_;", "  infile f lrecl=1048576 truncover;", "  input;",
             "  n = countc(_infile_, 'x');", "run;"]
    hits = sas_lint.check_infile_large_lrecl("<test>", lines)
    assert any(h[2] == "C40" for h in hits), hits


def test_c40_clean_cases():
    for lines in (["data _null_;", "infile f lrecl=32767;", "input;", "x=_infile_;", "run;"],
                  ["data _null_;", "infile f lrecl=1048576;", "input a $char100.;", "run;"],
                  ["data _null_;", "infile f lrecl=1048576;", "run;",
                   "data _null_;", "infile g;", "x=_infile_;", "run;"]):
        assert sas_lint.check_infile_large_lrecl("<test>", lines) == [], lines


def test_c38_clean_cases():
    for lines in (["select a from &ds where %unquote(&where);"],
                  ["%_val(ds=x, where=&where);"],
                  ["%let where = a;"]):
        assert sas_lint.check_where_param_no_unquote("<test>", lines) == [], lines
