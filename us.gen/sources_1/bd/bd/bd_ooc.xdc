################################################################################

# This XDC is used only for OOC mode of synthesis, implementation
# This constraints file contains default clock frequencies to be used during
# out-of-context flows such as OOC Synthesis and Hierarchical Designs.
# This constraints file is not used in normal top-down synthesis (default flow
# of Vivado)
################################################################################
create_clock -name eth_refclk_clk_p -period 6.400 [get_ports eth_refclk_clk_p]
create_clock -name jesd_refclk_clk_p -period 10 [get_ports jesd_refclk_clk_p]
create_clock -name osc_200mhz_clk_p -period 5 [get_ports osc_200mhz_clk_p]
create_clock -name jesd_coreclk_clk_p -period 10 [get_ports jesd_coreclk_clk_p]

################################################################################