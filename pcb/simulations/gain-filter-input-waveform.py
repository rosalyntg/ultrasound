import sys

clk_rate=20e6
bit_period_per_update=14
rise_time=32e-6
dac_bits=12
#dac_vdd=3.3
dac_vdd=0.01
slew_rate = 650e6 # V/s


time_per_update = 1/(clk_rate/bit_period_per_update)
updates=int(rise_time/time_per_update)
v_per_update = dac_vdd/updates


prev_v = 0
for i in range(updates):
    v_target=i*v_per_update
    adc_val = int(v_target/dac_vdd * (1 << dac_bits))
    v_real = adc_val / (1 << dac_bits) * dac_vdd
    if i == updates - 1:
        v_real = dac_vdd
    slew_time = (v_real - prev_v) / slew_rate
    print(f'{i * time_per_update * 1e9}ns {prev_v}')
    print(f'{(i * time_per_update + slew_time) * 1e9}ns {v_real}')

    prev_v = v_real

print(f'{rise_time * 1.5 * 1e9}ns {dac_vdd}')
print(f'{rise_time * 2 * 1e9}ns 0')


