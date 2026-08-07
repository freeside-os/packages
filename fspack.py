#!/usr/bin/env python3
import sys
import os
import subprocess

# If we are already in packages/, fstools might resolve packages/fstools
cwd = os.getcwd()
if os.path.basename(cwd) == "packages":
    os.chdir("..")

args = sys.argv[1:]
if args[0] == "verify":
    cmd = ["/home/dq/Code/freeside/build/fstools", "pkg", "verify"] + args[1:]
    sys.exit(subprocess.call(cmd))
else:
    cmd = ["/home/dq/Code/freeside/build/fstools", "pkg"] + args
    sys.exit(subprocess.call(cmd))
