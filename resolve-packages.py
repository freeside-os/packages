#!/usr/bin/env python3
import os
import sys

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        tomllib = None

def load_manifests(packages_dir):
    manifests = {}
    if not os.path.isdir(packages_dir):
        return manifests

    for entry in os.listdir(packages_dir):
        manifest_path = os.path.join(packages_dir, entry, "package.manifest")
        if not os.path.isfile(manifest_path):
            continue

        if tomllib is None:
            manifests[entry] = parse_manifest_fallback(manifest_path, entry)
            continue

        try:
            with open(manifest_path, "rb") as f:
                data = tomllib.load(f)
            pkg = data.get("package", {})
            name = pkg.get("name", entry)
            manifests[name] = data
        except Exception as e:
            print(f"Warning: Failed to parse {manifest_path}: {e}", file=sys.stderr)

    return manifests

def parse_manifest_fallback(filepath, entry_name):
    data = {"package": {"name": entry_name, "dependencies": []}, "build": {"dependencies": []}}
    try:
        with open(filepath, "r") as f:
            lines = f.readlines()
        
        current_section = None
        for line in lines:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("[package]"):
                current_section = "package"
            elif line.startswith("[build]"):
                current_section = "build"
            elif line.startswith("["):
                current_section = None
            elif "=" in line and current_section:
                key, val = line.split("=", 1)
                key = key.strip()
                val = val.strip()
                if key == "name":
                    data["package"]["name"] = val.replace("\"", "").replace("'", "")
                elif key == "group":
                    data["package"]["group"] = val.replace("\"", "").replace("'", "")
                elif key == "dependencies":
                    deps_str = val.replace("[", "").replace("]", "").replace("\"", "").replace("'", "")
                    deps = [d.strip() for d in deps_str.split(",") if d.strip()]
                    data[current_section]["dependencies"] = deps
    except Exception as e:
        print(f"Warning: Fallback parser failed for {filepath}: {e}", file=sys.stderr)
    return data

def collect_deps(name, manifests, visited):
    if name in visited or name not in manifests:
        return
    visited.add(name)
    data = manifests[name]
    runtime_deps = data.get("package", {}).get("dependencies", [])
    build_deps = data.get("build", {}).get("dependencies", [])
    for dep in set(runtime_deps + build_deps):
        collect_deps(dep, manifests, visited)

def main():
    packages_dir = os.path.dirname(os.path.abspath(__file__))
    if not os.path.isdir(packages_dir):
        packages_dir = "packages"

    manifests = load_manifests(packages_dir)
    target_groups = {"base", "builder"}
    
    target_pkgs = {
        name for name, data in manifests.items()
        if data.get("package", {}).get("group") in target_groups
    }

    all_needed = set()
    for name in target_pkgs:
        collect_deps(name, manifests, all_needed)

    in_degree = {name: 0 for name in all_needed}
    adj = {name: [] for name in all_needed}

    for name in all_needed:
        data = manifests[name]
        runtime_deps = data.get("package", {}).get("dependencies", [])
        build_deps = data.get("build", {}).get("dependencies", [])
        for dep in set(runtime_deps + build_deps):
            if dep in all_needed:
                adj[dep].append(name)
                in_degree[name] += 1

    from collections import deque
    queue = deque(sorted(n for n in all_needed if in_degree[n] == 0))
    ordered = []
    while queue:
        node = queue.popleft()
        ordered.append(node)
        for neighbour in sorted(adj[node]):
            in_degree[neighbour] -= 1
            if in_degree[neighbour] == 0:
                queue.append(neighbour)

    if len(ordered) != len(all_needed):
        print("Error: Dependency cycle detected", file=sys.stderr)
        sys.exit(1)

    for name in ordered:
        if name in target_pkgs:
            print(name)

if __name__ == "__main__":
    main()
