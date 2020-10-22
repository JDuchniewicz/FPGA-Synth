import argparse
import matplotlib.pyplot as plt
import numpy as np
import math

def twos_complement(hexstr, bits):
    value = int(hexstr, 16)
    if value & (1 << (bits - 1)): # if negative, flip the value in 2s compl 
        value -= 1 << bits
    return value

class Plotter:
    def __init__(self, args):
        self.args = args

    def plot(self):
        results = []

        with open(self.args.f, 'r') as f:
            i = 0
            for line in f:
                line = line.replace(" ", "")
                self.convert(results, line,i)
                i += 4

            plt.plot(np.arange(0, len(results)), results)
            plt.show()
        
    def convert(self, results, line, idx):
        # 0x56 0x34 0x12 0x00
         # 0x00 0x56 0x34 0x12
        if self.args.format == 'S24_LE' or self.args.format == 'S32_LE':
            for i in range(4):
                numstr = ""
                word = line[i * 8: i * 8 + 8]
                if not word:
                    break
                for j in range(1, 4):
                    num = word[j * 2: j * 2 + 2]
                    numstr = num + numstr

                if numstr == "":
                    break
                converted = twos_complement(numstr, 24)
                if idx > 15000 and idx < 20000:
                    print(f"{idx + i} | {numstr} | {converted}")
                results.append(converted)

         # the awkward format of sending 0x00123456 number in 0x00 0x12 0x34 0x56
        else:
            for i in range(4):
                num = line[i * 8 + 2: i * 8 + 8]
                if not num:
                    break
                #print(f"{num}")
                converted = twos_complement(num, 24)
                if idx > 10000 and idx < 15000:
                    print(f"{idx + i} | {num} | {converted}")
                results.append(converted)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', help='name of file with hex values', required=True)
    parser.add_argument('--format', help='format in which it was saved', choices=['S24_LE', 'S24_BE', 'S32_LE'], required=True)
    parser.add_argument('-s', help='stripped', required=False)
    args = parser.parse_args()
    plotter = Plotter(args)     
    plotter.plot()

if __name__ == "__main__":
    main()
