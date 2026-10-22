/*==========================================================================
  Program : 05_build_pcnr.sas
  Project : PeCAN Data Dictionary (PDD)
  Purpose : Phase 5 -- Build PCNR_ on the spine.
            Starts from pdd.src_s09 (spine, 41,150 rows), left-joins all
            other 1:1 PRECEDE_STUDY_ID sources using Phase 4 name map,
            applies gap-fill and type resolution, writes pdd.pcnr.

  Reads   : pdd.src_s01..pdd.src_s20 (all sources)
            pdd.name_map_vars (PCNR_ variable roster from Phase 4)
            docs\pcnr_source_priority.csv (D-15 gap-fill rank order)
            docs\pcnr_source_override.csv (D-05b per-variable source pin)

  Writes  : pdd.pcnr (41,150 rows x 1,299 PCNR_ + NORM_PSID)
            pdd.qc_pcnr_conflicts
            exchange\pcnr_gapfill.csv

  PCM compliance:
    C1  No ?? in PROC SQL
    C2  No ANSI SQL (OFFSET/FETCH/LIMIT/ROW_NUMBER OVER/WITH AS)
    C3  No open-code %if/%else outside %macro
    C9  LIBNAME engine before path
    C11 No macro keyword in quoted PUT string
    C13 All macro definitions in Section 0 before first call
    C14 No bare data;/set;

  Author  : GSD Phase 05 Plan 05
==========================================================================*/


/* ============================================================
   SECTION 0 -- %include config, %pdd_lib, macro library
   %include of 05_build_pcnr_macros.sas brings in %fail_out,
   %_p5_ok, %route_log, %restore_log, and all entry-point macros
   before any call (PCM C13).
   ============================================================ */

%include "&sas_path.\00_config.sas";
%pdd_lib;

%include "&sas_path.\05_build_pcnr_macros.sas";


/* ============================================================
   SECTION 1 -- Preflight (D-18 assertion, spine QC, hashes)
   ============================================================ */
%route_log;

%_p5_ok(section=1);
%p5_preflight;


/* ============================================================
   SECTION 2 -- Spine coverage QC (D-19 extended)
   ============================================================ */
%_p5_ok(section=2);
%p5_spine_coverage;


/* ============================================================
   SECTION 3 -- Type-conflict resolution (D-02)
   ============================================================ */
%_p5_ok(section=3);
%p5_resolve_types;


/* ============================================================
   SECTION 4 -- Build accumulator (left-join all sources)
   ============================================================ */
%_p5_ok(section=4);
%p5_build_accumulator;


/* ============================================================
   SECTION 5 -- Gap-fill (D-15 priority order)
   ============================================================ */
%_p5_ok(section=5);
%p5_run_gapfill;


/* ============================================================
   SECTION 6 -- Finalize pdd.pcnr
   ============================================================ */
%_p5_ok(section=6);
%p5_finalize_pcnr;


/* ============================================================
   SECTION 7 -- Write QC datasets / exchange CSV
   ============================================================ */
%_p5_ok(section=7);
%p5_write_qc;


/* ============================================================
   SECTION 8 -- Python QC command (informational -- no shell-out)
   run_pipeline.cmd invokes write_pcnr_qc.py automatically.
   This %put is for operators running 05_build_pcnr.sas standalone.
   ============================================================ */
%put NOTE: [05_build_pcnr] Phase 5 SAS complete. Run Python QC step via run_pipeline.cmd:;
%put NOTE: [05_build_pcnr]   python python\scripts\write_pcnr_qc.py;
%put NOTE: [05_build_pcnr]   Console output: logs\write_pcnr_qc_console.txt;

%restore_log;
