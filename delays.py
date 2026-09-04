import numpy as np

PULSER_CLK_RATE = 156.25e6

class Args:
    def __init__(self):
        self.number_active_elements = 8
        self.focus_distance = 0.010
        self.steering_angle = 0.0
        self.sound_speed = 1540.0
        self.dt = 1/PULSER_CLK_RATE
        self.channel_offsets = np.linspace(0, (self.number_active_elements - 1) * 500e-6, self.number_active_elements)
        self.tau = np.zeros(8)

def beamforming_delays(args: Args):
    """
    calculate the beamforming delays based on the focus and steering settings

    """
    # create indexing variable
    element_index = np.arange(-(args.number_active_elements - 1) / 2, (args.number_active_elements + 1) / 2)

    # check for focus depth
    if np.isinf(args.focus_distance):
        # calculate time delays for a steered beam
        delay_times = args.channel_offsets * np.sin(args.steering_angle * np.pi / 180) / args.sound_speed  # [s]

    else:
        # calculate time delays for a steered and focussed beam
        delay_times = (
            args.focus_distance
            / args.sound_speed
            * (
                1
                - np.sqrt(
                    1
                    + (args.channel_offsets / args.focus_distance) ** 2
                    - 2 * (args.channel_offsets / args.focus_distance) * np.sin(args.steering_angle * np.pi / 180)
                )
            )
        )
        delay_times += args.tau  # add the channel-specific offsets

    # convert the delays to be in units of time points
    delay_times = (delay_times / args.dt).round().astype(int)
    return delay_times

def beamforming_main():
    scanlines = 256
    min_angle = 20
    max_angle = -20

    # relative to channel 0
    calibration = np.loadtxt("calibration.csv", delimiter=",")
    channel_offsets = calibration[:, 0]
    tau = calibration[:, 1]
    tau = np.zeros(8)



    final = np.zeros((scanlines, 8))  # 20 angles, 8 active elements
    for i, a in enumerate(np.linspace(min_angle, max_angle, scanlines)):
        args = Args()
        args.focus_distance = 30e-3
        args.steering_angle = float(a)
        args.channel_offsets = channel_offsets
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


# final = calibration_main()
final = beamforming_main()

for i in range(final.shape[0]):
    print(','.join([str(int(x)) for x in final[i, :].tolist()]))
