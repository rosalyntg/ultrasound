# file: bd_in_system_ibert_0_0.xdc
####################################################################################
##**************************************************************************
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *rxrate_sync1*}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *rxrate_sync2*}]
set_false_path -from [get_cells -hierarchical -filter {NAME =~ *rxrate_sync1*}]
set_false_path -from [get_cells -hierarchical -filter {NAME =~ *rxrate_sync2*}]

set_false_path -to [get_cells -hierarchical -filter {NAME =~ *rxrate_reg_sync1*}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *rxrate_reg_sync2*}]
set_false_path -from [get_cells -hierarchical -filter {NAME =~ *rxrate_reg_sync1*}]
set_false_path -from [get_cells -hierarchical -filter {NAME =~ *rxrate_reg_sync2*}]

set_case_analysis 0 [get_pins -of_object [get_cells -hierarchical -filter {NAME =~ *i_regs}] -filter {REF_PIN_NAME =~ rxrate_ovrd_o*}]

