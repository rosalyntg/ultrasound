-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
-- Date        : Fri Jul  3 17:43:11 2026
-- Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/russell/ultrasound/fpga/us/us.gen/sources_1/bd/bd/ip/bd_net_wrapper_0_0/bd_net_wrapper_0_0_stub.vhdl
-- Design      : bd_net_wrapper_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcau15p-ffvb676-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bd_net_wrapper_0_0 is
  Port ( 
    logic_clk : in STD_LOGIC;
    logic_rst : in STD_LOGIC;
    xgmii_rx_clk : in STD_LOGIC;
    xgmii_rx_rst : in STD_LOGIC;
    xgmii_tx_clk : in STD_LOGIC;
    xgmii_tx_rst : in STD_LOGIC;
    xgmii_rxd : in STD_LOGIC_VECTOR ( 63 downto 0 );
    xgmii_rxc : in STD_LOGIC_VECTOR ( 7 downto 0 );
    xgmii_txd : out STD_LOGIC_VECTOR ( 63 downto 0 );
    xgmii_txc : out STD_LOGIC_VECTOR ( 7 downto 0 );
    s_udp_hdr_valid : in STD_LOGIC;
    s_udp_hdr_ready : out STD_LOGIC;
    s_udp_ip_dscp : in STD_LOGIC_VECTOR ( 5 downto 0 );
    s_udp_ip_ecn : in STD_LOGIC_VECTOR ( 1 downto 0 );
    s_udp_ip_ttl : in STD_LOGIC_VECTOR ( 7 downto 0 );
    s_udp_ip_source_ip : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_udp_ip_dest_ip : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_udp_source_port : in STD_LOGIC_VECTOR ( 15 downto 0 );
    s_udp_dest_port : in STD_LOGIC_VECTOR ( 15 downto 0 );
    s_udp_length : in STD_LOGIC_VECTOR ( 15 downto 0 );
    s_udp_checksum : in STD_LOGIC_VECTOR ( 15 downto 0 );
    s_udp_payload_axis_tdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
    s_udp_payload_axis_tkeep : in STD_LOGIC_VECTOR ( 7 downto 0 );
    s_udp_payload_axis_tvalid : in STD_LOGIC;
    s_udp_payload_axis_tready : out STD_LOGIC;
    s_udp_payload_axis_tlast : in STD_LOGIC;
    s_udp_payload_axis_tuser : in STD_LOGIC;
    m_udp_hdr_valid : out STD_LOGIC;
    m_udp_hdr_ready : in STD_LOGIC;
    m_udp_eth_dest_mac : out STD_LOGIC_VECTOR ( 47 downto 0 );
    m_udp_eth_src_mac : out STD_LOGIC_VECTOR ( 47 downto 0 );
    m_udp_eth_type : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_udp_ip_version : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_udp_ip_ihl : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_udp_ip_dscp : out STD_LOGIC_VECTOR ( 5 downto 0 );
    m_udp_ip_ecn : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_udp_ip_length : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_udp_ip_identification : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_udp_ip_flags : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_udp_ip_fragment_offset : out STD_LOGIC_VECTOR ( 12 downto 0 );
    m_udp_ip_ttl : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_udp_ip_protocol : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_udp_ip_header_checksum : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_udp_ip_source_ip : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_udp_ip_dest_ip : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_udp_source_port : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_udp_dest_port : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_udp_length : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_udp_checksum : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_udp_payload_axis_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_udp_payload_axis_tkeep : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_udp_payload_axis_tvalid : out STD_LOGIC;
    m_udp_payload_axis_tready : in STD_LOGIC;
    m_udp_payload_axis_tlast : out STD_LOGIC;
    m_udp_payload_axis_tuser : out STD_LOGIC;
    rx_error_bad_frame : out STD_LOGIC;
    rx_error_bad_fcs : out STD_LOGIC;
    ip_rx_busy : out STD_LOGIC;
    ip_tx_busy : out STD_LOGIC;
    udp_rx_busy : out STD_LOGIC;
    udp_tx_busy : out STD_LOGIC;
    local_mac : in STD_LOGIC_VECTOR ( 47 downto 0 );
    local_ip : in STD_LOGIC_VECTOR ( 31 downto 0 );
    gateway_ip : in STD_LOGIC_VECTOR ( 31 downto 0 );
    subnet_mask : in STD_LOGIC_VECTOR ( 31 downto 0 );
    clear_arp_cache : in STD_LOGIC
  );

  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of bd_net_wrapper_0_0 : entity is "bd_net_wrapper_0_0,net_wrapper,{}";
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of bd_net_wrapper_0_0 : entity is "bd_net_wrapper_0_0,net_wrapper,{x_ipProduct=Vivado 2025.2.1,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=net_wrapper,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of bd_net_wrapper_0_0 : entity is "yes";
  attribute IP_DEFINITION_SOURCE : string;
  attribute IP_DEFINITION_SOURCE of bd_net_wrapper_0_0 : entity is "module_ref";
end bd_net_wrapper_0_0;

architecture stub of bd_net_wrapper_0_0 is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "logic_clk,logic_rst,xgmii_rx_clk,xgmii_rx_rst,xgmii_tx_clk,xgmii_tx_rst,xgmii_rxd[63:0],xgmii_rxc[7:0],xgmii_txd[63:0],xgmii_txc[7:0],s_udp_hdr_valid,s_udp_hdr_ready,s_udp_ip_dscp[5:0],s_udp_ip_ecn[1:0],s_udp_ip_ttl[7:0],s_udp_ip_source_ip[31:0],s_udp_ip_dest_ip[31:0],s_udp_source_port[15:0],s_udp_dest_port[15:0],s_udp_length[15:0],s_udp_checksum[15:0],s_udp_payload_axis_tdata[63:0],s_udp_payload_axis_tkeep[7:0],s_udp_payload_axis_tvalid,s_udp_payload_axis_tready,s_udp_payload_axis_tlast,s_udp_payload_axis_tuser,m_udp_hdr_valid,m_udp_hdr_ready,m_udp_eth_dest_mac[47:0],m_udp_eth_src_mac[47:0],m_udp_eth_type[15:0],m_udp_ip_version[3:0],m_udp_ip_ihl[3:0],m_udp_ip_dscp[5:0],m_udp_ip_ecn[1:0],m_udp_ip_length[15:0],m_udp_ip_identification[15:0],m_udp_ip_flags[2:0],m_udp_ip_fragment_offset[12:0],m_udp_ip_ttl[7:0],m_udp_ip_protocol[7:0],m_udp_ip_header_checksum[15:0],m_udp_ip_source_ip[31:0],m_udp_ip_dest_ip[31:0],m_udp_source_port[15:0],m_udp_dest_port[15:0],m_udp_length[15:0],m_udp_checksum[15:0],m_udp_payload_axis_tdata[63:0],m_udp_payload_axis_tkeep[7:0],m_udp_payload_axis_tvalid,m_udp_payload_axis_tready,m_udp_payload_axis_tlast,m_udp_payload_axis_tuser,rx_error_bad_frame,rx_error_bad_fcs,ip_rx_busy,ip_tx_busy,udp_rx_busy,udp_tx_busy,local_mac[47:0],local_ip[31:0],gateway_ip[31:0],subnet_mask[31:0],clear_arp_cache";
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of logic_clk : signal is "xilinx.com:signal:clock:1.0 logic_clk CLK";
  attribute X_INTERFACE_MODE : string;
  attribute X_INTERFACE_MODE of logic_clk : signal is "slave";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of logic_clk : signal is "XIL_INTERFACENAME logic_clk, ASSOCIATED_RESET logic_rst, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN bd_xxv_ethernet_0_0_rx_clk_out_0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of logic_rst : signal is "xilinx.com:signal:reset:1.0 logic_rst RST";
  attribute X_INTERFACE_MODE of logic_rst : signal is "slave";
  attribute X_INTERFACE_PARAMETER of logic_rst : signal is "XIL_INTERFACENAME logic_rst, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of xgmii_rx_clk : signal is "xilinx.com:signal:clock:1.0 xgmii_rx_clk CLK";
  attribute X_INTERFACE_MODE of xgmii_rx_clk : signal is "slave";
  attribute X_INTERFACE_PARAMETER of xgmii_rx_clk : signal is "XIL_INTERFACENAME xgmii_rx_clk, ASSOCIATED_RESET xgmii_rx_rst, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN bd_xxv_ethernet_0_0_rx_clk_out_0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of xgmii_rx_rst : signal is "xilinx.com:signal:reset:1.0 xgmii_rx_rst RST";
  attribute X_INTERFACE_MODE of xgmii_rx_rst : signal is "slave";
  attribute X_INTERFACE_PARAMETER of xgmii_rx_rst : signal is "XIL_INTERFACENAME xgmii_rx_rst, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of xgmii_tx_clk : signal is "xilinx.com:signal:clock:1.0 xgmii_tx_clk CLK";
  attribute X_INTERFACE_MODE of xgmii_tx_clk : signal is "slave";
  attribute X_INTERFACE_PARAMETER of xgmii_tx_clk : signal is "XIL_INTERFACENAME xgmii_tx_clk, ASSOCIATED_RESET xgmii_tx_rst, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN bd_xxv_ethernet_0_0_tx_mii_clk_0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of xgmii_tx_rst : signal is "xilinx.com:signal:reset:1.0 xgmii_tx_rst RST";
  attribute X_INTERFACE_MODE of xgmii_tx_rst : signal is "slave";
  attribute X_INTERFACE_PARAMETER of xgmii_tx_rst : signal is "XIL_INTERFACENAME xgmii_tx_rst, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of s_udp_payload_axis_tdata : signal is "xilinx.com:interface:axis:1.0 s_udp_payload_axis TDATA";
  attribute X_INTERFACE_MODE of s_udp_payload_axis_tdata : signal is "slave";
  attribute X_INTERFACE_PARAMETER of s_udp_payload_axis_tdata : signal is "XIL_INTERFACENAME s_udp_payload_axis, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of s_udp_payload_axis_tkeep : signal is "xilinx.com:interface:axis:1.0 s_udp_payload_axis TKEEP";
  attribute X_INTERFACE_INFO of s_udp_payload_axis_tvalid : signal is "xilinx.com:interface:axis:1.0 s_udp_payload_axis TVALID";
  attribute X_INTERFACE_INFO of s_udp_payload_axis_tready : signal is "xilinx.com:interface:axis:1.0 s_udp_payload_axis TREADY";
  attribute X_INTERFACE_INFO of s_udp_payload_axis_tlast : signal is "xilinx.com:interface:axis:1.0 s_udp_payload_axis TLAST";
  attribute X_INTERFACE_INFO of s_udp_payload_axis_tuser : signal is "xilinx.com:interface:axis:1.0 s_udp_payload_axis TUSER";
  attribute X_INTERFACE_INFO of m_udp_payload_axis_tdata : signal is "xilinx.com:interface:axis:1.0 m_udp_payload_axis TDATA";
  attribute X_INTERFACE_MODE of m_udp_payload_axis_tdata : signal is "master";
  attribute X_INTERFACE_PARAMETER of m_udp_payload_axis_tdata : signal is "XIL_INTERFACENAME m_udp_payload_axis, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of m_udp_payload_axis_tkeep : signal is "xilinx.com:interface:axis:1.0 m_udp_payload_axis TKEEP";
  attribute X_INTERFACE_INFO of m_udp_payload_axis_tvalid : signal is "xilinx.com:interface:axis:1.0 m_udp_payload_axis TVALID";
  attribute X_INTERFACE_INFO of m_udp_payload_axis_tready : signal is "xilinx.com:interface:axis:1.0 m_udp_payload_axis TREADY";
  attribute X_INTERFACE_INFO of m_udp_payload_axis_tlast : signal is "xilinx.com:interface:axis:1.0 m_udp_payload_axis TLAST";
  attribute X_INTERFACE_INFO of m_udp_payload_axis_tuser : signal is "xilinx.com:interface:axis:1.0 m_udp_payload_axis TUSER";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of stub : architecture is "net_wrapper,Vivado 2025.2.1";
begin
end;
