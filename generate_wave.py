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
        self.table_size_hex_len = int(math.log2(self.table_size) // 4)

    def generate(self):
        if 'sine' in self.args.t:
            generate_sine()
    
    def generate_sine(self):
        step_size = self.output_max_size // self.table_size
        fill_loop_size = self.output_width - int(math.log2(self.table_size))
        idx_hex = ""
        out = open(self.args.d, 'w')

        for sample in range(self.table_size):
            rad = (sample / self.table_size) * 2 * math.pi
            sine = math.sin(rad)
            shifted_sine = sine + 1 # shift up by 1 and multiply by half of range; mapped: -1 = 0x0,  0 = MAX / 2, 1 = MAX
            sine_hex = '{0:0{1}x}'.format(int((self.output_max_size // 2) * shifted_sine), self.output_width_hex_len) # format specifier

            if self.args.q:
                out.write(sine_hex)
            else:
               # print(sine_hex)
               # print(sine)
                idx_hex = '{0:0{1}x}'.format(sample * step_size, self.table_size_hex_len)
                #print(idx_hex)
                out.write("{0}'h{1} \t:\tval_out <= {2}'h{3};\n".format(self.output_width_hex_len, idx_hex, self.output_width_hex_len, sine_hex))

                # if have more input values then samples, hold last sample for OUT_WIDTH - log2(NUM_SAMPLES)
                i = 1
                while i <= fill_loop_size:
                    idx_hex = '{0:0{1}x}'.format((sample * step_size) + i, self.table_size_hex_len)
                #    print(idx_hex)
                    out.write("{0}'h{1} \t:\tval_out <= {2}'h{3};\n".format(self.output_width_hex_len, idx_hex, self.output_width_hex_len, sine_hex))
                    i += 1 
                sample += i

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', choices=['sine'], help='type of wave to generate', required=True)
    parser.add_argument('-n', choices=['4096', '8192'], help='number of samples to be generated', required=True)
    parser.add_argument('-f', help='generate full period instead of quarter')
    parser.add_argument('-q', help='generate verilog ready lines of sequential logic')
    parser.add_argument('-d', help='output file', required=True)
    parser.add_argument('-r', default='16', help='output bits width')
    args = parser.parse_args()
    gen = Generator(args)     
    gen.generate_sine()

if __name__ == "__main__":
    main()

