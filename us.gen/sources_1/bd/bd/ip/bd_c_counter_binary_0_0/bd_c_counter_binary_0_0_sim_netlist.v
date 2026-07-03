// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
// Date        : Mon Jun 29 23:06:44 2026
// Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode funcsim
//               /home/russell/ultrasound/fpga/us/us.gen/sources_1/bd/bd/ip/bd_c_counter_binary_0_0/bd_c_counter_binary_0_0_sim_netlist.v
// Design      : bd_c_counter_binary_0_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xcau15p-ffvb676-2-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "bd_c_counter_binary_0_0,c_counter_binary_v12_0_22,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "c_counter_binary_v12_0_22,Vivado 2025.2.1" *) 
(* NotValidForBitStream *)
module bd_c_counter_binary_0_0
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
  bd_c_counter_binary_0_0_c_counter_binary_v12_0_22 U0
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 2416)
`pragma protect data_block
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
U9VF/l2Som+IE5hFlGES7RvqtySFvQ==
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 9776)
`pragma protect data_block
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
stmqzQ5n8umVPtvOa+YY5Dntz7UNUFvqJN0nRoU=
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
