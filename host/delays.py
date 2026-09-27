import numpy as np
import itertools

PULSER_CLK_RATE = 156.25e6

class Args:
    def __init__(self):
        self.number_active_elements = 8
        self.focus_distance = 0.010
        self.steering_angle = 0.0
        self.sound_speed = 1540.0
        self.dt = 1/PULSER_CLK_RATE
        self.channel_offsets = np.linspace(0, (self.number_active_elements - 1) * 500e-6, self.number_active_elements)
        self.channel_z = np.zeros(8)  # element position towards the target
        self.origin_x = 0.0           # beam origin along the array (steering is about it)
        self.tau = np.zeros(8)        # per-element extra latency (calibration.csv)

def beamforming_delays(args: Args):
    """
    calculate the beamforming delays based on the focus and steering settings

    """
    # create indexing variable
    element_index = np.arange(-(args.number_active_elements - 1) / 2, (args.number_active_elements + 1) / 2)

    theta = args.steering_angle * np.pi / 180
    x = args.channel_offsets - args.origin_x
    z = args.channel_z

    # check for focus depth
    if np.isinf(args.focus_distance):
        # calculate time delays for a steered beam
        delay_times = (x * np.sin(theta) + z * np.cos(theta)) / args.sound_speed  # [s]

    else:
        # calculate time delays for a steered and focussed beam: each element
        # fires (F - |focus - element|) / c after a hypothetical element at
        # the origin, so all waves reach the focus together
        F = args.focus_distance
        dist = np.sqrt((F * np.sin(theta) - x) ** 2 + (F * np.cos(theta) - z) ** 2)
        delay_times = (F - dist) / args.sound_speed

    # an element with extra latency tau fires tau earlier (same convention
    # as the client's generate_delays)
    delay_times = delay_times - args.tau

    # convert the delays to be in units of time points
    delay_times = (delay_times / args.dt).round().astype(int)
    return delay_times

def beamforming_main():
    scanlines = 256
    min_angle = 20
    max_angle = -20

    # relative to channel 0; columns x_m, z_m, tau_s, sign (calibration.py)
    calibration = np.loadtxt("calibration.csv", delimiter=",", comments="#")
    channel_offsets = calibration[:, 0]
    channel_z = calibration[:, 1]
    tau = calibration[:, 2]



    # beam origins spread across the aperture, from x_max (line 0, the +angle
    # end) to x_min (last line), as the client's scanline_origin
    x_min, x_max = channel_offsets.min(), channel_offsets.max()
    origins = np.linspace(x_max, x_min, scanlines) if scanlines > 1 else [(x_min + x_max) / 2]

    final = np.zeros((scanlines, 8))  # 20 angles, 8 active elements
    for i, a in enumerate(np.linspace(min_angle, max_angle, scanlines)):
        args = Args()
        args.focus_distance = 30e-3
        args.steering_angle = float(a)
        args.origin_x = float(origins[i])
        args.channel_offsets = channel_offsets
        args.channel_z = channel_z
        args.tau = tau
        final[i, :] = beamforming_delays(args)
    final -= np.min(final)

    return final



# fire one at a time, to get impulse response
def calibration_main():
    final = np.zeros((8, 8)) + 0xffff # 0xffff is do not fire channel

    for i in range(8):
        final[i,i] = 0
        pass
    return final

def pairs_main():
    final = np.zeros((len(list(itertools.combinations(range(8), 2))), 8)) + 0xffff # 0xffff is do not fire channel
    for i, (a, b) in enumerate(itertools.combinations(range(8), 2)):
        final[i, a] = 0
        final[i, b] = 0

    return final


# final = calibration_main()
# final = beamforming_main()
final = pairs_main()

for i in range(final.shape[0]):
    print(','.join([str(int(x)) for x in final[i, :].tolist()]))
