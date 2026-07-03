import os

def dump_file(path):
    print(f"--- {path} ---")
    if os.path.exists(path):
        with open(path, 'r') as f:
            print(f.read())
    else:
        print("Not found.")

dump_file("/usr/include/net/if_arp.h")
dump_file("/usr/include/netinet/if_ether.h")
dump_file("/usr/include/linux/if_arp.h")
