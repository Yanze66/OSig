#!/usr/bin/env python3
"""Generate a complete build flow for one hpu_mini batch configuration.

  gen_cfg_flow.py --cfg b16 --pep-batch PEP_BATCH_bpbs16_tpbs32 [--freq 200000000] [--period 5.0]

Writes scripts/cfg_<cfg>/{import_ooc.tcl, import_sim.tcl, package_xo.tcl, link.cfg, clocks.xdc, build_kernel.sh}
Build outputs go to build_<cfg>/ (OOC synth), build_<cfg>/sim (XSim project) and build_kernel_<cfg>/ (xo/xsa/xclbin).
Same file selection as gen_import_tcl.py / gen_package_tcl.py (patched wrappers, pem1_glwe1_bsk4_ksk4),
only the PEP_BATCH directory changes. FREQ_HZ of the packaged kernel is set directly (no xo patch needed).
"""
import argparse, json, os
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
OLD = Path('/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/hpu_vck190_ooc')
HW = '/home/yzwu/Desktop/hpu_fpga-main/hw'
PART = 'xcvc1902-vsva2197-2MP-e-S'

ap = argparse.ArgumentParser()
ap.add_argument('--cfg', required=True, help='short name, e.g. b16')
ap.add_argument('--pep-batch', required=True, help='e.g. PEP_BATCH_bpbs16_tpbs32')
ap.add_argument('--freq', type=int, default=200000000)
ap.add_argument('--period', type=float, default=5.0, help='OOC clock period (ns)')
a = ap.parse_args()

batch_dir = Path(HW) / 'module/pe_pbs/module/pep_common/rtl/PEP_BATCH' / a.pep_batch
if not batch_dir.is_dir():
    batch_dir = HERE / 'rtl/pep_batch' / a.pep_batch   # configs generated outside the repo
if not (batch_dir / 'pep_batch_definition_pkg.sv').is_file():
    raise SystemExit(f'no such batch config: {a.pep_batch}')

SWAPS = [
    ('TOP_PC/TOP_PC_pem2_glwe1_bsk16_ksk16/', 'TOP_PC/TOP_PC_pem1_glwe1_bsk4_ksk4/'),
    ('TOP_PCMAX/TOP_PCMAX_pem2_glwe1_bsk16_ksk16/', 'TOP_PCMAX/TOP_PCMAX_pem1_glwe1_bsk4_ksk4/'),
    ('PEP_BATCH/PEP_BATCH_bpbs9_tpbs27/', f'PEP_BATCH/{a.pep_batch}/'),
]
sel = json.load(open(OLD / 'selected_files.json'))
entries = sel['files'] if isinstance(sel, dict) and 'files' in sel else sel
files = []
for e in entries:
    name = e['name']
    for x, y in SWAPS:
        name = name.replace(x, y)
    if name.endswith('top_defines_inc.sv'):
        continue
    if '/PEP_BATCH/' in name:
        name = str(batch_dir / 'pep_batch_definition_pkg.sv')
    if name.endswith('/pe_pbs/rtl/pe_pbs.sv'):
        name = str(HERE / 'rtl/patched/pe_pbs.sv')
    if name.endswith('/pe_pbs/rtl/pe_pbs_with_entry_assembly.sv'):
        name = str(HERE / 'rtl/patched/pe_pbs_with_entry_assembly.sv')
    files.append({'name': name, 'inc': e.get('is_include_file', False)})
files.append({'name': str(HERE / 'rtl/top_defines_inc.sv'), 'inc': True})
files.append({'name': str(HERE / 'rtl/hpu_mini.sv'), 'inc': False})
krnl = {'name': str(HERE / 'rtl/hpu_mini_krnl.sv'), 'inc': False}
missing = [f['name'] for f in files + [krnl] if not os.path.isfile(f['name'])]
if missing:
    raise SystemExit('MISSING:\n' + '\n'.join(missing))
assert any(a.pep_batch in f['name'] for f in files), 'batch pkg not in file list'

inc_dirs = [str(HERE / 'rtl'), f'{HW}/module/hpu/rtl/inc',
            f'{HW}/module/number_theoretic_transform/module/ntt_core_common/rtl/inc',
            f'{HW}/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/inc',
            f'{HW}/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/inc']

out = HERE / 'scripts' / f'cfg_{a.cfg}'
out.mkdir(parents=True, exist_ok=True)
build = HERE / f'build_{a.cfg}'
kbuild = HERE / f'build_kernel_{a.cfg}'


def add_files(t, flist, global_inc=False):
    t.append('add_files -norecurse [list \\')
    t += ['    {%s} \\' % f['name'] for f in flist]
    t.append(']')
    for f in flist:
        t.append('set_property file_type {%s} [get_files {%s}]' % ('Verilog Header' if f['inc'] else 'SystemVerilog', f['name']))
        if f['inc'] and global_inc:
            t.append('set_property is_global_include true [get_files {%s}]' % f['name'])
    t.append('set_property include_dirs [list %s] [get_filesets sources_1]' % ' '.join('{%s}' % d for d in inc_dirs))


# ---- clocks.xdc
(out / 'clocks.xdc').write_text(f'# OOC clock for hpu_mini {a.cfg} ({1e3/a.period:.0f} MHz)\n'
                                f'create_clock -name ap_clk -period {a.period:.3f} [get_ports ap_clk]\n')

# ---- import_ooc.tcl : OOC synthesis + reports
t = [f'create_project hpu_mini_ooc {build}/hpu_mini_ooc -part {PART} -force',
     'set_property target_language Verilog [current_project]',
     'set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY XPM_FIFO} [current_project]']
add_files(t, files)
t += ['set_property top hpu_mini [get_filesets sources_1]',
      f'add_files -fileset constrs_1 -norecurse {{{out}/clocks.xdc}}',
      f'set_property used_in_implementation false [get_files {{{out}/clocks.xdc}}]',
      'set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]',
      'set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]',
      'update_compile_order -fileset sources_1',
      'launch_runs synth_1 -jobs 16', 'wait_on_run synth_1',
      'if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {error "SYNTH FAILED"}',
      'open_run synth_1',
      f'report_utilization -file {build}/hpu_mini_utilization.rpt',
      f'report_utilization -hierarchical -hierarchical_depth 4 -file {build}/hpu_mini_hier.rpt',
      f'report_timing_summary -file {build}/hpu_mini_timing.rpt',
      'puts "HPU_MINI_OOC_DONE"']
(out / 'import_ooc.tcl').write_text('\n'.join(t) + '\n')

# ---- import_sim.tcl : separate project, tb_hpu_mini XSim (TB_PLUSARGS env, e.g. CASE=4)
sim_files = [f'{HW}/simu_lib/axi4_lib/rtl/axi4_ram.sv', f'{HW}/simu_lib/axi4_lib/rtl/axi4_mem.sv', str(HERE / 'rtl/tb_hpu_mini.sv')]
t = [f'create_project hpu_mini_sim {build}/sim -part {PART} -force',
     'set_property target_language Verilog [current_project]',
     'set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY XPM_FIFO} [current_project]']
add_files(t, files)
t += ['set_property top hpu_mini [get_filesets sources_1]',
      'add_files -fileset sim_1 -norecurse [list %s]' % ' '.join('{%s}' % f for f in sim_files)]
t += ['set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1] {%s}]' % f for f in sim_files]
t += ['set inc_dirs [get_property include_dirs [get_filesets sources_1]]',
      f'lappend inc_dirs {HW}/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_barrett/rtl/coverage',
      'set_property include_dirs $inc_dirs [get_filesets sim_1]',
      f'set_property verilog_define [list DEF_INIT_RAM=1 TB_GOLDEN_DIR=\\"{HERE}/mockup_run/ucode\\" TB_DATA_DIR=\\"{HERE}/keys_flat\\"] [get_filesets sim_1]',
      'set_property top tb_hpu_mini [get_filesets sim_1]',
      'set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]',
      'set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]',
      'if {[info exists ::env(TB_PLUSARGS)]} { set_property -name {xsim.simulate.xsim.more_options} -value "-testplusarg $::env(TB_PLUSARGS)" -objects [get_filesets sim_1] }',
      'update_compile_order -fileset sources_1',
      'launch_simulation', 'puts "XSIM_LAUNCH_RETURNED"', 'close_sim -quiet', 'puts "XSIM_DONE"']
(out / 'import_sim.tcl').write_text('\n'.join(t) + '\n')

# ---- package_xo.tcl : user-managed RTL kernel, FREQ_HZ = freq
regs = [('MAGIC', 0x00, 'read-only'), ('VERSION', 0x04, 'read-only'), ('STATUS', 0x0C, 'read-only'),
        ('ISSUED', 0x10, 'read-only'), ('ACK_TOTAL', 0x14, 'read-only'), ('DOP_PUSH', 0x18, 'write-only'), ('ERROR', 0x1C, 'read-write'),
        ('CT_ADDR_LO', 0x20, 'read-write'), ('CT_ADDR_HI', 0x24, 'read-write'), ('GLWE_ADDR_LO', 0x30, 'read-write'), ('GLWE_ADDR_HI', 0x34, 'read-write'),
        ('BPIP_CTRL', 0x38, 'read-write'), ('BPIP_TIMEOUT', 0x3C, 'read-write')]
for i in range(4):
    regs += [(f'BSK{i}_ADDR_LO', 0x40 + 8 * i, 'read-write'), (f'BSK{i}_ADDR_HI', 0x44 + 8 * i, 'read-write')]
for i in range(4):
    regs += [(f'KSK{i}_ADDR_LO', 0x60 + 8 * i, 'read-write'), (f'KSK{i}_ADDR_HI', 0x64 + 8 * i, 'read-write')]
regs += [('KEY_CTRL', 0x80, 'read-write'), ('KEY_STATUS', 0x84, 'read-only'), ('PEM_LD_ACK', 0x90, 'read-only'), ('PEM_ST_ACK', 0x94, 'read-only'),
         ('PEA_ACK', 0x98, 'read-only'), ('PEP_ACK', 0x9C, 'read-only'), ('LOCAL_ACK', 0xA0, 'read-only'), ('LAST_PBS_CYCLES', 0xA8, 'read-only'),
         ('CYCLE_LO', 0xB0, 'read-only'), ('CYCLE_HI', 0xB4, 'read-only')]
t = [f'create_project -force hpu_mini_pkg {kbuild}/vivado_ip -part {PART}',
     'set_property target_language Verilog [current_project]',
     'set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY XPM_FIFO} [current_project]']
add_files(t, files + [krnl], global_inc=True)
t += ['set_property top hpu_mini_krnl [get_filesets sources_1]', 'update_compile_order -fileset sources_1',
      f'ipx::package_project -root_dir {kbuild}/packaged_ip -vendor local.osig -library hpu -taxonomy /UserIP -import_files -set_current true',
      'set core [ipx::current_core]', 'set_property name hpu_mini_krnl $core',
      'set_property display_name {HPU mini KS+PBS core} $core',
      'set_property description {Zama HPU KS+PBS processing element with regfile/pe_mem/pe_alu, user-managed control} $core',
      'set_property sdx_kernel true $core', 'set_property sdx_kernel_type rtl $core',
      'set bus [ipx::get_bus_interfaces s_axi_control -of_objects $core]',
      'if {[llength $bus] != 1} {error {AXI-Lite control inference failed}}',
      'set_property name S_AXI_CONTROL $bus',
      'foreach b [ipx::get_bus_interfaces -of_objects $core] { set nm [get_property name $b]; if {[string match -nocase {m_axi_*} $nm] || $nm eq {S_AXI_CONTROL}} { ipx::associate_bus_interfaces -busif $nm -clock ap_clk $core } }',
      'foreach b [ipx::get_bus_interfaces -of_objects $core] { set nm [get_property name $b]; if {[string match -nocase {m_axi_*} $nm]} { set as [ipx::get_address_spaces $nm -of_objects $core]; if {[llength $as] == 0} { set as [ipx::add_address_space $nm $core] }; set_property width 64 $as; set_property range 18446744073709551616 $as; set_property master_address_space_ref $nm $b } }',
      'set rst [ipx::get_bus_parameters POLARITY -of_objects [ipx::get_bus_interfaces ap_rst_n -of_objects $core]]',
      'if {[llength $rst] > 0} {set_property value ACTIVE_LOW $rst}',
      'set clk [ipx::get_bus_interfaces ap_clk -of_objects $core]',
      f'set fp [ipx::get_bus_parameters FREQ_HZ -of_objects $clk]; if {{[llength $fp] == 0}} {{set fp [ipx::add_bus_parameter FREQ_HZ $clk]}}; set_property value {a.freq} $fp',
      'set ar [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects $clk]; if {[llength $ar] == 0} {set ar [ipx::add_bus_parameter ASSOCIATED_RESET $clk]}; set_property value ap_rst_n $ar',
      'foreach m [ipx::get_memory_maps -of_objects $core] {ipx::remove_memory_map [get_property name $m] $core}',
      'set mm [ipx::add_memory_map S_AXI_CONTROL $core]; set ab [ipx::add_address_block regs $mm]',
      'set_property base_address 0 $ab; set_property range 4096 $ab; set_property width 32 $ab; set_property usage register $ab',
      'set_property slave_memory_map_ref S_AXI_CONTROL [ipx::get_bus_interfaces S_AXI_CONTROL -of_objects $core]']
for name, off, acc in regs:
    t.append(f'set reg [ipx::add_register {name} $ab]; set_property address_offset {off} $reg; set_property size 32 $reg; set_property access {acc} $reg')
t += ['set_property supported_families {versal Production} $core',
      'ipx::create_xgui_files $core; ipx::update_checksums $core; ipx::check_integrity -kernel $core; ipx::save_core $core',
      # hand-written kernel.xml declares the 10 AXI masters as pointer args so v++ [connectivity] sp= can bind them
      f'package_xo -force -xo_path {kbuild}/hpu_mini.xo -kernel_name hpu_mini_krnl -ctrl_protocol user_managed -ip_directory {kbuild}/packaged_ip -kernel_xml {HERE}/kernel/kernel.xml',
      f'puts "XO_READY: {kbuild}/hpu_mini.xo"', 'close_project']
(out / 'package_xo.tcl').write_text('\n'.join(t) + '\n')

# ---- link.cfg
lk = ['[connectivity]', 'nk=hpu_mini_krnl:1:hpu_mini_1']
lk += [f'sp=hpu_mini_1.m_axi_{p}:DDR' for p in ['pem', 'glwe', 'bsk0', 'bsk1', 'bsk2', 'bsk3', 'ksk0', 'ksk1', 'ksk2', 'ksk3']]
lk += ['', '[clock]', f'freqHz={a.freq}:hpu_mini_1.ap_clk']
(out / 'link.cfg').write_text('\n'.join(lk) + '\n')

# ---- build_kernel.sh : package xo, v++ link, v++ package (xclbin + sd_card with BOOT.BIN)
sh = f'''#!/usr/bin/env bash
# hpu_mini {a.cfg} ({a.pep_batch}, {a.freq/1e6:.0f} MHz): package .xo -> v++ link -> v++ package
set -eo pipefail
ROOT={HERE}
KB={kbuild}
mkdir -p "$KB/link" "$KB/package"
cd "$KB"
if [ ! -f "$KB/hpu_mini.xo" ] || [ "${{FORCE_XO:-0}}" = 1 ]; then
  /tools/Xilinx/2025.1/Vivado/bin/vivado -mode batch -nojournal -log "$KB/package_xo.log" -source "{out}/package_xo.tcl"
  grep -q XO_READY "$KB/package_xo.log"
fi
source /tools/Xilinx/2025.1/Vitis/settings64.sh
PLATFORM=/tools/Xilinx/2025.1/Vitis/base_platforms/xilinx_vck190_base_202510_1/xilinx_vck190_base_202510_1.xpfm
cd "$KB/link"
v++ --link --target hw --platform "$PLATFORM" --config "{out}/link.cfg" --save-temps \\
  "$KB/hpu_mini.xo" -o "$KB/hpu_mini_hw.xsa" 2>&1 | tee "$KB/link.log"
echo "LINK_DONE"
COMMON_IMAGE=${{COMMON_IMAGE:-/home/yzwu/Downloads/xilinx-versal-common-v2025.1_05221048/xilinx-versal-common-v2025.1}}
cd "$KB/package"
v++ --package --target hw --platform "$PLATFORM" \\
 --package.rootfs "$COMMON_IMAGE/rootfs.ext4" --package.kernel_image "$COMMON_IMAGE/Image" \\
 --package.boot_mode sd --package.image_format ext4 \\
 --package.sd_file "$ROOT/build_kernel/hpu_server" --package.sd_file "$ROOT/board/run_server.sh" \\
 "$KB/hpu_mini_hw.xsa" -o hpu_mini_{a.cfg}.xclbin 2>&1 | tee "$KB/package.log"
ls -la "$KB/package/hpu_mini_{a.cfg}.xclbin" "$KB/package/sd_card/BOOT.BIN"
echo "PACKAGE_DONE"
'''
(out / 'build_kernel.sh').write_text(sh)
os.chmod(out / 'build_kernel.sh', 0o755)
print(f'wrote {out}: {len(files)} RTL files, batch={a.pep_batch}, freq={a.freq}, ooc period={a.period} ns')
