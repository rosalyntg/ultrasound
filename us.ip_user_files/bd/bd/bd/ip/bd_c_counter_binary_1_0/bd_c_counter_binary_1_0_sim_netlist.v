// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
// Date        : Mon Jun 29 23:06:43 2026
// Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode funcsim -rename_top bd_c_counter_binary_1_0 -prefix
//               bd_c_counter_binary_1_0_ bd_c_counter_binary_0_0_sim_netlist.v
// Design      : bd_c_counter_binary_0_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xcau15p-ffvb676-2-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "bd_c_counter_binary_0_0,c_counter_binary_v12_0_22,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "c_counter_binary_v12_0_22,Vivado 2025.2.1" *) 
(* NotValidForBitStream *)
module bd_c_counter_binary_1_0
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
  bd_c_counter_binary_1_0_c_counter_binary_v12_0_22 U0
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 2352)
`pragma protect data_block
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
EQfo0a/tkB+GnEYypBba
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 9456)
`pragma protect data_block
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
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
