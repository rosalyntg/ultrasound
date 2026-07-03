# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_RX_SUBSYS_EN" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_TX_SUBSYS_EN" -parent ${Page_0}


}

proc update_PARAM_VALUE.C_RX_SUBSYS_EN { PARAM_VALUE.C_RX_SUBSYS_EN } {
	# Procedure called to update C_RX_SUBSYS_EN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_RX_SUBSYS_EN { PARAM_VALUE.C_RX_SUBSYS_EN } {
	# Procedure called to validate C_RX_SUBSYS_EN
	return true
}

proc update_PARAM_VALUE.C_TX_SUBSYS_EN { PARAM_VALUE.C_TX_SUBSYS_EN } {
	# Procedure called to update C_TX_SUBSYS_EN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_TX_SUBSYS_EN { PARAM_VALUE.C_TX_SUBSYS_EN } {
	# Procedure called to validate C_TX_SUBSYS_EN
	return true
}


proc update_MODELPARAM_VALUE.C_TX_SUBSYS_EN { MODELPARAM_VALUE.C_TX_SUBSYS_EN PARAM_VALUE.C_TX_SUBSYS_EN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_TX_SUBSYS_EN}] ${MODELPARAM_VALUE.C_TX_SUBSYS_EN}
}

proc update_MODELPARAM_VALUE.C_RX_SUBSYS_EN { MODELPARAM_VALUE.C_RX_SUBSYS_EN PARAM_VALUE.C_RX_SUBSYS_EN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SUBSYS_EN}] ${MODELPARAM_VALUE.C_RX_SUBSYS_EN}
}

