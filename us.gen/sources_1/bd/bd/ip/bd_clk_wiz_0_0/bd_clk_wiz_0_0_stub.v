// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
// Date        : Sun Apr 19 19:02:56 2026
// Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/russell/ultrasound/fpga/us/us.gen/sources_1/bd/bd/ip/bd_clk_wiz_0_0/bd_clk_wiz_0_0_stub.v
// Design      : bd_clk_wiz_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcau15p-ffvb676-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CORE_GENERATION_INFO = "bd_clk_wiz_0_0,clk_wiz_v6_0_18_0_0,{component_name=bd_clk_wiz_0_0,use_phase_alignment=false,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,enable_axi=0,feedback_source=FDBK_AUTO,PRIMITIVE=BUFGCE_DIV,num_out_clk=1,clkin1_period=5.000,clkin2_period=10.0,use_power_down=false,use_reset=false,use_locked=false,use_inclk_stopped=false,feedback_type=SINGLE,CLOCK_MGR_TYPE=NA,manual_override=false}" *) 
module bd_clk_wiz_0_0(mhz25, clk_in1_p, clk_in1_n)
/* synthesis syn_black_box black_box_pad_pin="clk_in1_p,clk_in1_n" */
/* synthesis syn_force_seq_prim="mhz25" */;
  output mhz25 /* synthesis syn_isclock = 1 */;
  input clk_in1_p;
  input clk_in1_n;
endmodule
