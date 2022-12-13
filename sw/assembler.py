import sys
import getopt
import numpy as np
from bitstring import BitArray

usagestr = f"""
{sys.argv[0]}: assemble REND3R programs
usage: {sys.argv[0]} [-b] [-o dest] <source> 
options:
    -b: print in binary instead of hex
    -o: set the output file
TODO:
    REWORK REGISTERS BASED ON NEW ISA
    generate dump file (instruction/binary side-by-side)
"""

class RenderSyntaxException(Exception):
    def __init__(self, *args: object) -> None:
        super().__init__(*args)

PROP_SIZE = 5
class PropList:
    def __init__(self, plist: list[str | list] = []):
        self.plist = []
        for i, p in enumerate(plist):
            tp = "f"
            if isinstance(p, list):
                tp = p[1]
                p = p[0]
            
            self.plist.append({
                "bit_array": BitArray(int=i, length=PROP_SIZE),
                "index": i,
                "reg_name": f"a{i}",
                "sym_name": p,
                "type": tp,
            })
    
    def __contains__(self, name):
        try:
            x = self[name]
            return True
        except:
            return False

    def __getitem__(self, name) -> dict:
        for p in self.plist:
            if p["reg_name"] == name or p["sym_name"] == name: return p
        raise RenderSyntaxException

class Instruction32:
    def __init__(self):
        self.a = ["0"]*32
    
    def __getitem__(self, i):
        return self.a[i]

    def __setitem__(self, i, x):
        self.a[i] = x
    
    def set_range(self, i, j, x: str):
        self.a[j:i+1] = [c for c in x[::-1]]
    
    def get_range(self, i, j):
        return "".join((self.a[j:i+1])[::-1])

    def __str__(self) -> str:
        return "".join(self.a[::-1])

def usage():
    print(usagestr)
    sys.exit(1)

def syntax_err(msg: str):
    print(f"\nSyntax error on line {line_num}:\n\t{line}\n{msg}\n")
    sys.exit(1)

# return n-bit BitArray
def parse_int(num: str, length: int = 16) -> BitArray:
    num = num.replace('_', '')

    if len(num) > 2 and num[0:2] == "0x":
        # hex
        try: return BitArray(uint=int(num, 16), length=length)
        except: raise RenderSyntaxException
    elif len(num) > 2 and num[0:2] == "0b":
        # binary
        try: return BitArray(uint=int(num, 2), length=length)
        except: raise RenderSyntaxException
    else:
        # decimal
        try: return BitArray(uint=int(num), length=length)
        except Exception: raise RenderSyntaxException

# returns 16-bit BitArray
def parse_float16(num) -> BitArray:
    try: return BitArray(float=np.float16(float(num)), length=16)
    except: 
        try: 
            i = parse_int(num)
            f = float(i.int)
            return BitArray(float=np.float16(f), length=16)
        except:
            raise RenderSyntaxException

camera_props = PropList([
    ["zero", "i"],
    "xloc",
    "yloc",
    "zloc",
    "xfor",
    "yfor",
    "zfor",
    "xup",
    "yup",
    "zup",
    "nclip",
    "fclip",
    "hfov",
    "vfov",
])

light_props = PropList([
    ["src", "i"],
    "xloc",
    "yloc",
    "zloc",
    "xfor",
    "yfor",
    "zfor",
    ["col", "i"],
    "int",
])

shape_props = PropList([
    ["zero", "i"],
    "xloc",
    "yloc",
    "zloc",
    "rrot",
    "irot",
    "jrot",
    "krot",
    "xscl",
    "yscl",
    "zscl",
    ["col", "i"],
    ["mat", "i"],
    ["type", "i"],
])


triangle_props = PropList([
    ["zero", "i"],
    "x1",
    "y1",
    "z1",
    "x2",
    "y2",
    "z2",
    "x3",
    "y3",
    "z3",
    "none",
    ["col", "i"],
    ["mat", "i"],
])

def parse_prop(prop: str, prop_type: PropList) -> dict:
    return prop_type[prop]

def parse_line(ln: str, ln_num: int, hex: bool) -> str:
    global line
    global line_num
    line = ln
    line_num = ln_num

    # print(line)
    line_split = line.lower().split(" ", 1)
    cmd = line_split[0]

    args = []
    if len(line_split) > 1 and len(line_split[1].strip()) > 0: 
        args = [x.strip() for x in line_split[1].strip().split(",")]

    instr = Instruction32()

    # print(cmd, args)
    
    if cmd == "er":
        if len(args) != 0: syntax_err()
    elif cmd == "nr":
        if len(args) != 0: syntax_err()
        instr.set_range(10, 9, "01")
    elif cmd == "nf":
        if len(args) != 0: syntax_err()
        instr.set_range(10, 9, "10")
    elif cmd == "lr":
        if len(args) != 0: syntax_err()
        instr.set_range(10, 9, "11")
    elif cmd == "cam":
        if len(args) != 2: syntax_err()
        prop = parse_prop(args[0], camera_props)

        if prop["type"] == "i":     data = parse_int(args[1])
        elif prop["type"] == "f":   data = parse_float16(args[1])
        else:                       raise RenderSyntaxException
        
        instr.set_range(2, 0, "001")
        instr.set_range(15, 11, prop["bit_array"].bin)
        instr.set_range(31, 16, data.bin)
    elif cmd == "lt":
        if len(args) != 3: syntax_err()

        idx = parse_int(args[0], length=6)
        prop = parse_prop(args[1], light_props)
        
        if prop["type"] == "i":     data = parse_int(args[2])
        elif prop["type"] == "f":   data = parse_float16(args[2])
        else:                       raise RenderSyntaxException

        instr.set_range(2, 0, "011")
        instr.set_range(8, 3, idx.bin)
        instr.set_range(15, 11, prop["bit_array"].bin)
        instr.set_range(31, 16, data.bin)
    elif cmd == "sp" or cmd == "tr":
        if len(args) != 5: syntax_err("Wrong number of arguments")

        props_list = shape_props if cmd == "sp" else triangle_props

        idx = parse_int(args[0], length=19)
        prop = parse_prop(args[1], props_list)
        prop2 = parse_prop(args[2], props_list)

        if prop["type"] == "i":     data = parse_int(args[3])
        elif prop["type"] == "f":   data = parse_float16(args[3])
        else:                       raise RenderSyntaxException

        if prop2["type"] == "i":     data2 = parse_int(args[4])
        elif prop2["type"] == "f":   data2 = parse_float16(args[4])
        else:                       raise RenderSyntaxException
        
        instr.set_range(2, 0, "101")
        instr.set_range(5, 3, idx.bin[::-1][2::-1])
        instr.set_range(10, 6, prop2["bit_array"].bin)
        instr.set_range(15, 11, prop["bit_array"].bin)
        instr.set_range(31, 16, idx.bin[::-1][18:2:-1])
        
        instr2 = Instruction32()
        instr2.set_range(15, 0, data2.bin)
        instr2.set_range(31, 16, data.bin) 

        ba1 = BitArray(bin=str(instr))
        ba2 = BitArray(bin=str(instr2))

        if hex:
            return ba1.hex + "\n" + ba2.hex
        else:
            return ba1.bin + "\n" + ba2.bin
    else:
        syntax_err()
    
    ba = BitArray(bin=str(instr))
    if hex:
        return ba.hex
    return ba.bin

def assemble(src_path, dst_path, hex):
    try:
        with open(src_path, "r") as src, open(dst_path, "w") as dst:
            for i, line in enumerate(src):
                try:
                    if (line.strip().startswith("//")): continue
                    dst.write(parse_line(line.strip(), i+1, hex))
                    dst.write("\n")
                except RenderSyntaxException:
                    syntax_err("")
    except IOError as e:
        print(f"Could not find source file: {src_path}")

def main():
    #  first arg is source, second arg
    opts, args = getopt.getopt(sys.argv[1:], "ho:")

    if len(args) != 1:
        usage()
    
    src = args[0]
    dst = None
    hex = True

    for o, v in opts:
        if o == '-o':
            dst = v
        elif o == '-b':
            hex = False
        
    if dst is None:
        dst = f"{src[::-1].split('.', 1)[1][::-1]}.{'hex' if hex else 'bin'}"
    
    print("Reading from", src)
    print("Writing to", dst)
    assemble(src, dst, hex)

if __name__ == "__main__":
    main()