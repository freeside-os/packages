import os

def read_grep(filepath, term):
    if not os.path.exists(filepath):
        print(f"{filepath} not found")
        return
    with open(filepath, 'r') as f:
        lines = f.readlines()
    for i, line in enumerate(lines):
        if term in line:
            start = max(0, i - 5)
            end = min(len(lines), i + 6)
            print(f"--- {filepath} (lines {start}-{end}) ---")
            for j in range(start, end):
                print(f"{j}: {lines[j].rstrip()}")

read_grep("meson.build", "valgrind")
read_grep("src/basic/meson.build", "generated_gperf_headers")
