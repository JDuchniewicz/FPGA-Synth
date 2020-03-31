import argparse
import math

class Generator:
    def __init__(self, args):
        self.args = args
        self.sampling_speed = int(self.args.s)
        self.k = 2


    def generate_coeff(self):
        out = open(self.args.d, 'w')
        for i in range(128):
            freq = 2**((i - 69)/12) * 440
            # map freq to cutoff frequency (2 guys' curve seems to be the best choice, experimented with others, cite them)
            curve_val = ((math.exp((2.5 * i)/127) - 1)/(math.exp(2.5) - 1))
            cutoff_freq = curve_val * 32*10**3 # rescale to 1-32KHz
            #print(cutoff_freq) 
            g = math.tan((cutoff_freq/(self.sampling_speed * 10**3)) * math.pi)         
            #print(g)
            m = 1 + g*(g+self.k)
            a1 = 1/m
            a2 = g*a1
            a3 = g*a2
            #print("m:{}, a1:{}, a2:{}, a3:{}".format(m,a1,a2,a3))
            # now convert to Q3.31 format for precision
            a1_q = int(a1 * 2**31)
            a2_q = int(a2 * 2**31)
            a3_q = int(a3 * 2**31)
            
            if self.args.q is not False:
                midi_hex = '{0:0{1}x}'.format(i, 2)
                a1_bin = '{0:0{1}b}'.format(a1_q, 34)
                a2_bin = '{0:0{1}b}'.format(a2_q, 34)
                a3_bin = '{0:0{1}b}'.format(a3_q, 34)

                line = "7'h{} \t:\t begin \n".format(midi_hex)
                line += "\to_a1 <= 34'b{};\n".format(a1_bin)
                line += "\to_a2 <= 34'b{};\n".format(a2_bin)
                line += "\to_a3 <= 34'b{};\n".format(a3_bin) # later add spacing between n and m values '_'
                line += "\tend\n"
                #print(line)
                out.write(line)
            else:
                print("in Q3.31 a1:{}, a2:{}, a3:{}".format(a1_q,a2_q,a3_q))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', help='sampling speed in KHz', required=True)
    parser.add_argument('-q', help='generate verilog ready lines of sequential logic', action="store_true")
    parser.add_argument('-d', help='output file', required=True)
    args = parser.parse_args()
    gen = Generator(args)     
    gen.generate_coeff()

if __name__ == "__main__":
    main()

