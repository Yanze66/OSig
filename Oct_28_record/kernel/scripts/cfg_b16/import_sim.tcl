create_project hpu_mini_sim /home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/build_b16/sim -part xcvc1902-vsva2197-2MP-e-S -force
set_property target_language Verilog [current_project]
set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY XPM_FIFO} [current_project]
add_files -norecurse [list \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/AXI_DATA_W/AXI_DATA_W_256/axi_if_data_w_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_bsk_axi_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_ksk_axi_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_ct_axi_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_glwe_axi_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_ucore_axi_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_shell_axil_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_trc_axi_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_mhdma_axi_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common_package/rtl/common_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/param/module/param_msg2_carry2_pfail128_132b_tuniform_144a47/rtl/param_tfhe_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/param/rtl/NTT_MOD/NTT_MOD_goldilocks/param_ntt_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/param/rtl/param_tfhe_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/param/rtl/param_ntt_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/module/regf_common/rtl/REGF_STRUCT/REGF_STRUCT_reg64_coef32_seq4/regf_common_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/module/regf_common/rtl/regf_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_common_instruction/rtl/hpu_common_instruction_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/top_common/rtl/TOP_TOP/TOP_TOP_hpu/top_common_top_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/top_common/rtl/TOP_PC/TOP_PC_pem1_glwe1_bsk4_ksk4/top_common_pc_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/top_common/rtl/TOP_PCMAX/TOP_PCMAX_pem1_glwe1_bsk4_ksk4/top_common_pcmax_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/top_common/rtl/top_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_mem/module/pem_common/rtl/pem_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/cdc/module/xpm_cdc_handshake_wrapper/rtl/xpm_cdc_handshake_wrapper.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/cdc/module/xpm_fifo_async_wrapper/rtl/xpm_fifo_async_wrapper.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/cdc/module/xpm_cdc_single_wrapper/rtl/xpm_cdc_single_wrapper.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_wrapper_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_1R1W_behav_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_1R1W_behav.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_wrapper_1R1W.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_2RW_behav_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_2RW_behav.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_wrapper_2RW.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_wrapper_NR1W.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_NR1W_behav.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_NR1W_behav_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_element_type1.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_element_type2.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_element_type3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_element.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_reg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_ram_rdy_vld.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_ram_rdy_vld_2clk.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_delay.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/inc/ntt_core_common_macro_inc.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/NTT_CORE_ARCH/NTT_CORE_ARCH_gf64/ntt_core_common_arch_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/NTT_CORE_R/NTT_CORE_R_2/ntt_core_common_r_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/NTT_CORE_PSI/NTT_CORE_PSI_16/ntt_core_common_psi_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/NTT_CORE_DIV/NTT_CORE_DIV_1/ntt_core_common_div_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/NTT_CORE_RDX_CUT/NTT_CORE_RDX_CUT_n5c5c1/ntt_core_common_cut_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/ntt_core_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/module/bsk_mgr_common/rtl/BSK_SLOT/BSK_SLOT_8/bsk_mgr_common_slot_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/module/bsk_mgr_common/rtl/BSK_CUT/BSK_CUT_16/bsk_mgr_common_cut_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/module/bsk_mgr_common/rtl/bsk_mgr_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_if/module/bsk_if_common/rtl/bsk_if_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_common/rtl/PEP_MSPLIT/PEP_MSPLIT_main2_subs2/pep_msplit_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_common/rtl/PEP_BATCH/PEP_BATCH_bpbs16_tpbs32/pep_batch_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_common/rtl/pep_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_common/rtl/KSLB/KSLB_x2y32z3/pep_ks_common_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_common/rtl/pep_ks_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_alu/module/pea_common/rtl/PEA_ALU/PEA_ALU_1/pea_alu_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_alu/module/pea_common/rtl/pea_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_common/rtl/HPU_PART/HPU_PART_gf64/hpu_part_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_common/rtl/HPU_TWDFILE/HPU_TWDFILE_default/hpu_twdfile_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_common/rtl/hpu_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/module/ksk_mgr_common/rtl/KSK_SLOT/KSK_SLOT_8/ksk_mgr_common_slot_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/module/ksk_mgr_common/rtl/KSK_CUT/KSK_CUT_16/ksk_mgr_common_cut_definition_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/module/ksk_mgr_common/rtl/ksk_mgr_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_common/rtl/ntt_core_gf64_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/instruction_scheduler_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/module/isc_common/rtl/isc_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_cfg_1in3_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_cfg_3in3_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_prc_1in3_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_prc_3in3_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_mhdma_2in3_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_req_ack.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_req_ack_rd.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_error_manager.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_counter_manager.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_cfg_1in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_cfg_3in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_prc_1in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_prc_3in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_cfg_1in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_cfg_3in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_prc_1in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_prc_3in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_mhdma_2in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/multi_hpu_dma.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_bridge.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_decoder.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_formatter.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_master.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_slave.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_nmu_pipe.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/constraint/multi_hpu_dma_timing_constraints_hier.xdc} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/stream_to_pipe/rtl/stream_to_pipe.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_bin_to_one_hot.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_one_hot_to_bin.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_find_first_bit_equal_to_1.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_find_last_bit_equal_to_1.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_delay_side.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_select_from_one_hot.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_pseudo_reverse.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_pseudo_invert.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_pulse_to_rdy_vld.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_count_ones.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/isc_evt.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/isc_ack.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/isc_parser.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/isc_pool.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/isc_query.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/instruction_scheduler.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/trace_manager/rtl/trace_manager.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_core/rtl/arith_mult_core_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_core/rtl/arith_mult_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_core/rtl/arith_mult_core_with_side.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_karatsuba/rtl/arith_mult_karatsuba_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_karatsuba/rtl/arith_mult_karatsuba_cascade_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_karatsuba/rtl/arith_mult_karatsuba.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_karatsuba/rtl/arith_mult_karatsuba_cascade.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_karatsuba/rtl/arith_mult_kara_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_64bgoldilocks_karatsuba/rtl/arith_mult_64bgoldilocks_karatsuba_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_64bgoldilocks_karatsuba/rtl/arith_mult_64bgoldilocks_karatsuba_cascade_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_64bgoldilocks_karatsuba/rtl/arith_mult_64bgoldilocks_karatsuba.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_64bgoldilocks_karatsuba/rtl/arith_mult_64bgoldilocks_karatsuba_cascade.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/rtl/arith_mult_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/rtl/arith_mult.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_alu/rtl/pea_alu_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_alu/rtl/pe_alu.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/stream_to_seq/rtl/stream_to_seq.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/stream_to_seq/rtl/seq_to_stream.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_mem/rtl/pem_load.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_mem/rtl/pem_store.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_mem/rtl/pe_mem.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_mersenne/rtl/arith_mult_cst_mersenne_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_mersenne/rtl/arith_mult_cst_mersenne.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas3/rtl/arith_mult_cst_solinas3_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas3/rtl/arith_mult_cst_solinas3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas2/rtl/arith_mult_cst_solinas2_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas2/rtl/arith_mult_cst_solinas2.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_goldilocks_inv/rtl/arith_mult_cst_goldilocks_inv_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_goldilocks_inv/rtl/arith_mult_cst_goldilocks_inv.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas2_44_14_inv/rtl/arith_mult_cst_solinas2_44_14_inv_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas2_44_14_inv/rtl/arith_mult_cst_solinas2_44_14_inv.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/rtl/arith_mult_constant_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/rtl/arith_mult_constant.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_switch/module/mod_switch_to_2powerN/rtl/mod_switch_to_2powerN_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_switch/module/mod_switch_to_2powerN/rtl/mod_switch_to_2powerN.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_if/rtl/bsk_if_cache_control.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_if/rtl/bsk_if_axi4_read.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_if/rtl/bsk_if.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/rtl/bsk_mgr_node.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/rtl/bsk_mgr_cut.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/rtl/bsk_manager.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/constraint/bsk_manager_timing_constraints_hier.xdc} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_if/module/ksk_if_common/rtl/ksk_if_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_if/rtl/ksk_if_cache_control.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_if/rtl/ksk_if_axi4_read.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_if/rtl/ksk_if.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/rtl/ksk_mgr_node.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/rtl/ksk_manager.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/constraint/ksk_manager_timing_constraints_hier.xdc} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_mult/rtl/pep_ks_mult_node.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_mult/rtl/pep_ks_mult.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_out_process/rtl/pep_ks_out_process.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_control/rtl/pep_ks_ctrl_read.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_control/rtl/pep_ks_ctrl_feed.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_control/rtl/pep_ks_control.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_rd_rdy_vld/rtl/ram_rd_rdy_vld.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/decomposer/module/decomp_parallel/rtl/decomp_parallel.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_blwe_ram/rtl/pep_ks_blram_format.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_blwe_ram/rtl/pep_ks_blram_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_blwe_ram/rtl/pep_ks_blwe_ram.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/rtl/pep_ks_result_format.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/rtl/pep_ks_body_map.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/rtl/pep_key_switch.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_common/rtl/pep_mmacc_common_permutation_vector.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_common/rtl/pep_mmacc_common_param_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_misc/rtl/pep_mmacc_infifo.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_misc/rtl/pep_mmacc_body_ram.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_glwe_ram/rtl/pep_mmacc_gram_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_glwe_ram/rtl/pep_mmacc_glwe_ram.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_gram_arb/rtl/pep_mmacc_gram_arb.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_acc_read.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_acc_write.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_acc_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_main_acc.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_subs_acc.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_acc_assembly.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_read.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_rot.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_join.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_final.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_entry.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_main_feed.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_subs_feed.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/stream_dispatch/rtl/stream_disp_format.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/stream_dispatch/rtl/stream_dispatch.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/inc/pep_mmacc_splitc_sxt_macro_inc.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_sync.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_read.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_rot.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_join.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_final.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_entry.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_main_sxt.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_subs_sxt.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_assembly.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/rtl/pep_mmacc_splitc_main.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/rtl/pep_mmacc_splitc_subsidiary.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/rtl/pep_mmacc_splitc_assembly.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/constraint/pep_mmacc_splitc_timing_constraints_hier.xdc} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/decomposer/module/decomp_balanced_sequential/rtl/decomp_balseq_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/decomposer/module/decomp_balanced_sequential/rtl/decomp_balanced_sequential.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_common/rtl/ntt_core_wmm_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_1R_behav_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_1R_behav.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_2R_behav_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_2R_behav.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_wrapper_1R.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_wrapper_2R.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/twiddle/rtl/twiddle_phi_ru_manager.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/twiddle/rtl/twiddle_intt_final_manager.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_add_sub/rtl/mod_add_sub_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_add_sub/rtl/mod_add.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_add_sub/rtl/mod_sub.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_mersenne/rtl/mod_reduct_mersenne_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_mersenne/rtl/mod_reduct_mersenne.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_barrett/rtl/mod_reduct_barrett_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_barrett/rtl/mod_reduct_barrett.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas2/rtl/mod_reduct_solinas2_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas2/rtl/mod_reduct_solinas2_general.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas2/rtl/mod_reduct_solinas2_half.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas2/rtl/mod_reduct_solinas2.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas3/rtl/mod_reduct_solinas3_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas3/rtl/mod_reduct_solinas3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_64bgoldilocks_karatsuba/rtl/mod_reduct_64bgoldilocks_karatsuba_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_64bgoldilocks_karatsuba/rtl/mod_reduct_64bgoldilocks_karatsuba.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/rtl/mod_reduct_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/rtl/mod_reduct.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_mult/module/mod_mult_with_reduct/rtl/mod_mult_with_reduct.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_mult/rtl/mod_mult_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_mult/rtl/mod_mult.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_radix/module/ntt_radix_cooley_tukey/rtl/ntt_radix_cooley_tukey_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_radix/module/ntt_radix_cooley_tukey/rtl/ntt_radix_ct_mult_butterfly.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_radix/module/ntt_radix_cooley_tukey/rtl/ntt_radix_ct_butterfly.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_radix/module/ntt_radix_cooley_tukey/rtl/ntt_radix_cooley_tukey.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_cluster_butterfly_unit/rtl/ntt_core_wmm_clbu_pcg_pipe.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_cluster_butterfly_unit/rtl/ntt_core_wmm_clbu_pcg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_pcg_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_rd_pcg_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_wr_pcg_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_last_stage_wr_pcg_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_wr_pcg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_last_stage_wr_pcg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_rd_pcg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_infifo/rtl/ntt_core_wmm_infifo.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_ram_rd/rtl/ntt_core_wmm_ram_rd_pcg_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_ram_rd/rtl/ntt_core_wmm_ram_rd_pcg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_network/rtl/ntt_core_wmm_network_pcg_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_network/rtl/ntt_core_wmm_network_pcg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_acc/rtl/mod_acc_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_acc/rtl/mod_acc.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_post_process/rtl/ntt_core_wmm_post_process.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_post_process/rtl/ntt_core_wmm_post_process_wrapper.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_sequencer/rtl/ntt_core_wmm_sequencer.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_with_matrix_multiplication_unfold_pcg/rtl/ntt_core_with_matrix_multiplication_unfold_pcg_head.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_with_matrix_multiplication_unfold_pcg/rtl/ntt_core_with_matrix_multiplication_unfold_pcg_middle_fwd.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_with_matrix_multiplication_unfold_pcg/rtl/ntt_core_with_matrix_multiplication_unfold_pcg_middle_bwd.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_with_matrix_multiplication_unfold_pcg/rtl/ntt_core_with_matrix_multiplication_unfold_pcg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_with_matrix_multiplication_unfold_pcg/rtl/ntt_core_with_matrix_multiplication_unfold_pcg_assembly.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/rtl/ntt_core_with_matrix_multiplication.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/rtl/ntt_core_with_matrix_multiplication_head.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/rtl/ntt_core_with_matrix_multiplication_middle.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_add.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_sub.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_shift_cst.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_shift.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_sign.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_reduction.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_sign_reduction.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_mult.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_acc.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_butterfly_unit/rtl/ntt_core_gf64_bu_cooley_tukey.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_butterfly_unit/rtl/ntt_core_gf64_bu_gentleman_sande.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_butterfly_unit/rtl/ntt_core_gf64_bu_stage_column_fwd.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_butterfly_unit/rtl/ntt_core_gf64_bu_stage_column_bwd.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/inc/ntt_core_gf64_ntw_macro_inc.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_rot.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_core_wr.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_core_rd.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_core_ram.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_cst.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_network.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/constraint/ntt_core_gf64_network_timing_constraints_hier.xdc} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_phi_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_rom.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_reg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_shift_reg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_mult.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_shift.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_post_process/rtl/ntt_core_gf64_pp_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_post_process/rtl/ntt_core_gf64_post_process.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/rtl/ntt_core_gf64_reduction.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/rtl/ntt_core_gf64_middle.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/rtl/ntt_core_gf64_head.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/rtl/ntt_core_gf64_tail.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/rtl/ntt_core_gf64.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_load_blwe.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_load_glwe.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_ldg_splitc_dispatch.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_ldg_splitc_dispatch_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_ldg_splitc_entry.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_ldg_splitc_write.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_ldg_splitc_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_load_glwe_splitc_main.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_load_glwe_splitc_subs.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_load_glwe_splitc_assembly.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_sequencer/rtl/pep_sequencer.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pep_if_pkg.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pep_br_mod_switch_to_2powerN.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_bsk.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_ksk.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_ks.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_entry_main.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_entry_subsidiary.sv} \
    {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/patched/pe_pbs_with_entry_assembly.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_modsw.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_ntt_core_head.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_ntt_core_middle.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_ntt_core_tail.sv} \
    {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/patched/pe_pbs.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/rtl/regf_read_arbiter.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/rtl/regf_write_arbiter.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/rtl/regf_ram_unit.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/rtl/regfile.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/constraint/regfile_timing_constraints_hier.xdc} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/fpga_clock_reset/rtl/fpga_reset_dist.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/fpga_clock_reset/rtl/fpga_clock_reset.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/inc/hpu_io_macro_inc.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_with_entry_1in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_with_entry_3in3.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_with_pe.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_3parts_1in3_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_3parts_2in3_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_3parts_3in3_core.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_soft_reset.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_qualified_pipe.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_qual_sll.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_3parts.sv} \
    {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/constraint/hpu_timing_constraints_local.xdc} \
    {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/top_defines_inc.sv} \
    {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/hpu_mini.sv} \
]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/AXI_DATA_W/AXI_DATA_W_256/axi_if_data_w_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_bsk_axi_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_ksk_axi_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_ct_axi_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_glwe_axi_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_ucore_axi_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_shell_axil_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_trc_axi_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/axi_if/module/axi_if_common/rtl/axi_if_mhdma_axi_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common_package/rtl/common_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/param/module/param_msg2_carry2_pfail128_132b_tuniform_144a47/rtl/param_tfhe_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/param/rtl/NTT_MOD/NTT_MOD_goldilocks/param_ntt_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/param/rtl/param_tfhe_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/param/rtl/param_ntt_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/module/regf_common/rtl/REGF_STRUCT/REGF_STRUCT_reg64_coef32_seq4/regf_common_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/module/regf_common/rtl/regf_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_common_instruction/rtl/hpu_common_instruction_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/top_common/rtl/TOP_TOP/TOP_TOP_hpu/top_common_top_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/top_common/rtl/TOP_PC/TOP_PC_pem1_glwe1_bsk4_ksk4/top_common_pc_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/top_common/rtl/TOP_PCMAX/TOP_PCMAX_pem1_glwe1_bsk4_ksk4/top_common_pcmax_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/top_common/rtl/top_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_mem/module/pem_common/rtl/pem_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/cdc/module/xpm_cdc_handshake_wrapper/rtl/xpm_cdc_handshake_wrapper.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/cdc/module/xpm_fifo_async_wrapper/rtl/xpm_fifo_async_wrapper.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/cdc/module/xpm_cdc_single_wrapper/rtl/xpm_cdc_single_wrapper.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_wrapper_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_1R1W_behav_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_1R1W_behav.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_wrapper_1R1W.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_2RW_behav_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_2RW_behav.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_wrapper_2RW.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_wrapper_NR1W.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_NR1W_behav.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_wrapper/rtl/ram_NR1W_behav_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_element_type1.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_element_type2.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_element_type3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_element.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_reg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_ram_rdy_vld.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_ram_rdy_vld_2clk.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/fifo/rtl/fifo_delay.sv}]
set_property file_type {Verilog Header} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/inc/ntt_core_common_macro_inc.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/NTT_CORE_ARCH/NTT_CORE_ARCH_gf64/ntt_core_common_arch_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/NTT_CORE_R/NTT_CORE_R_2/ntt_core_common_r_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/NTT_CORE_PSI/NTT_CORE_PSI_16/ntt_core_common_psi_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/NTT_CORE_DIV/NTT_CORE_DIV_1/ntt_core_common_div_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/NTT_CORE_RDX_CUT/NTT_CORE_RDX_CUT_n5c5c1/ntt_core_common_cut_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/ntt_core_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/module/bsk_mgr_common/rtl/BSK_SLOT/BSK_SLOT_8/bsk_mgr_common_slot_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/module/bsk_mgr_common/rtl/BSK_CUT/BSK_CUT_16/bsk_mgr_common_cut_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/module/bsk_mgr_common/rtl/bsk_mgr_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_if/module/bsk_if_common/rtl/bsk_if_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_common/rtl/PEP_MSPLIT/PEP_MSPLIT_main2_subs2/pep_msplit_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_common/rtl/PEP_BATCH/PEP_BATCH_bpbs16_tpbs32/pep_batch_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_common/rtl/pep_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_common/rtl/KSLB/KSLB_x2y32z3/pep_ks_common_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_common/rtl/pep_ks_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_alu/module/pea_common/rtl/PEA_ALU/PEA_ALU_1/pea_alu_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_alu/module/pea_common/rtl/pea_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_common/rtl/HPU_PART/HPU_PART_gf64/hpu_part_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_common/rtl/HPU_TWDFILE/HPU_TWDFILE_default/hpu_twdfile_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_common/rtl/hpu_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/module/ksk_mgr_common/rtl/KSK_SLOT/KSK_SLOT_8/ksk_mgr_common_slot_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/module/ksk_mgr_common/rtl/KSK_CUT/KSK_CUT_16/ksk_mgr_common_cut_definition_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/module/ksk_mgr_common/rtl/ksk_mgr_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_common/rtl/ntt_core_gf64_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/instruction_scheduler_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/module/isc_common/rtl/isc_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_cfg_1in3_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_cfg_3in3_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_prc_1in3_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_prc_3in3_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_mhdma_2in3_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_req_ack.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_req_ack_rd.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_error_manager.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_counter_manager.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_cfg_1in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_cfg_3in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_prc_1in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_prc_3in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_cfg_1in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_cfg_3in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_prc_1in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_prc_3in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/module/hpu_regif/rtl/hpu_regif_core_mhdma_2in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/multi_hpu_dma.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_bridge.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_decoder.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_formatter.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_master.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_slave.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/rtl/mhdma_nmu_pipe.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/multi_hpu_dma/constraint/multi_hpu_dma_timing_constraints_hier.xdc}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/stream_to_pipe/rtl/stream_to_pipe.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_bin_to_one_hot.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_one_hot_to_bin.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_find_first_bit_equal_to_1.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_find_last_bit_equal_to_1.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_delay_side.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_select_from_one_hot.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_pseudo_reverse.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_pseudo_invert.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_pulse_to_rdy_vld.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/common/rtl/common_lib_count_ones.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/isc_evt.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/isc_ack.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/isc_parser.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/isc_pool.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/isc_query.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/instruction_scheduler/rtl/instruction_scheduler.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/trace_manager/rtl/trace_manager.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_core/rtl/arith_mult_core_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_core/rtl/arith_mult_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_core/rtl/arith_mult_core_with_side.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_karatsuba/rtl/arith_mult_karatsuba_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_karatsuba/rtl/arith_mult_karatsuba_cascade_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_karatsuba/rtl/arith_mult_karatsuba.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_karatsuba/rtl/arith_mult_karatsuba_cascade.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_karatsuba/rtl/arith_mult_kara_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_64bgoldilocks_karatsuba/rtl/arith_mult_64bgoldilocks_karatsuba_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_64bgoldilocks_karatsuba/rtl/arith_mult_64bgoldilocks_karatsuba_cascade_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_64bgoldilocks_karatsuba/rtl/arith_mult_64bgoldilocks_karatsuba.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/module/arith_mult_64bgoldilocks_karatsuba/rtl/arith_mult_64bgoldilocks_karatsuba_cascade.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/rtl/arith_mult_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult/rtl/arith_mult.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_alu/rtl/pea_alu_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_alu/rtl/pe_alu.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/stream_to_seq/rtl/stream_to_seq.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/stream_to_seq/rtl/seq_to_stream.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_mem/rtl/pem_load.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_mem/rtl/pem_store.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_mem/rtl/pe_mem.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_mersenne/rtl/arith_mult_cst_mersenne_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_mersenne/rtl/arith_mult_cst_mersenne.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas3/rtl/arith_mult_cst_solinas3_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas3/rtl/arith_mult_cst_solinas3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas2/rtl/arith_mult_cst_solinas2_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas2/rtl/arith_mult_cst_solinas2.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_goldilocks_inv/rtl/arith_mult_cst_goldilocks_inv_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_goldilocks_inv/rtl/arith_mult_cst_goldilocks_inv.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas2_44_14_inv/rtl/arith_mult_cst_solinas2_44_14_inv_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/module/arith_mult_cst_solinas2_44_14_inv/rtl/arith_mult_cst_solinas2_44_14_inv.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/rtl/arith_mult_constant_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/arithmetic/module/arith_mult_constant/rtl/arith_mult_constant.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_switch/module/mod_switch_to_2powerN/rtl/mod_switch_to_2powerN_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_switch/module/mod_switch_to_2powerN/rtl/mod_switch_to_2powerN.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_if/rtl/bsk_if_cache_control.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_if/rtl/bsk_if_axi4_read.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_if/rtl/bsk_if.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/rtl/bsk_mgr_node.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/rtl/bsk_mgr_cut.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/rtl/bsk_manager.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/bsk/module/bsk_manager/constraint/bsk_manager_timing_constraints_hier.xdc}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_if/module/ksk_if_common/rtl/ksk_if_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_if/rtl/ksk_if_cache_control.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_if/rtl/ksk_if_axi4_read.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_if/rtl/ksk_if.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/rtl/ksk_mgr_node.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/rtl/ksk_manager.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/ksk/module/ksk_manager/constraint/ksk_manager_timing_constraints_hier.xdc}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_mult/rtl/pep_ks_mult_node.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_mult/rtl/pep_ks_mult.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_out_process/rtl/pep_ks_out_process.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_control/rtl/pep_ks_ctrl_read.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_control/rtl/pep_ks_ctrl_feed.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_control/rtl/pep_ks_control.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/ram_rd_rdy_vld/rtl/ram_rd_rdy_vld.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/decomposer/module/decomp_parallel/rtl/decomp_parallel.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_blwe_ram/rtl/pep_ks_blram_format.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_blwe_ram/rtl/pep_ks_blram_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/module/pep_ks_blwe_ram/rtl/pep_ks_blwe_ram.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/rtl/pep_ks_result_format.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/rtl/pep_ks_body_map.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_key_switch/rtl/pep_key_switch.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_common/rtl/pep_mmacc_common_permutation_vector.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_common/rtl/pep_mmacc_common_param_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_misc/rtl/pep_mmacc_infifo.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_misc/rtl/pep_mmacc_body_ram.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_glwe_ram/rtl/pep_mmacc_gram_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_glwe_ram/rtl/pep_mmacc_glwe_ram.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_gram_arb/rtl/pep_mmacc_gram_arb.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_acc_read.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_acc_write.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_acc_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_main_acc.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_subs_acc.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_acc/rtl/pep_mmacc_splitc_acc_assembly.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_read.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_rot.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_join.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_final.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_entry.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_feed_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_main_feed.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_feed/rtl/pep_mmacc_splitc_subs_feed.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/stream_dispatch/rtl/stream_disp_format.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/stream_dispatch/rtl/stream_dispatch.sv}]
set_property file_type {Verilog Header} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/inc/pep_mmacc_splitc_sxt_macro_inc.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_sync.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_read.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_rot.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_join.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_final.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_entry.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_main_sxt.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_subs_sxt.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/pep_mmacc_splitc_sxt_assembly.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/rtl/pep_mmacc_splitc_main.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/rtl/pep_mmacc_splitc_subsidiary.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/rtl/pep_mmacc_splitc_assembly.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/constraint/pep_mmacc_splitc_timing_constraints_hier.xdc}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/decomposer/module/decomp_balanced_sequential/rtl/decomp_balseq_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/decomposer/module/decomp_balanced_sequential/rtl/decomp_balanced_sequential.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_common/rtl/ntt_core_wmm_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_1R_behav_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_1R_behav.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_2R_behav_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_2R_behav.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_wrapper_1R.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/rom_wrapper/rtl/rom_wrapper_2R.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/twiddle/rtl/twiddle_phi_ru_manager.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/twiddle/rtl/twiddle_intt_final_manager.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_add_sub/rtl/mod_add_sub_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_add_sub/rtl/mod_add.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_add_sub/rtl/mod_sub.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_mersenne/rtl/mod_reduct_mersenne_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_mersenne/rtl/mod_reduct_mersenne.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_barrett/rtl/mod_reduct_barrett_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_barrett/rtl/mod_reduct_barrett.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas2/rtl/mod_reduct_solinas2_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas2/rtl/mod_reduct_solinas2_general.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas2/rtl/mod_reduct_solinas2_half.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas2/rtl/mod_reduct_solinas2.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas3/rtl/mod_reduct_solinas3_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_solinas3/rtl/mod_reduct_solinas3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_64bgoldilocks_karatsuba/rtl/mod_reduct_64bgoldilocks_karatsuba_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_64bgoldilocks_karatsuba/rtl/mod_reduct_64bgoldilocks_karatsuba.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/rtl/mod_reduct_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/rtl/mod_reduct.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_mult/module/mod_mult_with_reduct/rtl/mod_mult_with_reduct.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_mult/rtl/mod_mult_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_mult/rtl/mod_mult.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_radix/module/ntt_radix_cooley_tukey/rtl/ntt_radix_cooley_tukey_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_radix/module/ntt_radix_cooley_tukey/rtl/ntt_radix_ct_mult_butterfly.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_radix/module/ntt_radix_cooley_tukey/rtl/ntt_radix_ct_butterfly.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_radix/module/ntt_radix_cooley_tukey/rtl/ntt_radix_cooley_tukey.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_cluster_butterfly_unit/rtl/ntt_core_wmm_clbu_pcg_pipe.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_cluster_butterfly_unit/rtl/ntt_core_wmm_clbu_pcg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_pcg_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_rd_pcg_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_wr_pcg_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_last_stage_wr_pcg_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_wr_pcg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_last_stage_wr_pcg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_dispatch_rotate/rtl/ntt_core_wmm_dispatch_rotate_rd_pcg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_infifo/rtl/ntt_core_wmm_infifo.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_ram_rd/rtl/ntt_core_wmm_ram_rd_pcg_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_ram_rd/rtl/ntt_core_wmm_ram_rd_pcg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_network/rtl/ntt_core_wmm_network_pcg_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_network/rtl/ntt_core_wmm_network_pcg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_acc/rtl/mod_acc_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_acc/rtl/mod_acc.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_post_process/rtl/ntt_core_wmm_post_process.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_post_process/rtl/ntt_core_wmm_post_process_wrapper.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_wmm_sequencer/rtl/ntt_core_wmm_sequencer.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_with_matrix_multiplication_unfold_pcg/rtl/ntt_core_with_matrix_multiplication_unfold_pcg_head.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_with_matrix_multiplication_unfold_pcg/rtl/ntt_core_with_matrix_multiplication_unfold_pcg_middle_fwd.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_with_matrix_multiplication_unfold_pcg/rtl/ntt_core_with_matrix_multiplication_unfold_pcg_middle_bwd.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_with_matrix_multiplication_unfold_pcg/rtl/ntt_core_with_matrix_multiplication_unfold_pcg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/module/ntt_core_with_matrix_multiplication_unfold_pcg/rtl/ntt_core_with_matrix_multiplication_unfold_pcg_assembly.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/rtl/ntt_core_with_matrix_multiplication.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/rtl/ntt_core_with_matrix_multiplication_head.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_with_matrix_multiplication/rtl/ntt_core_with_matrix_multiplication_middle.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_add.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_sub.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_shift_cst.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_shift.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_sign.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_reduction.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_sign_reduction.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_mult.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_arithmetic/rtl/ntt_core_gf64_pmr_acc.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_butterfly_unit/rtl/ntt_core_gf64_bu_cooley_tukey.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_butterfly_unit/rtl/ntt_core_gf64_bu_gentleman_sande.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_butterfly_unit/rtl/ntt_core_gf64_bu_stage_column_fwd.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_butterfly_unit/rtl/ntt_core_gf64_bu_stage_column_bwd.sv}]
set_property file_type {Verilog Header} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/inc/ntt_core_gf64_ntw_macro_inc.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_rot.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_core_wr.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_core_rd.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_core_ram.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_ntw_cst.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/ntt_core_gf64_network.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/constraint/ntt_core_gf64_network_timing_constraints_hier.xdc}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_phi_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_rom.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_reg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_shift_reg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_mult.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi_shift.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_phi/rtl/ntt_core_gf64_phi.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_post_process/rtl/ntt_core_gf64_pp_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_post_process/rtl/ntt_core_gf64_post_process.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/rtl/ntt_core_gf64_reduction.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/rtl/ntt_core_gf64_middle.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/rtl/ntt_core_gf64_head.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/rtl/ntt_core_gf64_tail.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/rtl/ntt_core_gf64.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_load_blwe.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_load_glwe.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_ldg_splitc_dispatch.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_ldg_splitc_dispatch_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_ldg_splitc_entry.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_ldg_splitc_write.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_ldg_splitc_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_load_glwe_splitc_main.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_load_glwe_splitc_subs.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_load/rtl/pep_load_glwe_splitc_assembly.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/module/pep_sequencer/rtl/pep_sequencer.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pep_if_pkg.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pep_br_mod_switch_to_2powerN.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_bsk.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_ksk.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_ks.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_entry_main.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_entry_subsidiary.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/patched/pe_pbs_with_entry_assembly.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_modsw.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_ntt_core_head.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_ntt_core_middle.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pe_pbs/rtl/pe_pbs_with_ntt_core_tail.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/patched/pe_pbs.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/rtl/regf_read_arbiter.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/rtl/regf_write_arbiter.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/rtl/regf_ram_unit.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/rtl/regfile.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/regfile/constraint/regfile_timing_constraints_hier.xdc}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/fpga_clock_reset/rtl/fpga_reset_dist.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/fpga_clock_reset/rtl/fpga_clock_reset.sv}]
set_property file_type {Verilog Header} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/inc/hpu_io_macro_inc.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_with_entry_1in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_with_entry_3in3.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_with_pe.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_3parts_1in3_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_3parts_2in3_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_3parts_3in3_core.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_soft_reset.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_qualified_pipe.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_qual_sll.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/hpu_3parts.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/constraint/hpu_timing_constraints_local.xdc}]
set_property file_type {Verilog Header} [get_files {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/top_defines_inc.sv}]
set_property file_type {SystemVerilog} [get_files {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/hpu_mini.sv}]
set_property include_dirs [list {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl} {/home/yzwu/Desktop/hpu_fpga-main/hw/module/hpu/rtl/inc} {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_common/rtl/inc} {/home/yzwu/Desktop/hpu_fpga-main/hw/module/number_theoretic_transform/module/ntt_core_gf64/module/ntt_core_gf64_network/rtl/inc} {/home/yzwu/Desktop/hpu_fpga-main/hw/module/pep_mono_mult_acc/module/pep_mmacc_splitc/module/pep_mmacc_splitc_sxt/rtl/inc}] [get_filesets sources_1]
set_property top hpu_mini [get_filesets sources_1]
add_files -fileset sim_1 -norecurse [list {/home/yzwu/Desktop/hpu_fpga-main/hw/simu_lib/axi4_lib/rtl/axi4_ram.sv} {/home/yzwu/Desktop/hpu_fpga-main/hw/simu_lib/axi4_lib/rtl/axi4_mem.sv} {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/tb_hpu_mini.sv}]
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1] {/home/yzwu/Desktop/hpu_fpga-main/hw/simu_lib/axi4_lib/rtl/axi4_ram.sv}]
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1] {/home/yzwu/Desktop/hpu_fpga-main/hw/simu_lib/axi4_lib/rtl/axi4_mem.sv}]
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1] {/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/rtl/tb_hpu_mini.sv}]
set inc_dirs [get_property include_dirs [get_filesets sources_1]]
lappend inc_dirs /home/yzwu/Desktop/hpu_fpga-main/hw/common_lib/mod_arithmetic/module/mod_reduct/module/mod_reduct_barrett/rtl/coverage
set_property include_dirs $inc_dirs [get_filesets sim_1]
set_property verilog_define [list DEF_INIT_RAM=1 TB_GOLDEN_DIR=\"/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/mockup_run/ucode\" TB_DATA_DIR=\"/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/keys_flat\"] [get_filesets sim_1]
set_property top tb_hpu_mini [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]
if {[info exists ::env(TB_PLUSARGS)]} { set_property -name {xsim.simulate.xsim.more_options} -value "-testplusarg $::env(TB_PLUSARGS)" -objects [get_filesets sim_1] }
update_compile_order -fileset sources_1
launch_simulation
puts "XSIM_LAUNCH_RETURNED"
close_sim -quiet
puts "XSIM_DONE"
