
module i2c_pinswap (
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_M SCL_I" *)
    input  wire m_i2c_scl_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_M SCL_O" *)
    output reg m_i2c_scl_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_M SCL_T" *)
    output reg m_i2c_scl_t,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_M SDA_I" *)
    input  wire m_i2c_sda_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_M SDA_O" *)
    output reg m_i2c_sda_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_M SDA_T" *)
    output reg m_i2c_sda_t,

    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_S SCL_I" *)
    output  reg s_i2c_scl_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_S SCL_O" *)
    input wire s_i2c_scl_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_S SCL_T" *)
    input wire s_i2c_scl_t,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_S SDA_I" *)
    output  reg s_i2c_sda_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_S SDA_O" *)
    input wire s_i2c_sda_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_S SDA_T" *)
    input wire s_i2c_sda_t,

    input wire swap 
);

always @* begin
    if (swap) begin
        s_i2c_scl_i = m_i2c_sda_i;
        m_i2c_scl_o = s_i2c_sda_o;
        m_i2c_scl_t = s_i2c_sda_t;
        s_i2c_sda_i = m_i2c_scl_i;
        m_i2c_sda_o = s_i2c_scl_o;
        m_i2c_sda_t = s_i2c_scl_t;
    end else begin
        s_i2c_scl_i = m_i2c_scl_i;
        m_i2c_scl_o = s_i2c_scl_o;
        m_i2c_scl_t = s_i2c_scl_t;
        s_i2c_sda_i = m_i2c_sda_i;
        m_i2c_sda_o = s_i2c_sda_o;
        m_i2c_sda_t = s_i2c_sda_t;
    end
end


endmodule