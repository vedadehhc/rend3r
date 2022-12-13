import sys
import getopt
from io import TextIOWrapper
import numpy as np

usagestr = f"""
{sys.argv[0]}: generate REND3R programs
usage: {sys.argv[0]} <program> <dest> 
arguments:
    program: which (preset) program to generate. Options are:
        sphere
        cube
    dest: destination file (.rdr)
"""

def usage():
    print(usagestr)
    sys.exit(1)

def write_triangle(f: TextIOWrapper, idx: int, vertices: list[float], color: str):
    assert len(vertices) == 9

    labels = ['x1', 'y1', 'z1', 'x2', 'y2', 'z2', 'x3', 'y3', 'z3', 'col']
    vertices.append(color)

    for i in range(0, 10, 2):
        f.write(f'tr {idx}, {labels[i]}, {labels[i+1]}, {vertices[i]}, {vertices[i+1]}\n')

def generate_sphere(f: TextIOWrapper):
    center = [0, 0, -1.5]
    rad = 1
    NUM_PHI = 5
    NUM_THETA = 5

    top = [center[0], center[1], center[2] + rad]
    bot = [center[0], center[1], center[2] - rad]
    rows = []

    phi_vals = np.linspace(0, np.pi, NUM_PHI+1, endpoint=False)[1:]
    theta_vals = np.linspace(0, np.pi * 2, NUM_THETA, endpoint=False)

    for phi in phi_vals:
        r = []
        for theta in theta_vals:
            r.append([
                rad * np.sin(phi) * np.cos(theta) + center[0],
                rad * np.sin(phi) * np.sin(theta) + center[1],
                rad * np.cos(phi) + center[2]
            ])
        rows.append(r)

    tri_count = 0

    for j in range(len(rows[0])):
        nextj = (j + 1)
        if nextj >= len(rows[0]):
            nextj -= len(rows[0])
        
        write_triangle(f, tri_count, [*(rows[0][j]), *(rows[0][nextj]), *top], '0b00000_111111_00000')
        tri_count += 1

    for i in range(1, len(rows)):
        for j in range(len(rows[i])):
            p1 = rows[i][j]
            p2 = rows[i-1][j]

            nextj = (j + 1)
            if nextj >= len(rows[i]):
                nextj -= len(rows[i])

            prevj = (j - 1)
            if prevj < 0:
                prevj += len(rows[i])

            write_triangle(f, tri_count, [*p1, *(rows[i][nextj]), *p2], '0b11111_000000_00000')
            tri_count += 1
            write_triangle(f, tri_count, [*p1, *(rows[i][prevj]),  *p2], '0b00000_000000_11111')
            tri_count += 1
    
    for j in range(len(rows[len(rows)-1])):
        nextj = (j + 1)
        if nextj >= len(rows[len(rows)-1]):
            nextj -= len(rows[len(rows)-1])
        
        write_triangle(f, tri_count, [*(rows[len(rows)-1][j]), *(rows[len(rows)-1][nextj]), *bot], '0b00000_111111_00000')
        tri_count += 1


def generate_cube(f: TextIOWrapper):
    pass

def main():
    opts, args = getopt.getopt(sys.argv[1:], ":")

    if len(args) != 2 or len(opts) != 0:
        usage()

    dst_path = args[1]
    prog = args[0]

    print("Writing to", dst_path)

    with open(dst_path, "w") as f:
        f.write("nr\n")
        if prog == 'sphere':
            generate_sphere(f)
        elif prog == 'cube':
            generate_cube(f)
        f.write('nf\n')
        f.write("er\n")
        f.write("er\n")

if __name__ == "__main__":
    main()