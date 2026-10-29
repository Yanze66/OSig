#!/usr/bin/env python3
"""Generate a standalone Vivado batch Tcl for hpu_mini OOC synthesis.
Reuses the file selection from the earlier hpu_3parts OOC run, swapping:
  TOP_PC/TOP_PCMAX pem2_glwe1_bsk16_ksk16 -> pem1_glwe1_bsk4_ksk4
  PEP_BATCH bpbs9_tpbs27 -> bpbs8_tpbs16
and adding rtl/hpu_mini.sv as the new top."""
import json, os
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
OLD = Path('/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/hpu_vck190_ooc')
HW = '/home/yzwu/Desktop/hpu_fpga-main/hw'

SWAPS = [
    ('TOP_PC/TOP_PC_pem2_glwe1_bsk16_ksk16/', 'TOP_PC/TOP_PC_pem1_glwe1_bsk4_ksk4/'),
    ('TOP_PCMAX/TOP_PCMAX_pem2_glwe1_bsk16_ksk16/', 'TOP_PCMAX/TOP_PCMAX_pem1_glwe1_bsk4_ksk4/'),
    ('PEP_BATCH/PEP_BATCH_bpbs9_tpbs27/', 'PEP_BATCH/PEP_BATCH_bpbs8_tpbs16/'),
]

sel = json.load(open(OLD / 'selected_files.json'))
entries = sel['files'] if isinstance(sel, dict) and 'files' in sel else sel

files = []
for e in entries:
    name = e['name']
    for a, b in SWAPS:
        if a in name:
            name = name.replace(a, b)
    if name.endswith('top_defines_inc.sv'):
        continue  # replaced by our own copy
    if name.endswith('/pe_pbs/rtl/pe_pbs.sv'):
        name = str(HERE / 'rtl' / 'patched' / 'pe_pbs.sv')  # patched monolithic assembly
    if name.endswith('/pe_pbs/rtl/pe_pbs_with_entry_assembly.sv'):
        name = str(HERE / 'rtl' / 'patched' / 'pe_pbs_with_entry_assembly.sv')
    files.append({'name': name, 'inc': e.get('is_include_file', False)})

# our additions
files.append({'name': str(HERE / 'rtl' / 'top_defines_inc.sv'), 'inc': True})
files.append({'name': str(HERE / 'rtl' / 'hpu_mini.sv'), 'inc': False})

missing = [f['name'] for f in files if not os.path.isfile(f['name'])]
if missing:
    raise SystemExit('MISSING FILES:\n' + '\n'.join(missing))

inc_dirs = [
    str(HERE / 'rtl'),
    f'{HW}/module/hpu/rtl/inc',
    f'{HW}/module/number_theoretic_transform/module/ntt_core_common/rtl/inc',
    f'{HW}/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/inc',
    f'{HW}/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/inc',
]

build = HERE / 'build'
tcl = []
tcl.append(f'create_project hpu_mini_ooc {build}/hpu_mini_ooc -part xcvc1902-vsva2197-2MP-e-S -force')
tcl.append('set_property target_language Verilog [current_project]')
tcl.append('set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY XPM_FIFO} [current_project]')
tcl.append('add_files -norecurse [list \\')
for f in files:
    tcl.append('    {%s} \\' % f['name'])
tcl.append(']')
for f in files:
    ftype = 'Verilog Header' if f['inc'] else 'SystemVerilog'
    tcl.append('set_property file_type {%s} [get_files {%s}]' % (ftype, f['name']))
tcl.append('set_property include_dirs [list %s] [get_filesets sources_1]' %
           ' '.join('{%s}' % d for d in inc_dirs))
tcl.append('set_property top hpu_mini [get_filesets sources_1]')
tcl.append(f'add_files -fileset constrs_1 -norecurse {{{HERE}/scripts/hpu_mini_ooc_clocks.xdc}}')
tcl.append(f'set_property used_in_implementation false [get_files {{{HERE}/scripts/hpu_mini_ooc_clocks.xdc}}]')
tcl.append('set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]')
tcl.append('set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]')
tcl.append('update_compile_order -fileset sources_1')
tcl.append('launch_runs synth_1 -jobs 16')
tcl.append('wait_on_run synth_1')
tcl.append('if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {error "SYNTH FAILED"}')
tcl.append('open_run synth_1')
tcl.append(f'report_utilization -file {build}/hpu_mini_utilization.rpt')
tcl.append(f'report_utilization -hierarchical -hierarchical_depth 4 -file {build}/hpu_mini_hier.rpt')
tcl.append(f'report_timing_summary -file {build}/hpu_mini_timing.rpt')
tcl.append('puts "HPU_MINI_OOC_DONE"')

out = HERE / 'scripts' / 'import_hpu_mini_ooc.tcl'
out.write_text('\n'.join(tcl) + '\n')
print('wrote', out, len(files), 'files')
