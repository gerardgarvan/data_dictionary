#!/usr/bin/env python3
"""
tools/sas_lint.py  --  Static linter for PDD pipeline SAS files.

Checks
------
C1  ?? inside a PROC SQL block (valid only in DATA step INPUT)
C2  ANSI SQL not supported in PROC SQL: OFFSET/FETCH, LIMIT, TOP n,
    ROW_NUMBER() OVER, WITH ... AS
C3  %if / %else at open-code level (outside %macro ... %mend)
C4  %then <non-%do text>;; followed by %else on the next non-blank line
C5  %if comparison RHS is a bare identifier that itself contains - or .
    (hyphen is arithmetic; trailing dot is a macro word-delimiter)
C6  ORDER BY clause containing an aggregate function
C7  fdelete / fexist / fopen called with a string literal as fileref
C8  prxmatch with $ anchor on a variable not wrapped in strip()
C9  LIBNAME statement with engine placed after the path string (wrong order)
C10 array _character_ / _numeric_ declared before SET/MERGE/INPUT in a DATA step
C11 SAS macro keyword inside a quoted string on a PUT line (macro-in-put)
C13 Macro called before its %macro definition within the same file
C14 DATA or SET statement with no dataset name (bare "data ;" / "set ;")
W2  Assert-style count query: reports dataset name and WHERE-clause columns for reviewer

Usage
-----
    python tools/sas_lint.py sas/00_config.sas sas/03a_build_spec.sas ...

Exit codes
----------
    0  no hits
    1  one or more hits found
"""

import re
import sys
import glob as _glob

CI = re.IGNORECASE


# ── comment stripping ─────────────────────────────────────────────────────────

def strip_block_comments(text):
    """Replace /* ... */ with whitespace preserving line numbers."""
    def _blank(m):
        return '\n' * m.group().count('\n')
    return re.sub(r'/\*.*?\*/', _blank, text, flags=re.DOTALL)


# ── C1: ?? in PROC SQL ────────────────────────────────────────────────────────

def check_qq_in_sql(path, lines):
    """?? modifier is invalid in PROC SQL; it is only valid in DATA step INPUT."""
    hits = []
    in_sql = False
    for i, raw in enumerate(lines, 1):
        if re.search(r'\bPROC\s+SQL\b', raw, CI):
            in_sql = True
        if in_sql and '??' in raw:
            hits.append((path, i, 'C1',
                '?? modifier is invalid inside PROC SQL -- move the count to a DATA step'))
        if in_sql and re.search(r'^\s*QUIT\s*;', raw, CI):
            in_sql = False
        # A new DATA or non-SQL PROC step also ends the SQL context
        if in_sql \
                and re.match(r'^\s*(DATA|PROC)\s+\w', raw, CI) \
                and not re.search(r'\bPROC\s+SQL\b', raw, CI):
            in_sql = False
    return hits


# ── C2: ANSI SQL syntax ───────────────────────────────────────────────────────

_ANSI_PATTERNS = [
    (r'\bOFFSET\s+\d+\b',               'OFFSET not supported in PROC SQL'),
    (r'\bFETCH\s+(NEXT|FIRST)\b',       'FETCH NEXT/FIRST not supported in PROC SQL'),
    (r'\bLIMIT\s+\d+\b',                'LIMIT not supported in PROC SQL'),
    (r'\bTOP\s+\d+\b',                  'TOP n not supported in PROC SQL'),
    (r'\bROW_NUMBER\s*\(\s*\)\s+OVER\s*\(', 'ROW_NUMBER() OVER not supported in PROC SQL'),
    (r'\bWITH\s+\w+\s+AS\s*\(',         'WITH ... AS CTE not supported in PROC SQL'),
]

def check_ansi_sql(path, lines):
    hits = []
    for i, raw in enumerate(lines, 1):
        for pat, msg in _ANSI_PATTERNS:
            if re.search(pat, raw, CI):
                hits.append((path, i, 'C2', msg))
    return hits


# ── C3: open-code %if / %else ─────────────────────────────────────────────────

def check_opencode_if(path, lines):
    """Flag %if / %else that appears outside any %macro ... %mend block."""
    hits = []
    depth = 0
    for i, raw in enumerate(lines, 1):
        depth += len(re.findall(r'%macro\b', raw, CI))
        if depth == 0 and re.search(r'%\s*(if|else)\b', raw, CI):
            hits.append((path, i, 'C3',
                '%if / %else at open-code level (outside %macro ... %mend)'))
        depth = max(0, depth - len(re.findall(r'%mend\b', raw, CI)))
    return hits


# ── C4: %then <text>;; followed by %else ─────────────────────────────────────

def check_then_double_semi(path, lines):
    """Detect %then <non-%do stmt>;; where the next non-blank line is %else."""
    hits = []
    non_blank = [i for i, l in enumerate(lines) if l.strip()]
    for pos, lnum in enumerate(non_blank):
        raw = lines[lnum]
        if re.search(r'%then\b(?!\s*%do\b).*;;', raw, CI):
            if pos + 1 < len(non_blank):
                nxt = lines[non_blank[pos + 1]]
                if re.search(r'^\s*%else\b', nxt, CI):
                    hits.append((path, lnum + 1, 'C4',
                        '%then <text>;; followed by %else -- the %else branch is unreachable'))
    return hits


# ── C5: %if comparison with dangerous bare identifier on RHS ──────────────────
#
# The two real risks:
#   a) RHS contains - (hyphen treated as arithmetic subtraction in macro)
#   b) RHS ends with . (dot is a macro word-delimiter; "fmt10." splits at "fmt10")
#
# Approach:
#   After the comparison operator (= with no < > ! before it, or a word op
#   with whitespace on BOTH sides), the very next non-space token must be a
#   bare identifier that itself ends with - or . to trigger a hit.
#
#   Word operators (ne eq gt lt ge le) REQUIRE whitespace before AND after to
#   prevent matching "le" inside "%length", "%else", etc.

# The match region is bounded to the %if condition (before %then) by the
# negative lookahead (?!%then\b) on each character of the lazy match.
# This prevents the regex from sliding past %then and matching = in %let.
_IF_UNQUOTED = re.compile(
    r'%if\b'
    r'(?:(?!%then\b)[^\n;])*?'    # condition region: stops before %then
    r'(?:'
        # bare = not part of <=, >=, !=, ==
        r'(?<![<>!=])=(?!=)'
        r'|'
        # word operator surrounded by whitespace (prevents "le" in "%length")
        r'(?<=\s)(?:ne|eq|gt|lt|ge|le)(?=\s)'
    r')'
    r'\s*'
    # RHS must not be a macro escape, a quoted string, a macro var (&), or a digit
    r'(?!%str\s*\()(?!%bquote\s*\()(?!%eval\s*\()(?!%sysfunc\s*\()'
    r'(?![\'"])(?!&)(?!\d)'
    # The bare identifier itself must contain - or end with .
    r'[A-Za-z_]\w*[-.]',
    CI,
)

def check_if_unquoted_special(path, lines):
    hits = []
    for i, raw in enumerate(lines, 1):
        if re.search(_IF_UNQUOTED, raw):
            hits.append((path, i, 'C5',
                '%if comparison RHS is a bare identifier containing - or . '
                '(hyphen = arithmetic; trailing dot = macro word-delimiter) -- '
                'wrap in %str() or %bquote()'))
    return hits


# ── C6: ORDER BY with aggregate function ──────────────────────────────────────

_ORDERBY_AGG = re.compile(
    r'\border\s+by\b.*\b(count|sum|avg|mean|min|max)\s*\(', CI)

def check_orderby_aggregate(path, lines):
    hits = []
    for i, raw in enumerate(lines, 1):
        if re.search(_ORDERBY_AGG, raw):
            hits.append((path, i, 'C6',
                'ORDER BY contains an aggregate function -- '
                'use a subquery or a column alias'))
    return hits


# ── C7: fdelete / fexist / fopen with literal string fileref ─────────────────

# Only flag when a macro variable reference (&name) appears inside single
# quotes -- that prevents expansion and passes the literal text to the function.
# fopen('hardcoded_fileref') is correct SAS; fopen('&macro_var') is the bug.
_LITERAL_FILEREF = re.compile(r"\b(fdelete|fexist|fopen)\s*\(\s*'[^']*&", CI)

def check_literal_fileref(path, lines):
    hits = []
    for i, raw in enumerate(lines, 1):
        if re.search(_LITERAL_FILEREF, raw):
            hits.append((path, i, 'C7',
                'fdelete/fexist/fopen uses a string literal as the fileref name -- '
                'assign with FILENAME first and pass the fileref name variable'))
    return hits


# ── C8: prxmatch with $ anchor, variable not in strip() ──────────────────────
#
# Implemented as explicit parsing (not a pure regex) to avoid lookbehind
# false-positives: the pattern must contain $, and the second argument must
# NOT be wrapped in strip().

def _find_closing_quote(s, quote_char, start):
    """Return index of the next unescaped quote_char in s starting at start."""
    i = start
    while i < len(s):
        if s[i] == quote_char:
            return i
        i += 1
    return -1

def check_prxmatch_dollar_no_strip(path, lines):
    hits = []
    for i, raw in enumerate(lines, 1):
        for m in re.finditer(r'prxmatch\s*\(', raw, CI):
            rest = raw[m.end():]
            # Find the opening quote of the regex pattern
            qm = re.match(r'\s*([\'"])', rest)
            if not qm:
                continue
            qchar = qm.group(1)
            pat_start = qm.end()
            pat_end = _find_closing_quote(rest, qchar, pat_start)
            if pat_end < 0:
                continue
            pattern_text = rest[pat_start:pat_end]
            # Only care if the pattern contains a $ anchor
            if '$' not in pattern_text:
                continue
            # Find the comma separating pattern from the variable
            after_pat = rest[pat_end + 1:]
            cm = re.match(r'\s*,\s*', after_pat)
            if not cm:
                continue
            second_arg = after_pat[cm.end():]
            # Hit if the second argument does NOT begin with strip(
            if not re.match(r'strip\s*\(', second_arg, CI):
                hits.append((path, i, 'C8',
                    'prxmatch with $ anchor: variable not wrapped in strip() -- '
                    'trailing spaces in fixed-length char vars prevent $ from matching'))
    return hits


# ── W1: PROC SQL INTO without &sqlrc check after QUIT ─────────────────────────
#
# Warning: a PROC SQL block that populates macro variables via INTO but is not
# followed by a &sqlrc / sqlrc check within 10 lines of QUIT.  A SQL error puts
# SAS into syntax-check mode; populated macro vars may be empty or stale, and
# subsequent %fail_out / %if guards that rely on them will behave incorrectly.
#
# Kept at warning level (W1) because legitimate PROC SQL may omit &sqlrc when
# the surrounding %macro already guards on &syserr or when the INTO result is
# not relied upon for flow control.

def check_sql_no_sqlrc(path, lines):
    hits = []
    in_sql = False
    has_into = False

    for i, raw in enumerate(lines):
        if re.search(r'\bPROC\s+SQL\b', raw, CI):
            in_sql = True
            has_into = False
        if in_sql and re.search(r'\bINTO\s*:', raw, CI):
            has_into = True
        if in_sql and re.search(r'^\s*QUIT\s*;', raw, CI):
            in_sql = False
            if has_into:
                window = lines[i + 1 : i + 11]
                if not any(re.search(r'sqlrc|sqlobs', l, CI) for l in window):
                    hits.append((path, i + 1, 'W1',
                        'PROC SQL INTO: result used without &sqlrc check after QUIT '
                        '-- verify query succeeded before using populated macro vars'))
        # A new DATA or non-SQL PROC step also ends the SQL context
        if in_sql \
                and re.match(r'^\s*(DATA|PROC)\s+\w', raw, CI) \
                and not re.search(r'\bPROC\s+SQL\b', raw, CI):
            in_sql = False

    return hits


# ── C9: LIBNAME engine after path ────────────────────────────────────────────
#
# Correct: LIBNAME libref <engine> "path";
# Wrong:   LIBNAME libref "path" <engine>;
#
# The pattern matches: libname <word> "<anything>" <word-identifier>;
# where the token after the closing quote is a bare word (the misplaced engine).
# Excludes the %sysfunc(libname(...)) function form and comments.

_LIBNAME_ENGINE_AFTER_PATH = re.compile(
    r'^\s*libname\s+\w+\s+'   # LIBNAME libref
    r'(?:&[\w.]+\s+)?'         # optional macro-var prefix (not the path itself)
    r'["\']'                   # opening quote of path
    r'[^"\']*'                 # path contents
    r'["\']'                   # closing quote
    r'\s+\w+\s*;',             # bare word (engine) then semicolon
    CI,
)

def check_libname_engine_after_path(path, lines):
    hits = []
    for i, raw in enumerate(lines, 1):
        if re.search(_LIBNAME_ENGINE_AFTER_PATH, raw):
            hits.append((path, i, 'C9',
                'LIBNAME engine placed after the path string -- '
                'correct syntax: LIBNAME libref <engine> "path";'))
    return hits


# ── C10: array _character_/_numeric_ before SET/MERGE/INPUT ──────────────────
#
# In a DATA step, _character_ and _numeric_ are bound at compile time to the
# variables already on the PDV when the array statement is processed.  If the
# array appears before the SET/MERGE/INPUT that reads the source dataset, the
# array captures only variables declared by preceding LENGTH/ATTRIB/RETAIN
# statements -- not the dataset columns the programmer intended.
# Fix: move the SET/MERGE/INPUT statement above the array declaration.

_W2_KEYWORDS = frozenset(
    'and or not in is null missing between like ne eq gt lt ge le then do end '
    'as from where select inner join on group by order having distinct count sum '
    'max min avg case when else into trimmed strip upcase cats compress input put '
    'prxmatch index lengthn substr scan trim left right coalesce best32'.split()
)

def check_assert_query_columns(path, lines):
    """W2: Report dataset name and WHERE columns in assert-style count(*) INTO queries."""
    hits = []
    in_sql = False
    sql_lines = []
    is_count_into = False

    for i, raw in enumerate(lines, 1):
        if re.search(r'\bPROC\s+SQL\b', raw, CI):
            in_sql = True
            sql_lines = []
            is_count_into = False
        if in_sql:
            sql_lines.append(raw)
            if re.search(r'\bcount\s*\(\s*\*\s*\)\s+into\s+:', raw, CI):
                is_count_into = True
        if in_sql and re.search(r'^\s*QUIT\s*;', raw, CI):
            if is_count_into:
                sql_text = ' '.join(sql_lines)
                # Extract dataset name(s) from FROM clause
                ds_match = re.search(r'\bfrom\s+([\w.]+)', sql_text, CI)
                ds_name = ds_match.group(1) if ds_match else '?'
                # Extract column tokens from WHERE clause
                where_match = re.search(r'\bwhere\b(.*?)(?:;|$)', sql_text, CI)
                cols = []
                if where_match:
                    clause = where_match.group(1)
                    # Strip quoted strings and regex literals before token extraction
                    clause = re.sub(r"'[^']*'", '', clause)
                    clause = re.sub(r'"[^"]*"', '', clause)
                    clause = re.sub(r'/[^/]*/', '', clause)
                    tokens = re.findall(r'\b([a-z_]\w*)\b(?!\s*\()', clause, CI)
                    seen = set()
                    for t in tokens:
                        tl = t.lower()
                        if (tl not in _W2_KEYWORDS and not t[0].isdigit()
                                and len(t) > 1 and tl not in seen):
                            seen.add(tl)
                            cols.append(t)
                col_str = ', '.join(cols) if cols else '(none extracted)'
                hits.append((path, i, 'W2',
                    f'assert count query on {ds_name} -- WHERE columns: {col_str}'))
            in_sql = False
            sql_lines = []
            is_count_into = False
    return hits


# ── C11: macro keyword inside quoted string on a PUT line ─────────────────────
#
# Detects `put '... %if ...'` or `put "... %let ..."` patterns.
# In a DATA step FILE context this writes macro code literally; the macro
# processor does NOT execute it.  Flag so reviewers confirm the intent.

_MACRO_KWD_IN_PUTSTR = re.compile(
    r'\bput\b'
    r'[^;]*'
    r'(?:'
        r"'[^']*%(?:if|else|do|end|let|macro|mend|abort)\b"
        r'|'
        r'"[^"]*%(?:if|else|do|end|let|macro|mend|abort)\b'
    r')',
    CI,
)

def check_macro_in_put(path, lines):
    hits = []
    for i, raw in enumerate(lines, 1):
        if re.search(_MACRO_KWD_IN_PUTSTR, raw):
            hits.append((path, i, 'C11',
                'macro keyword inside a quoted string on a PUT line -- '
                'the macro is NOT executed; confirm this is intentional code generation'))
    return hits


# ── C13: macro called before definition (same file) ──────────────────────────
#
# Only flags macros whose %macro definition appears later in the same file.
# Macros defined in %included files are not reported (would require cross-file
# analysis).

_C13_BUILTIN = frozenset("""
abort bquote copy display do else end eval global goto if include input left
length let local lowcase macro mend nrbquote nrquote nrstr put qscan qsubstr
qsysfunc qupcase quote resolve return run scan str substr superq syscall
sysevalf sysfunc sysget sysmacdelete sysmacexist sysmaclist trim unquote
upcase verify window
""".split())

def check_call_before_define(path, lines):
    definition_lines = {}
    for i, raw in enumerate(lines, 1):
        for m in re.finditer(r'%macro\s+(\w+)', raw, CI):
            name = m.group(1).lower()
            if name not in definition_lines:
                definition_lines[name] = i

    hits = []
    for i, raw in enumerate(lines, 1):
        for m in re.finditer(r'%(\w+)\s*(?:\(|;)', raw, CI):
            name = m.group(1).lower()
            if name in _C13_BUILTIN:
                continue
            defn_line = definition_lines.get(name)
            if defn_line is not None and defn_line > i:
                hits.append((path, i, 'C13',
                    f'%{name} called before its %macro definition '
                    f'(defined at line {defn_line})'))
    return hits


# ── C14: bare DATA or SET with no dataset name ────────────────────────────────
#
# Catches `data ;` / `set ;` emitted by a broken code generator where the
# dataset-name macro variable resolved to blank.

_BARE_DATA_SET = re.compile(r'^\s*(data|set)\s*;', CI)

def check_bare_data_set(path, lines):
    hits = []
    for i, raw in enumerate(lines, 1):
        if re.search(_BARE_DATA_SET, raw):
            kw = raw.strip().split()[0].upper()
            hits.append((path, i, 'C14',
                f'{kw} statement has no dataset name -- '
                'the dataset-name macro variable likely resolved to blank'))
    return hits


def check_array_special_before_set(path, lines):
    hits = []
    in_data = False
    seen_io = False
    for i, raw in enumerate(lines, 1):
        stripped = raw.strip()
        if re.match(r'\bdata\s+\S', stripped, CI) and not re.search(r'\bproc\s+sql\b', stripped, CI):
            in_data = True
            seen_io = False
        if in_data and re.match(r'run\s*;', stripped, CI):
            in_data = False
            seen_io = False
        if in_data and re.match(r'(set|merge|input)\b', stripped, CI):
            seen_io = True
        if in_data and not seen_io \
                and re.search(r'\barray\b[^;]*\b_(character|numeric)_\b', raw, CI):
            hits.append((path, i, 'C10',
                'array _character_/_numeric_ declared before SET/MERGE/INPUT -- '
                'the array captures only pre-declared PDV vars, not the source dataset columns; '
                'move SET/MERGE/INPUT above the array declaration'))
    return hits


# ── runner ────────────────────────────────────────────────────────────────────

CHECKS = [
    check_qq_in_sql,
    check_ansi_sql,
    check_opencode_if,
    check_then_double_semi,
    check_if_unquoted_special,
    check_orderby_aggregate,
    check_literal_fileref,
    check_prxmatch_dollar_no_strip,
    check_sql_no_sqlrc,
    check_libname_engine_after_path,
    check_array_special_before_set,
    check_macro_in_put,
    check_call_before_define,
    check_bare_data_set,
    check_assert_query_columns,
]


def lint_file(path):
    with open(path, encoding='utf-8', errors='replace') as fh:
        raw_text = fh.read()
    clean = strip_block_comments(raw_text)
    lines = clean.split('\n')
    hits = []
    for chk in CHECKS:
        hits.extend(chk(path, lines))
    return hits


def main(argv):
    if len(argv) < 2:
        print('Usage: python tools/sas_lint.py <file> [<file> ...]', file=sys.stderr)
        sys.exit(1)

    paths = []
    for arg in argv[1:]:
        expanded = _glob.glob(arg)
        paths.extend(expanded if expanded else [arg])

    all_hits = []
    for path in sorted(set(paths)):
        all_hits.extend(lint_file(path))

    errors   = [h for h in all_hits if not h[2].startswith('W')]
    warnings = [h for h in all_hits if h[2].startswith('W')]

    for path, lineno, code, msg in sorted(all_hits, key=lambda h: (h[0], h[1])):
        prefix = 'warning' if code.startswith('W') else 'error'
        print(f'{path}:{lineno}: [{code}] {prefix}: {msg}')

    if errors:
        print(f'\n{len(errors)} error(s), {len(warnings)} warning(s).', file=sys.stderr)
        sys.exit(1)
    elif warnings:
        print(f'\nsas_lint: {len(warnings)} warning(s). (clean -- no errors)', file=sys.stderr)
        sys.exit(0)
    else:
        print('sas_lint: clean.', file=sys.stderr)
        sys.exit(0)


if __name__ == '__main__':
    main(sys.argv)
