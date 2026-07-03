#----------------------------------------------------------------------
# Title      : Constraints for JESD204 PHY
# Project    : jesd204_phy_v4_1_4
#----------------------------------------------------------------------
# File       : bd_jesd204_phy_0_0_block.xdc
# Author     : AMD
#----------------------------------------------------------------------
# Description: Constraint file for JESD204 PHY core
#----------------------------------------------------------------------
# (c) Copyright 2025 Advanced Micro Devices, Inc. All rights reserved.
#
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
#
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
#
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
#
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
#----------------------------------------------------------------------

# To see constaint endpoints use
# foreach {tempVar} [ get_pins -hier -regexp -filter {name =~ {.*bd_jesd204_phy_0_0.*sync_[rt]x_reset_(?:data|all)\/data_sync_reg0/D} }] { puts $tempVar }
# To see timing
# report_timing -to  [ get_pins -hier -regexp -filter {name =~ {.*bd_jesd204_phy_0_0.*sync_[rt]x_reset_(?:data|all)\/data_sync_reg0/D} }] -path_type summary -unique_pins -setup -max_paths 1000
# Example
# set_false_path -to [get_cells -hier -regexp -filter {name =~ {.*bd_jesd204_phy_0_0.*sync_[rt]x_reset_(?:data|all)\/data_sync_reg.*} && IS_SEQUENTIAL}]

##############################################################################################################################################################
# TIMING CONSTRAINTS
##############################################################################################################################################################
set_false_path -from [get_cells -hier -filter {name =~ *jesd204_phy_block_i/gtwiz_reset_block_i/gtwiz_reset_*x_done_int_reg* && IS_SEQUENTIAL}]
set_false_path -to [get_cells -hier -filter {name =~ *jesd204_phy_block_i/gtwiz_reset_block_i/bit_synchronizer_gtwiz_reset_userclk_*x_active_inst/i_in_meta_reg* && IS_SEQUENTIAL}]



########################
# Waivers
########################
#
# CDC-10
#
create_waiver -internal -scope -user JESD204_PHY -type CDC -id CDC-10 -description {GT_WIZ cpll cal block is safe} \
  -from [ get_pins -filter {REF_PIN_NAME=~C} -of [get_cells -hier -filter {name=~*USER_CPLLLOCK_OUT_reg}] ] \
  -to   [ get_pins -filter {REF_PIN_NAME=~D} -of [get_cells -hier -filter {name=~*syncstages_ff_reg[0]}] ]

create_waiver -internal -scope -user JESD204_PHY -type CDC -id CDC-10 -description {GT_WIZ cpll cal block is safe} \
  -to   [ get_pins -filter {REF_PIN_NAME=~PRE} -of [get_cells -hier -filter {name=~*sync_gtwiz_userclk_tx_active/xpm_cdc_async_rst_inst/arststages_ff_reg[0]}] ]

