// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
// Date        : Mon Jun 29 23:06:43 2026
// Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ bd_c_counter_binary_0_0_sim_netlist.v
// Design      : bd_c_counter_binary_0_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xcau15p-ffvb676-2-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "bd_c_counter_binary_0_0,c_counter_binary_v12_0_22,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "c_counter_binary_v12_0_22,Vivado 2025.2.1" *) 
(* NotValidForBitStream *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix
   (CLK,
    Q);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk_intf CLK" *) (* x_interface_mode = "slave clk_intf" *) (* x_interface_parameter = "XIL_INTERFACENAME clk_intf, ASSOCIATED_BUSIF q_intf:thresh0_intf:l_intf:load_intf:up_intf:sinit_intf:sset_intf, ASSOCIATED_RESET SCLR, ASSOCIATED_CLKEN CE, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN bd_xxv_ethernet_0_0_rx_clk_out_0, INSERT_VIP 0" *) input CLK;
  (* x_interface_info = "xilinx.com:signal:data:1.0 q_intf DATA" *) (* x_interface_mode = "master q_intf" *) (* x_interface_parameter = "XIL_INTERFACENAME q_intf, LAYERED_METADATA xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value data} bitwidth {attribs {resolve_type generated dependency bitwidth format long minimum {} maximum {}} value 16} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} DATA_WIDTH 16}" *) output [15:0]Q;

  wire CLK;
  wire [15:0]Q;
  wire NLW_U0_THRESH0_UNCONNECTED;

  (* C_AINIT_VAL = "0" *) 
  (* C_CE_OVERRIDES_SYNC = "0" *) 
  (* C_FB_LATENCY = "0" *) 
  (* C_HAS_CE = "0" *) 
  (* C_HAS_SCLR = "0" *) 
  (* C_HAS_SINIT = "0" *) 
  (* C_HAS_SSET = "0" *) 
  (* C_IMPLEMENTATION = "0" *) 
  (* C_SCLR_OVERRIDES_SSET = "1" *) 
  (* C_SINIT_VAL = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_WIDTH = "16" *) 
  (* C_XDEVICEFAMILY = "artixuplus" *) 
  (* c_count_by = "1" *) 
  (* c_count_mode = "0" *) 
  (* c_count_to = "1" *) 
  (* c_has_load = "0" *) 
  (* c_has_thresh0 = "0" *) 
  (* c_latency = "1" *) 
  (* c_load_low = "0" *) 
  (* c_restrict_count = "0" *) 
  (* c_thresh0_value = "1" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_c_counter_binary_v12_0_22 U0
       (.CE(1'b1),
        .CLK(CLK),
        .L({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .LOAD(1'b0),
        .Q(Q),
        .SCLR(1'b0),
        .SINIT(1'b0),
        .SSET(1'b0),
        .THRESH0(NLW_U0_THRESH0_UNCONNECTED),
        .UP(1'b1));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2025.2.1"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
H+Yx0WHMrhOVb3Z5v4ApnlDqLIjrQT6ghEPm8cybrmURzRFia8RhWN1SQNQXYRk1MxzgaoS1ensQ
Eek+UYxIV2wui175kGy01PyVCfZLz2AOj3d3itEA+TAvrnQdNI8jJTN8gRKO77xNfuDUMkUbjy7V
dJ59dXW+5NLlsS73Rrw=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
MdUch67tovshbaRk5WxLcwC67FeY/T7HbRhXHMJc5O9jo5kwUDmuaA3bQTl2aFQOflLhtjEzC1PS
y+4sXYREULonTVQ1yqLNEAh7SnQO7n/vXxG2rHtzzVB2HnGV6Vh3SfY0jzgfriz+7JBZElnObLaT
z8J9d/n1jAUZ5tV5hoXueFksjYLVFylcl8yLg6s0ESiBeMQwD+xYO614LwUn7pqf+73g0TII34fm
zwgRNA/qso7yIgVX/WKi/gxRZ+4BbdUnAIjrTkYCqlSEtOGUYv/nszHBff828SYWL1wlui6y6z3j
d9R/JEqHpjGm3hWrGhFLa5K/OJSP4H5AYSC7Ng==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
P41O14g7IzXdGL1z+adTRuzMlSs4/u0Rymx9dK/+1+PC0seBmiEGK0SDIC9g9d95QddLOwJx86rV
jNNPJkfWblHJtO/lW/LsiMAFSSwsb1iYhiVdJRIEvTKp++TztX5zszlJQ+iMgWE2jDY6cEs6ytO4
9iUkBhXnTFuEi8eowbc=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
e6KaJig1By6gJwQUX/wQUYQiXey8d6gScylu2wOdINrF2T1e2lRXW52f+pqfyKfo5Ka7d15fYBsC
wxhsl6aRVNusKPs1TQKgHDgjnSyHatqzPLRroaJE9emKy4uGCxjJCbtXYGyp7YLXm7Q8NlMbFWMp
QDQO+IYoz66h4KTYNoqbHOC3ZF+bAlKSOwTtpKoZibYhX2K5F86qwE060MK+MjhXxzqpCBkb3y8l
ub5FfZkUPrYXO9U9GVR1zffgK/P+6uf9N8w1BTGfYdQg94LpG82X5rHmym4jE5WJR4tm0vz6VuSq
Mes15YcdiNE5DOCzSh/FrqpzhiLzxiOYLtmi2A==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
roqUwOyTPIS0n639lU2WhhFzEbdae+p+xHXYEHQ79PdrNBy+sE1aPht8zoLNjTtcY9Ye/Cx1Evr5
abM1MGc22jV4tObvXSiillZ4d2VnYj2L9gzohe0/ubmvsf/aAhXbJYgwnyKPi4c9PyGCd1523kkx
Ffbwqqi1iaQIkkCLO/spI150uuMxTDF0OLTEPna3H1MmYgVY1Xyoh8dJ2Gbkb3EYQnKx40Cq5ffe
CIS8uXF5cG9XAhicE3U5+8f1+3W0em7ZE5+Kn4vIBgxRVl+O1fBNqfZSGDjPbwglcuMEB3Lg0lnW
B1e4P2QMmATimZTKv1oLAZfUkKHLKmGIAsW5Vw==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2025.1-2029.x", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
G1cJuvMVz+Qw2RGaJ0m3GrDmrvCybz1oe/Yyx/PQBkpq0YtDvucaF0WAIt65UHxU2amNsVnsiTkW
h8VqjXUQra8aUM3nQfeETQah+t2t9bWlnsV8T0e4QycB/5dLFKvdv898mpalQuanl98hnEVFQJGm
8e7rXEnNQLf04xhXZk/sW0CBTJd5Pb94qAr6IaTxKWVRBXJKSjDTikRI6HmR3zECSRnfqATzZj/0
gO52ZV+eZ4jYie9SEOU9oeH36FJU9ZuC5rqwyHQI2+WLwbeGgF/o94hWTBACkplgSIl7HoB9G4K0
xr0xgRkxKfhW105CFMUVzcDJ9jrt5CKdyeEq9Q==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
ITK89PgZD+LUTPSipS3NQDk6X9ILb36hBuV9a35anwObPo7XBlN/s2bLTVCT5i4cSOSA34wlUwzI
dyNYwkqBsKUfxiSN58/dAzs0EWsj3s8R8l5txfrdO+ci9l8X72eC4+b/aR7FzfL6TM/kYHnhnnGQ
JMorAH0P+d5aKUAFX8CXwxblOEAj+rRYYTScY/eZ6IC7RT2uVjp7g9Ry3oOchuiHYy7dTSE95rdA
ktToDH2nf+ZxOqVL3Cl4oYf+laoGcoIS4duB1zU40als5SuZyEFjEqoRvQWEVkiZjLknx6GDafbR
wdxIuiVG/54Q8Bz1d0TVoP3IqiktVrbwJbTOGQ==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
Wz5IZDQUkk6w3o4WdzdnortJEWdqsZKFOJRbyuW0N4KG2e7olpe1GAxGczR5bWKcIdmOkjj01MaL
5X6ESxRWR/AkJTE9mw+hmucEO0GjfnlKUxDhWKzeo/Sh4qaDtBsAf3v1lJu1UN5ueGyWMnOsfgN5
4BgvJB6egJabOrNAWSZcQL69sVJJsqbxUS2EgV8baCbdDUE+hIIUWypQrVbXOZA1el/wCgrxkbXV
djqI2Sg+3EUWqYFlkO9pAQ+WGv6QOmnttZGOrcK2QUW8gqSZfY3UjBBFVE+fEHI9sepbwgBy7Kac
JsZmVBa8rcFCcQuPq7IIUIsmB3cwp1JyDXVQhOcQcmy2An7SWbqHOis67eO01q9uXTutuWlJbvJu
CaGhpq0axzE9lrUWRJF46CUH5JWYkwW9QoqtC8VgsJzFSdKTj9DlmOeD99IPqqJxLgew/NAhve/b
rkOHzjqxUbgl/bQNwR6oFhQ6ZCrkVWO7go2vCujm/YcF4ovg7ksy0ekS

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Qjv5FCNScF7yVJPH9Wg6QREQTLkPawNqGWOoZBaO1hoQVflZwgfqMC91DZGShk8+cnsfIpDsETXB
QCeQWF8fXXNKcDr4qqXQPcnX/qHhhpugJZe/azTaZBjuGXzyFPrs/L30NcOKZTScVuKieg8S8v5M
ERWA0+fmL8t0JhczHzOMb0ccZmtOswUlU8Dv6xa2BmND/iZBX673N/z0u15oekjJ/EJWerbn/0ID
vBiFH/aGHHBdaQi8niq2ZtKXD9Eh79X4hb1AdKHM0cVZcsSLXfdHo1X90oy5FSFC+avlUbkvXKke
CZgl/gjI0EyrjPVTiAvKAjvoEcwTFxAO7+233Q==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
QLl5fttRVGtWrV7iTtzYccioCpTIp5wQmXNR8IHM1i7RSEy5gXeUwnLvxH9woswXnPn5ATDsuB6O
/bUvtwPZ7vp4HdXytxaeqw97nR4Vq2J5DT17JxOeuyrHqjmjEEnUEQ+lbCOQKgTzFn2twK7L5/I4
0LQWr4/1K/4LYFsX0d1fcs2U9FRrKzB1aTdfDsAh1yQvcQydOgMagA72pR9fJmfLDB8vYdk5KIlp
Qyhc+0S+NFNUDe30TZS3wLqxxCaTVwmiFemeghfe/mCZo9RGd0VvTJFiyMALn01j/TUFHqTh1jrM
HlJdrbtUAJG3ihq9VpHabzJvD7BDUxPBp0A1zA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
fyuAqjbKJ8crvqKt0DSDhDR/KWlbsL4Z0uIbDBcxDAp99x8GV7NNXo8JE/8guO8lNTlTPIFnFSx6
ylhS+R2lVnJ1omxwqxPp+GF8zyRdM968b3bImsbegSEgtm3UwrX3z8zDFj9DLOH4/VAqcA/leaaK
VncicNvsUyzh7oHD+XmQ7veyik74t8bRLjBy6iXC0Su4vOrmpLRVpRptIeScFd9crUqeZkHLC0bB
ggBNq/KUW9mcPP8c48nuIVNpxACeqvoNB3tPpLaaMEow0R4VSj9Hm5dE1y3i8GlqLkHGaVbP2+Sk
U0f1tj8ziJqHVh+TJZAfsTB6ILiOcbscHnpLbQ==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 2400)
`pragma protect data_block
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
LOh6boVs
`pragma protect end_protected
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2025.2.1"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
Sv0jrqSHs7TyXc6QC9kmfLu9HZHAeNR5V0DspfkniyoEqR5Jr6hiITi8xKRORo+MQW5PXllc81k/
z75BA6SM+1VdgP0XBkF3pMNd7XUuWompFycF5+RmFAdxZYUCujtSLAf95+4uE/1NEL7XqZvNU+zP
Mbh8lnynTlab8p8cPwA=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
K+zcltr5xdBg+pU7XrIDMcBK0zp1FCrhlAdcijS89sRK/kpbhVrWfa9n3bg6ScoJkmJmQrIkZy9n
oRWpyBeXkcZMxm/JEIZp0Fb05gQFWchZOCKjHsUp9DbK1DbivZc59HEZcS7rmBQm5BMbeLVbo/dM
4txaHkbPPvwZyzDNo1D8I8wACKWMa0fI15/0Cq04QyiU5j44JWi2whqhV77Ob8u6OBa+mFAk4+sz
WyX7G7gTaAPgKIBtTCUGG3+rNE26bVwmF+N0+ddOeZ8xBFpWT7m5SdFSgrMEWdFxB2l30ygKw/Mo
T1zDJ1jghPFXr3FWP42r1BJY2ICBxRlBuenxOg==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
gpyrV+3Q6ztkr/kxWBOpxV/M/JYL6+c128JulWIFjK+I3duUJukmXMOOsWC01ZivBVxeQNLT3TUf
ypjH3gxb8Dxz2zSs/KNN4mSoM855mRCLsUP3Y1+GvEd5e1U0Y+0/eqC8Cg+2qSWUVX5Pa/HJfLIW
hGaw0s6kzV3zybtURu4=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Ec0pFT4eR0KaAJ7YQo99q7I788TYmPBZjMlbuxyMTazE1LbJTgJ1wdoH9G9n7j6rF7e7fXUl2vl2
3iClYgBcvl6RZpMro7ItvWgxkVLs1RfOtL/cNFBRJSDzG7DCc7ID+afyM1FtI4lkvbjbeCdJa1nx
qmTZrPWv0BAIVtGNUAl1xQ1ZfWZ5OoOolumcSrLo+y7RACBfyLwvJrJflRCzF7Kqgu5aJ1aIvrJ7
7uV/b5sIvbEFgy6J8Gkl3I3uq0L55yDSA4anHreny7jRtymOTOfsREtZwsdRfXmGnSFw2omZSNpf
K8FJ+zR/76u9iOPb77rapk5+RX5tr0xW5Qorxw==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
tdyxyVXRduyHY1QzrMYxcbM+ZP8uMiHWcXGs0kaPbva90gz7tK7PTrULtLHIH5HcK+7GvIGrnXGN
4+AkHCoPhOumVEm0KP6FK9VIhP28XT6JGwD9jyrQX5JUoUufUxVKAcThpox6YxcxGB3dq3sNbWVO
dlL6rg+aBiexiDQJ9YkHslPdBhAxbk+IFylYPW4Senxa9Ychdveqa92zckFz7Epyxz4ZMbpXsBS6
WMoCJzFQwBYHSS1KLV2JnxrFikofJ7CSWAf9zQbSeRM8xLhZrspLU/HLGB3zMVmvec+v09t7mRf2
UIGRw7N+956mVUpSWN9vBsn1EGzb7PZphtbOxQ==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2025.1-2029.x", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
oehienw9BYIMAfskCL8/qbFaGSa+TWi76n0+5qT/KQEuFyvHvsK+ilxJpWxRWd/5Omr8RQnPl9Qx
5QiEut6P7lv9chHPmhinGXMWVlKu1uAB8QmhOCXX/Vm0Az20ECY/OTA+eZhqmaBE1UHQ34Me9yW4
EBiZsm63Kfoda3Al07T/Q2z/HsRE/jifXobeHFgrBkHK1zFPzbw7bpek4fJW7tqd3DXBLBGjTU1A
ZNNetepEq/8URS4CglUrfPKUYYzjBF1wGV7G1GznkwK06htnulZkcuC+SZuJllVlbRc0wuWsQ2Qm
pHlWlE+mNidA13iAcdUyQY1G7xzMxNh+xv3RXw==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Hs7Uy2t1QLzwwWD0b9/RBy6topbmaFkrmcX62Rj4xDu/phCZsKlXms3Lj8Hf9UocSbeBrU5fUOjf
j+CGwX+LyjAYwXkiXQozOhOFqO6Ka2U3gZmYUBjxaSi6ILYHtLD4Eabq7SLLczC5Lwv6tgraVCzf
mCsG57AWFhWQU6jtft9P4CkYpAp+8bmCZ21U9I1jGXgc14c4qtwTLJrjjrg/DDVK6vs6DK6zySJV
bcan+gA3aBuodLjUpdGIKvlyW0VuydG8MX3wV9p0zWLzGXVf1qHXhjl3b7PYU40qOJjPpn8lnJjH
FQAFYCHDUheypS1X09o4tljqybxvR17ztJEwqA==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
i4MR69wgPU55SLC/r8n8h6M3RijbYZrOZEmhHircteFH/Le1qKcJbHZGu0kEQpAnkCiQn4jsBUsm
Se4oSvmc8r2bJxnAIqTYxgFBqe89D2LaiCnbv1yhIEG/gppVDyntrz4NHemamb35R+HeA/zoI+E4
X3cJQ1XsOLEt8RImwdYGm/M2q/rgP0mSJu0smhCw7ZvzPiNcywR9NKhwEFy/tHJqm1uKjwfXD/e2
ODKqEbpWNwrKBl8oid19vcay/Wux2OMofAhNG/P/ISubbI7l5X4aKMo5MyXHR/lMopamqDVFPj7d
PepkdWc2adoj95adiPIXsXG21dcAK2mVoFIB7zHEonszU3oI9k9E2pkpwuSdqdyAOksB8Jj2pIB0
mGUQRfwBuiCHWu1fyBLtLE5Z596mmgNTgp/6hGmBIAHq74CgXTqShmhiZmIa6jpnUaRbQJipksKb
M2er+U996ZrZst5zVU/d3YmfuguawO1L0WF211kqVVn1ZolCyypdiqdj

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
HTcfiYRI2jciXsfRu3uI5zuMszgb658LvmHoZa9l9eAjnszvNX74MRn7Pk+W0jp477kwn83eEsNF
hcEhiWLXgQUzqHQ5NX6B6V1TRkC1ciTtlWUyf+qpAO1yNpvvMSICRU+o8Dp8XFXAvl2c73a1ETJ1
NzAy6LCCrQ9+Dq24fJX0+/LRVd8f5r42DNPRxTr7yDhs8iAloeWU8XvINeAoL36HAGwVEKp1bLWD
+udwJ+0ALVf+r4oQnYHkPYlkg1XPRrS2XRYQKxHOKYBTRBxIDTKYHj8xTSrI972Kj3yrHPIj+4om
/JBqpSnNen4HOWOTUlDKsr/f2x0biz9aErdsTQ==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
RZzTG9Dfliiz4I2KjCZEYng+hpqVHPV+OTTP78mazWxKutHHgwu2WIgUp79iD6W7bk+Ju/JwhrRp
iGv/lxme742KzYLlCcBt1XEE84UkyYT7A7n4d1thwxFKzAbst5+s/lJU3kgt5yEylDDgzYjY8ra3
rlmT0qrgMf7mjBX9rMubFLf7MrlgV3GLE9YNFVfc1NdYa8uO7ioVntr1H8X/Y1GxfUyTN9zTq4VL
hP+6y0iRsjt/jGuCASvsrkWkrBAt8tSjsMn6LKa+FbmScouXI65Y+hD2Qia9w7LblyymjZsDoSAA
SFHu+sfDQuLazmqMilqPO8rqtA9a2gkhS4vB8w==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
RHuPoya9KA5sxsbukfImWTADo1qRp9UA9uhSd87G+ZHIiJ4yCvl7t4zL8xjmmtjaUtAar6ptoHsK
yufE68dYpGjX7bSEMmqzCqjdhSb9Ps24oykRlJjWsDsANIMGCCnPPWPgAT2PEHJU3SKH8RA3DQ5E
pYRBNCsKawuXaoPeFPxepNczHmi0eRFyzEnWUSdZsOsRnSqArDPGriLrJBz0bcP7XiqV8vJjEIwP
fQIgEeSYhQZJyccdd/W65IN8FccyYqbsDe6YxCNC0vzkXBNAjKvHLI+qXz3GhryRUXs97CBm8qhT
3szcmAup8WRJZ2RYK3rWwxVb35nI0RLC3dxrDw==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 9648)
`pragma protect data_block
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
3FzVmHvbPNPmglmItWZH
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
