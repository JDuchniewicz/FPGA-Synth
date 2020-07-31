import argparse
import math

# dependencies:
# number of samples cause the output index width
# output bits width cause the sine wave values
class Generator:
    def __init__(self, args):
        self.args = args
        self.output_width = int(self.args.r)
        self.output_max_size = 2 ** int(self.args.r)
        self.output_width_hex_len = int(self.args.r) // 4 # 4 bits is 1 hex value
        self.table_size = int(self.args.n)
        self.input_width = int(math.log2(self.table_size))
        self.table_size_hex_len = int(math.ceil(math.log2(self.table_size) / 4))

    def generate(self):
        if 'sine' in self.args.t:
            self.generate_sine()
        elif 'triangle' or 'sawtooth' in self.args.t:
            self.generate_ramp()

    def generate_sine(self):
        out = open(self.args.d, 'w')
        if self.args.q is not False:
            self.generate_qnotation_sine(out)
        else:
            self.generate_quarter_sine(out)

    # generate a quarter of a triangle OR
    # generate the positive half of the sawtooth
    def generate_ramp(self):
        out = open(self.args.d, 'w')
        self.output_width -= 1
        for sample in range(self.table_size):
            val = int(sample / self.table_size * 2**self.output_width)
            val_bin = '{0:0{1}b}'.format(val, self.output_width) # format specifier

            if self.args.g is not False:
                idx_hex = '{0:0{1}x}'.format(sample, self.table_size_hex_len)

                lhs = "{0}'h{1}".format(self.input_width, idx_hex)
                rhs = " \t:\to_val <= {0}'b0{1};\n".format(self.output_width + 1, val_bin) #leading zero because it is positive only

                lhs += rhs
                out.write(lhs)
            else:
                out.write(str(val) + '\n')
                
    # always generate quarter of a wave for Q format
    def generate_qnotation_sine(self, out):
        self.output_width -= 1
        for sample in range(self.table_size):
            rad = ((2 * sample + 1) / (2 * self.table_size * 4)) * 2 * math.pi # according to zipCPU, take quarter of full wave
            sine = math.sin(rad)
            qnotation_sine = int(2**(self.output_width) * sine)
            sine_bin = '{0:0{1}b}'.format(qnotation_sine, self.output_width) # format specifier

            if self.args.g is not False:
                idx_hex = '{0:0{1}x}'.format(sample, self.table_size_hex_len)

                lhs = "{0}'h{1}".format(self.input_width, idx_hex)
                rhs = " \t:\to_val <= {0}'b0{1};\n".format(self.output_width + 1, sine_bin) #leading zero because it is just a quarter

                lhs += rhs
                out.write(lhs)
            else:
                out.write(str(sine) + '\n')


    def generate_quarter_sine(self, out):
        self.table_size >>= 2
        self.output_width -= 1
        for sample in range(self.table_size):
            rad = ((2 * sample + 1) / (2 * self.table_size * 4)) * 2 * math.pi # according to zipCPU, take quarter of full wave
            sine = math.sin(rad)
            sine_bin = '{0:0{1}b}'.format(int(self.output_max_size * sine), self.output_width) # format specifier

            if self.args.g is not False:
                idx_hex = '{0:0{1}x}'.format(sample, self.table_size_hex_len)

                lhs = "{0}'h{1}".format(self.input_width, idx_hex)
                rhs = " \t:\to_val <= {0}'b0{1};\n".format(self.output_width + 1, sine_hex)

                lhs += rhs
                out.write(lhs)
            else:
                out.write(str(sine) + '\n')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', choices=['sine', 'triangle', 'sawtooth'], help='type of wave to generate', required=True)
    parser.add_argument('-n', choices=['512', '1024', '2048', '4096', '8192', '16384', '32768'], help='number of samples to be generated', required=True)
    parser.add_argument('-g', help='generate verilog ready lines of sequential logic', action="store_true")
    parser.add_argument('-q', help='generate table in Q0.<n> notation', action="store_true")
    parser.add_argument('-d', help='output file', required=True)
    parser.add_argument('-r', default='16', help='output bits width')
    args = parser.parse_args()
    gen = Generator(args)     
    gen.generate()

if __name__ == "__main__":
    main()

