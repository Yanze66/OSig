#!/usr/bin/env python3
"""Generate the Vivado Tcl that packages hpu_mini as a user-managed Vitis RTL kernel (.xo).
Same file selection as the OOC synthesis (patched wrappers, pem1_glwe1_bsk4_ksk4, bpbs8_tpbs16)."""
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
    for a, b in SWAPS: name = name.replace(a, b)
    if name.endswith('top_defines_inc.sv'): continue
    if name.endswith('/pe_pbs/rtl/pe_pbs.sv'): name = str(HERE/'rtl/patched/pe_pbs.sv')
    if name.endswith('/pe_pbs/rtl/pe_pbs_with_entry_assembly.sv'): name = str(HERE/'rtl/patched/pe_pbs_with_entry_assembly.sv')
    files.append({'name': name, 'inc': e.get('is_include_file', False)})
files.append({'name': str(HERE/'rtl/top_defines_inc.sv'), 'inc': True})
files.append({'name': str(HERE/'rtl/hpu_mini.sv'), 'inc': False})
files.append({'name': str(HERE/'rtl/hpu_mini_krnl.sv'), 'inc': False})
missing = [f['name'] for f in files if not os.path.isfile(f['name'])]
if missing: raise SystemExit('MISSING: ' + '\n'.join(missing))
inc_dirs = [str(HERE/'rtl'), f'{HW}/module/hpu/rtl/inc',
    f'{HW}/module/number_theoretic_transform/module/ntt_core_common/rtl/inc',
    f'{HW}/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/inc',
    f'{HW}/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/inc']
build = HERE/'build_kernel'
regs = [('MAGIC',0x00,'read-only'),('VERSION',0x04,'read-only'),('STATUS',0x0C,'read-only'),
        ('ISSUED',0x10,'read-only'),('ACK_TOTAL',0x14,'read-only'),('DOP_PUSH',0x18,'write-only'),('ERROR',0x1C,'read-write'),
        ('CT_ADDR_LO',0x20,'read-write'),('CT_ADDR_HI',0x24,'read-write'),('GLWE_ADDR_LO',0x30,'read-write'),('GLWE_ADDR_HI',0x34,'read-write'),
        ('BPIP_CTRL',0x38,'read-write'),('BPIP_TIMEOUT',0x3C,'read-write')]
for i in range(4):
    regs += [(f'BSK{i}_ADDR_LO',0x40+8*i,'read-write'),(f'BSK{i}_ADDR_HI',0x44+8*i,'read-write')]
for i in range(4):
    regs += [(f'KSK{i}_ADDR_LO',0x60+8*i,'read-write'),(f'KSK{i}_ADDR_HI',0x64+8*i,'read-write')]
regs += [('KEY_CTRL',0x80,'read-write'),('KEY_STATUS',0x84,'read-only'),('PEM_LD_ACK',0x90,'read-only'),('PEM_ST_ACK',0x94,'read-only'),
         ('PEA_ACK',0x98,'read-only'),('PEP_ACK',0x9C,'read-only'),('LOCAL_ACK',0xA0,'read-only'),('LAST_PBS_CYCLES',0xA8,'read-only'),
         ('CYCLE_LO',0xB0,'read-only'),('CYCLE_HI',0xB4,'read-only')]
t = []
t.append(f'create_project -force hpu_mini_pkg {build}/vivado_ip -part xcvc1902-vsva2197-2MP-e-S')
t.append('set_property target_language Verilog [current_project]')
t.append('set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY XPM_FIFO} [current_project]')
t.append('add_files -norecurse [list \\'); t += ['    {%s} \\' % f['name'] for f in files]; t.append(']')
for f in files:
    t.append('set_property file_type {%s} [get_files {%s}]' % ('Verilog Header' if f['inc'] else 'SystemVerilog', f['name']))
    if f['inc']:
        t.append('set_property is_global_include true [get_files {%s}]' % f['name'])
t.append('set_property include_dirs [list %s] [get_filesets sources_1]' % ' '.join('{%s}' % d for d in inc_dirs))
t.append('set_property top hpu_mini_krnl [get_filesets sources_1]')
t.append('update_compile_order -fileset sources_1')
t.append(f'ipx::package_project -root_dir {build}/packaged_ip -vendor local.osig -library hpu -taxonomy /UserIP -import_files -set_current true')
t.append('set core [ipx::current_core]')
t.append('set_property name hpu_mini_krnl $core')
t.append('set_property display_name {HPU mini KS+PBS core} $core')
t.append('set_property description {Zama HPU KS+PBS processing element with regfile/pe_mem/pe_alu, user-managed control} $core')
t.append('set_property sdx_kernel true $core')
t.append('set_property sdx_kernel_type rtl $core')
t.append('set bus [ipx::get_bus_interfaces s_axi_control -of_objects $core]')
t.append('if {[llength $bus] != 1} {error {AXI-Lite control inference failed}}')
t.append('set_property name S_AXI_CONTROL $bus')
t.append('foreach b [ipx::get_bus_interfaces -of_objects $core] { set nm [get_property name $b]; if {[string match -nocase {m_axi_*} $nm] || $nm eq {S_AXI_CONTROL}} { ipx::associate_bus_interfaces -busif $nm -clock ap_clk $core } }')
t.append('puts "BUS_IFS: [get_property name [ipx::get_bus_interfaces -of_objects $core]]"')
# explicit 64-bit address spaces for every AXI master (read-only ones get none by inference)
t.append('foreach b [ipx::get_bus_interfaces -of_objects $core] { set nm [get_property name $b]; if {[string match -nocase {m_axi_*} $nm]} { set as [ipx::get_address_spaces $nm -of_objects $core]; if {[llength $as] == 0} { set as [ipx::add_address_space $nm $core] }; set_property width 64 $as; set_property range 18446744073709551616 $as; set_property master_address_space_ref $nm $b } }')
t.append('set rst [ipx::get_bus_parameters POLARITY -of_objects [ipx::get_bus_interfaces ap_rst_n -of_objects $core]]')
t.append('if {[llength $rst] > 0} {set_property value ACTIVE_LOW $rst}')
t.append('set clk [ipx::get_bus_interfaces ap_clk -of_objects $core]')
t.append('set fp [ipx::get_bus_parameters FREQ_HZ -of_objects $clk]; if {[llength $fp] == 0} {set fp [ipx::add_bus_parameter FREQ_HZ $clk]}; set_property value 100000000 $fp')
t.append('set ar [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects $clk]; if {[llength $ar] == 0} {set ar [ipx::add_bus_parameter ASSOCIATED_RESET $clk]}; set_property value ap_rst_n $ar')
t.append('foreach m [ipx::get_memory_maps -of_objects $core] {ipx::remove_memory_map [get_property name $m] $core}')
t.append('set mm [ipx::add_memory_map S_AXI_CONTROL $core]; set ab [ipx::add_address_block regs $mm]')
t.append('set_property base_address 0 $ab; set_property range 4096 $ab; set_property width 32 $ab; set_property usage register $ab')
t.append('set_property slave_memory_map_ref S_AXI_CONTROL [ipx::get_bus_interfaces S_AXI_CONTROL -of_objects $core]')
for name, off, acc in regs:
    t.append(f'set reg [ipx::add_register {name} $ab]; set_property address_offset {off} $reg; set_property size 32 $reg; set_property access {acc} $reg')
t.append('set_property supported_families {versal Production} $core')
t.append('ipx::create_xgui_files $core; ipx::update_checksums $core; ipx::check_integrity -kernel $core; ipx::save_core $core')
t.append(f'package_xo -force -xo_path {build}/hpu_mini.xo -kernel_name hpu_mini_krnl -ctrl_protocol user_managed -ip_directory {build}/packaged_ip -output_kernel_xml {build}/kernel.xml')
t.append(f'puts "XO_READY: {build}/hpu_mini.xo"')
t.append('close_project')
out = HERE/'scripts'/'package_xo.tcl'
out.write_text('\n'.join(t) + '\n'); print('wrote', out, len(files), 'files')
