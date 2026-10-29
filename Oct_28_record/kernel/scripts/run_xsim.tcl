# Batch XSim run of tb_hpu_mini inside the existing hpu_mini_ooc project.
open_project /home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/build/hpu_mini_ooc/hpu_mini_ooc.xpr

set sim_files [list \
  /home/yzwu/Desktop/hpu_fpga-main/hw/simu_lib/axi4_lib/rtl/axi4_ram.sv \
  /home/yzwu/Desktop/hpu_fpga-main/hw/simu_lib/axi4_lib/rtl/axi4_mem.sv \
  /home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/tb_hpu_mini.sv \
]
foreach f $sim_files {
  if {[llength [get_files -quiet -of_objects [get_filesets sim_1] $f]] == 0} {
    add_files -fileset sim_1 -norecurse $f
  }
  set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1] $f]
}
set inc_dirs [get_property include_dirs [get_filesets sources_1]]
lappend inc_dirs /home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_barrett/rtl/coverage
set_property include_dirs $inc_dirs [get_filesets sim_1]
set_property verilog_define [list DEF_INIT_RAM=1 TB_GOLDEN_DIR=\"/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/mockup_run/ucode\" TB_DATA_DIR=\"/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/keys_flat\"] [get_filesets sim_1]
set_property top tb_hpu_mini [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]
if {[info exists ::env(TB_PLUSARGS)]} {
  set_property -name {xsim.simulate.xsim.more_options} -value "-testplusarg $::env(TB_PLUSARGS)" -objects [get_filesets sim_1]
}
launch_simulation
puts "XSIM_LAUNCH_RETURNED"
close_sim -quiet
puts "XSIM_DONE"
