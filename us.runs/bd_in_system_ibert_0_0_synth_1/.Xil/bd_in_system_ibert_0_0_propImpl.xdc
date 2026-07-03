set_property SRC_FILE_INFO {cfile:/home/russell/ultrasound/fpga/us/us.gen/sources_1/bd/bd/ip/bd_in_system_ibert_0_0/synth/bd_in_system_ibert_0_0.xdc rfile:../../../us.gen/sources_1/bd/bd/ip/bd_in_system_ibert_0_0/synth/bd_in_system_ibert_0_0.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
set_property SRC_FILE_INFO {cfile:/home/russell/ultrasound/fpga/us/us.gen/sources_1/bd/bd/ip/bd_in_system_ibert_0_0/synth/ibert_waivers.xdc rfile:../../../us.gen/sources_1/bd/bd/ip/bd_in_system_ibert_0_0/synth/ibert_waivers.xdc id:2 order:EARLY scoped_inst:inst} [current_design]
set_property src_info {type:SCOPED_XDC file:1 line:14 export:INPUT save:INPUT read:READ} [current_design]
set_case_analysis 0 [get_pins {inst/GTHE4_CH[0].u_gthe4_ch/i_regs/rxrate_ovrd_o}]
current_instance inst
set_property src_info {type:SCOPED_XDC file:2 line:7 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1165975" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_ports {gt0_drpdo_i[*]}] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*GT*E*_CH[*].u_gt*e*_ch/i_regs/U_XSDB_SLAVE/G_1PIPE_IFACE.s_do_r_reg[*]}]]
