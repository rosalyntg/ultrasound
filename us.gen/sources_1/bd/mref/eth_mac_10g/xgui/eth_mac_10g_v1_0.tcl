# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "CTRL_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ENABLE_DIC" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ENABLE_PADDING" -parent ${Page_0}
  ipgui::add_param $IPINST -name "KEEP_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MIN_FRAME_LENGTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PAUSE_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PFC_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PTP_TS_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PTP_TS_FMT_TOD" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PTP_TS_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RX_USER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "TX_PTP_TAG_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "TX_PTP_TAG_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "TX_PTP_TS_CTRL_IN_TUSER" -parent ${Page_0}
  ipgui::add_param $IPINST -name "TX_USER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "TX_USER_WIDTH_INT" -parent ${Page_0}


}

proc update_PARAM_VALUE.CTRL_WIDTH { PARAM_VALUE.CTRL_WIDTH } {
	# Procedure called to update CTRL_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CTRL_WIDTH { PARAM_VALUE.CTRL_WIDTH } {
	# Procedure called to validate CTRL_WIDTH
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.ENABLE_DIC { PARAM_VALUE.ENABLE_DIC } {
	# Procedure called to update ENABLE_DIC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_DIC { PARAM_VALUE.ENABLE_DIC } {
	# Procedure called to validate ENABLE_DIC
	return true
}

proc update_PARAM_VALUE.ENABLE_PADDING { PARAM_VALUE.ENABLE_PADDING } {
	# Procedure called to update ENABLE_PADDING when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_PADDING { PARAM_VALUE.ENABLE_PADDING } {
	# Procedure called to validate ENABLE_PADDING
	return true
}

proc update_PARAM_VALUE.KEEP_WIDTH { PARAM_VALUE.KEEP_WIDTH } {
	# Procedure called to update KEEP_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.KEEP_WIDTH { PARAM_VALUE.KEEP_WIDTH } {
	# Procedure called to validate KEEP_WIDTH
	return true
}

proc update_PARAM_VALUE.MIN_FRAME_LENGTH { PARAM_VALUE.MIN_FRAME_LENGTH } {
	# Procedure called to update MIN_FRAME_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MIN_FRAME_LENGTH { PARAM_VALUE.MIN_FRAME_LENGTH } {
	# Procedure called to validate MIN_FRAME_LENGTH
	return true
}

proc update_PARAM_VALUE.PAUSE_ENABLE { PARAM_VALUE.PAUSE_ENABLE } {
	# Procedure called to update PAUSE_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PAUSE_ENABLE { PARAM_VALUE.PAUSE_ENABLE } {
	# Procedure called to validate PAUSE_ENABLE
	return true
}

proc update_PARAM_VALUE.PFC_ENABLE { PARAM_VALUE.PFC_ENABLE } {
	# Procedure called to update PFC_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PFC_ENABLE { PARAM_VALUE.PFC_ENABLE } {
	# Procedure called to validate PFC_ENABLE
	return true
}

proc update_PARAM_VALUE.PTP_TS_ENABLE { PARAM_VALUE.PTP_TS_ENABLE } {
	# Procedure called to update PTP_TS_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PTP_TS_ENABLE { PARAM_VALUE.PTP_TS_ENABLE } {
	# Procedure called to validate PTP_TS_ENABLE
	return true
}

proc update_PARAM_VALUE.PTP_TS_FMT_TOD { PARAM_VALUE.PTP_TS_FMT_TOD } {
	# Procedure called to update PTP_TS_FMT_TOD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PTP_TS_FMT_TOD { PARAM_VALUE.PTP_TS_FMT_TOD } {
	# Procedure called to validate PTP_TS_FMT_TOD
	return true
}

proc update_PARAM_VALUE.PTP_TS_WIDTH { PARAM_VALUE.PTP_TS_WIDTH } {
	# Procedure called to update PTP_TS_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PTP_TS_WIDTH { PARAM_VALUE.PTP_TS_WIDTH } {
	# Procedure called to validate PTP_TS_WIDTH
	return true
}

proc update_PARAM_VALUE.RX_USER_WIDTH { PARAM_VALUE.RX_USER_WIDTH } {
	# Procedure called to update RX_USER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RX_USER_WIDTH { PARAM_VALUE.RX_USER_WIDTH } {
	# Procedure called to validate RX_USER_WIDTH
	return true
}

proc update_PARAM_VALUE.TX_PTP_TAG_ENABLE { PARAM_VALUE.TX_PTP_TAG_ENABLE } {
	# Procedure called to update TX_PTP_TAG_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TX_PTP_TAG_ENABLE { PARAM_VALUE.TX_PTP_TAG_ENABLE } {
	# Procedure called to validate TX_PTP_TAG_ENABLE
	return true
}

proc update_PARAM_VALUE.TX_PTP_TAG_WIDTH { PARAM_VALUE.TX_PTP_TAG_WIDTH } {
	# Procedure called to update TX_PTP_TAG_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TX_PTP_TAG_WIDTH { PARAM_VALUE.TX_PTP_TAG_WIDTH } {
	# Procedure called to validate TX_PTP_TAG_WIDTH
	return true
}

proc update_PARAM_VALUE.TX_PTP_TS_CTRL_IN_TUSER { PARAM_VALUE.TX_PTP_TS_CTRL_IN_TUSER } {
	# Procedure called to update TX_PTP_TS_CTRL_IN_TUSER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TX_PTP_TS_CTRL_IN_TUSER { PARAM_VALUE.TX_PTP_TS_CTRL_IN_TUSER } {
	# Procedure called to validate TX_PTP_TS_CTRL_IN_TUSER
	return true
}

proc update_PARAM_VALUE.TX_USER_WIDTH { PARAM_VALUE.TX_USER_WIDTH } {
	# Procedure called to update TX_USER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TX_USER_WIDTH { PARAM_VALUE.TX_USER_WIDTH } {
	# Procedure called to validate TX_USER_WIDTH
	return true
}

proc update_PARAM_VALUE.TX_USER_WIDTH_INT { PARAM_VALUE.TX_USER_WIDTH_INT } {
	# Procedure called to update TX_USER_WIDTH_INT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TX_USER_WIDTH_INT { PARAM_VALUE.TX_USER_WIDTH_INT } {
	# Procedure called to validate TX_USER_WIDTH_INT
	return true
}


proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.KEEP_WIDTH { MODELPARAM_VALUE.KEEP_WIDTH PARAM_VALUE.KEEP_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.KEEP_WIDTH}] ${MODELPARAM_VALUE.KEEP_WIDTH}
}

proc update_MODELPARAM_VALUE.CTRL_WIDTH { MODELPARAM_VALUE.CTRL_WIDTH PARAM_VALUE.CTRL_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CTRL_WIDTH}] ${MODELPARAM_VALUE.CTRL_WIDTH}
}

proc update_MODELPARAM_VALUE.ENABLE_PADDING { MODELPARAM_VALUE.ENABLE_PADDING PARAM_VALUE.ENABLE_PADDING } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_PADDING}] ${MODELPARAM_VALUE.ENABLE_PADDING}
}

proc update_MODELPARAM_VALUE.ENABLE_DIC { MODELPARAM_VALUE.ENABLE_DIC PARAM_VALUE.ENABLE_DIC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_DIC}] ${MODELPARAM_VALUE.ENABLE_DIC}
}

proc update_MODELPARAM_VALUE.MIN_FRAME_LENGTH { MODELPARAM_VALUE.MIN_FRAME_LENGTH PARAM_VALUE.MIN_FRAME_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MIN_FRAME_LENGTH}] ${MODELPARAM_VALUE.MIN_FRAME_LENGTH}
}

proc update_MODELPARAM_VALUE.PTP_TS_ENABLE { MODELPARAM_VALUE.PTP_TS_ENABLE PARAM_VALUE.PTP_TS_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PTP_TS_ENABLE}] ${MODELPARAM_VALUE.PTP_TS_ENABLE}
}

proc update_MODELPARAM_VALUE.PTP_TS_FMT_TOD { MODELPARAM_VALUE.PTP_TS_FMT_TOD PARAM_VALUE.PTP_TS_FMT_TOD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PTP_TS_FMT_TOD}] ${MODELPARAM_VALUE.PTP_TS_FMT_TOD}
}

proc update_MODELPARAM_VALUE.PTP_TS_WIDTH { MODELPARAM_VALUE.PTP_TS_WIDTH PARAM_VALUE.PTP_TS_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PTP_TS_WIDTH}] ${MODELPARAM_VALUE.PTP_TS_WIDTH}
}

proc update_MODELPARAM_VALUE.TX_PTP_TS_CTRL_IN_TUSER { MODELPARAM_VALUE.TX_PTP_TS_CTRL_IN_TUSER PARAM_VALUE.TX_PTP_TS_CTRL_IN_TUSER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TX_PTP_TS_CTRL_IN_TUSER}] ${MODELPARAM_VALUE.TX_PTP_TS_CTRL_IN_TUSER}
}

proc update_MODELPARAM_VALUE.TX_PTP_TAG_ENABLE { MODELPARAM_VALUE.TX_PTP_TAG_ENABLE PARAM_VALUE.TX_PTP_TAG_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TX_PTP_TAG_ENABLE}] ${MODELPARAM_VALUE.TX_PTP_TAG_ENABLE}
}

proc update_MODELPARAM_VALUE.TX_PTP_TAG_WIDTH { MODELPARAM_VALUE.TX_PTP_TAG_WIDTH PARAM_VALUE.TX_PTP_TAG_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TX_PTP_TAG_WIDTH}] ${MODELPARAM_VALUE.TX_PTP_TAG_WIDTH}
}

proc update_MODELPARAM_VALUE.TX_USER_WIDTH { MODELPARAM_VALUE.TX_USER_WIDTH PARAM_VALUE.TX_USER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TX_USER_WIDTH}] ${MODELPARAM_VALUE.TX_USER_WIDTH}
}

proc update_MODELPARAM_VALUE.RX_USER_WIDTH { MODELPARAM_VALUE.RX_USER_WIDTH PARAM_VALUE.RX_USER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RX_USER_WIDTH}] ${MODELPARAM_VALUE.RX_USER_WIDTH}
}

proc update_MODELPARAM_VALUE.PFC_ENABLE { MODELPARAM_VALUE.PFC_ENABLE PARAM_VALUE.PFC_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PFC_ENABLE}] ${MODELPARAM_VALUE.PFC_ENABLE}
}

proc update_MODELPARAM_VALUE.PAUSE_ENABLE { MODELPARAM_VALUE.PAUSE_ENABLE PARAM_VALUE.PAUSE_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PAUSE_ENABLE}] ${MODELPARAM_VALUE.PAUSE_ENABLE}
}

proc update_MODELPARAM_VALUE.TX_USER_WIDTH_INT { MODELPARAM_VALUE.TX_USER_WIDTH_INT PARAM_VALUE.TX_USER_WIDTH_INT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TX_USER_WIDTH_INT}] ${MODELPARAM_VALUE.TX_USER_WIDTH_INT}
}

