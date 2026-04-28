import sys
import struct

def simple_obj(filename):
    with open(filename, 'w') as f:
        f.write("v -0.29 -0.41 -0.08\n")
        f.write("v 0.29 -0.41 -0.08\n")
        f.write("v -0.29 0.41 -0.08\n")
        f.write("v 0.29 0.41 -0.08\n")
        f.write("v -0.29 -0.41 0.08\n")
        f.write("v 0.29 -0.41 0.08\n")
        f.write("v -0.29 0.41 0.08\n")
        f.write("v 0.29 0.41 0.08\n")
        f.write("f 1 2 4 3\n")
        f.write("f 5 7 8 6\n")
        f.write("f 1 5 6 2\n")
        f.write("f 3 4 8 7\n")
        f.write("f 1 3 7 5\n")
        f.write("f 2 6 8 4\n")
simple_obj("test.obj")
