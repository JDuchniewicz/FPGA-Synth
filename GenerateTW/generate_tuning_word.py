import argparse
import math

class Generator:
    def __init__(self, args):
        self.args = args
        self.tw_bits = int(args.n)
        self.sampling_speed = int(self.args.s)

    def generate_tw(self):
        out = open(self.args.d, 'w')
        for i in range(128):
            print("number " + str(i))
            freq = 2**((i - 69)/12) * 440
            print("freq " + str(freq))
            tw = int(freq * 2 ** self.tw_bits / (self.sampling_speed * 10 ** 6))
            #tw = 2 ** (self.tw_bits - 2) * freq / (self.sampling_speed * 10**6) # It overflows for big numbers (more than 16 bits??)
            print("tw " + str(tw))
            #rescaled_tw = round((tw * 2 ** self.tw_bits) / (math.pi * 2))
            #print("rescaled tw " +str(rescaled_tw))

            if self.args.q is not False:
                midi_hex = '{0:0{1}x}'.format(i, 2)
                tw_bin = '{0:0{1}b}'.format(tw, self.tw_bits)
                line = "7'h{0} \t:\to_tw <= {1}'b{2};\n".format(midi_hex, self.tw_bits, tw_bin)
                out.write(line)
            else:
                out.write(str(tw))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-n', help='number of bits used for sine calculation', required=True)
    parser.add_argument('-s', help='sampling speed in MHz', required=True)
    parser.add_argument('-q', help='generate verilog ready lines of sequential logic', action="store_true")
    parser.add_argument('-d', help='output file', required=True)
    args = parser.parse_args()
    gen = Generator(args)     
    gen.generate_tw()

if __name__ == "__main__":
    main()

