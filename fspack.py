#!/usr/bin/env python3
import os
import sys
import re
import shutil
import hashlib
import argparse
import subprocess
import urllib.request
import urllib.error
import textwrap
import tomllib
from dataclasses import dataclass, field
from typing import List, Dict, Optional
import ssl
from datetime import datetime

try:
    ssl._create_default_https_context = ssl._create_unverified_context
except AttributeError:
    pass

# ==============================================================================
# Typed Manifest Dataclasses
# ==============================================================================

@dataclass
class ChecksumInfo:
    algorithm: str
    value: str

@dataclass
class SourceInfo:
    url: Optional[str] = None
    file: Optional[str] = None
    git: Optional[str] = None
    ref: str = "HEAD"
    checksum: Optional[ChecksumInfo] = None

@dataclass
class BuildInfo:
    dependencies: List[str] = field(default_factory=list)
    environment: Dict[str, str] = field(default_factory=dict)

@dataclass
class PackageInfo:
    name: str
    version: str
    description: str
    dependencies: List[str] = field(default_factory=list)
    group: Optional[str] = None

@dataclass
class PackageManifest:
    package: PackageInfo
    sources: List[SourceInfo] = field(default_factory=list)
    build: BuildInfo = field(default_factory=BuildInfo)

# ==============================================================================
# Helper Functions
# ==============================================================================

def compute_sha256(path):
    """Computes the SHA256 checksum of a file."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def load_manifest(manifest_path: str) -> PackageManifest:
    """Loads and parses a package.manifest file into structured dataclasses."""
    with open(manifest_path, "rb") as f:
        data = tomllib.load(f)
    
    pkg_data = data.get("package", {})
    package = PackageInfo(
        name=pkg_data.get("name"),
        version=str(pkg_data.get("version")),
        description=pkg_data.get("description", ""),
        dependencies=pkg_data.get("dependencies", []),
        group=pkg_data.get("group")
    )
    
    sources = []
    for src in data.get("sources", []):
        checksum = None
        if "checksum" in src:
            checksum = ChecksumInfo(
                algorithm=src["checksum"].get("algorithm"),
                value=src["checksum"].get("value")
            )
        sources.append(SourceInfo(
            url=src.get("url"),
            file=src.get("file"),
            git=src.get("git"),
            ref=src.get("ref", "HEAD"),
            checksum=checksum
        ))
        
    build_data = data.get("build", {})
    env_block = build_data.get("environment", build_data.get("env", {}))
    build = BuildInfo(
        dependencies=build_data.get("dependencies", []),
        environment={k: str(v) for k, v in env_block.items()}
    )
    
    return PackageManifest(package=package, sources=sources, build=build)

def get_packages_dir():
    """Locates the packages directory in the workspace."""
    return os.environ.get("STRAYLIGHT_PACKAGES_ROOT", os.path.dirname(os.path.abspath(__file__)))

def load_all_manifests(packages_dir):
    """Loads all package manifests from the packages directory."""
    manifests = {}
    if not os.path.isdir(packages_dir):
        return manifests
    for entry in sorted(os.listdir(packages_dir)):
        manifest_path = os.path.join(packages_dir, entry, "package.manifest")
        if not os.path.isfile(manifest_path):
            continue
        manifests[entry] = load_manifest(manifest_path)
    return manifests

def load_all_manifests_safe(packages_dir):
    """Loads all package manifests, ignoring files that fail to parse."""
    manifests = {}
    if not os.path.isdir(packages_dir):
        return manifests
    for entry in sorted(os.listdir(packages_dir)):
        manifest_path = os.path.join(packages_dir, entry, "package.manifest")
        if not os.path.isfile(manifest_path):
            continue
        try:
            manifests[entry] = load_manifest(manifest_path)
        except Exception:
            pass
    return manifests

# ==============================================================================
# Commands: RESOLVE
# ==============================================================================

def collect_deps(name, manifests, visited):
    """Recursively collects transitive dependencies."""
    if name in visited or name not in manifests:
        return
    visited.add(name)
    data = manifests[name]
    runtime_deps = data.package.dependencies
    build_deps = data.build.dependencies
    for dep in set(runtime_deps + build_deps):
        collect_deps(dep, manifests, visited)

def resolve_dependencies(target_groups):
    """Returns a topologically sorted list of packages belonging to targeted groups."""
    packages_dir = get_packages_dir()
    manifests = load_all_manifests(packages_dir)
    
    target_pkgs = {
        name for name, data in manifests.items()
        if data.package.group in target_groups
    }

    all_needed = set()
    for name in target_pkgs:
        collect_deps(name, manifests, all_needed)

    in_degree = {name: 0 for name in all_needed}
    adj = {name: [] for name in all_needed}

    for name in all_needed:
        data = manifests[name]
        runtime_deps = data.package.dependencies
        build_deps = data.build.dependencies
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
        raise Exception("Dependency cycle detected among packages")

    return [name for name in ordered if name in target_pkgs]

def resolve_package_dependencies(pkg_name):
    """Returns a topologically sorted list of packages needed to build pkg_name (including pkg_name itself)."""
    packages_dir = get_packages_dir()
    manifests = load_all_manifests(packages_dir)
    
    if pkg_name not in manifests:
        raise Exception(f"Package {pkg_name} not found in manifests")
        
    all_needed = set()
    collect_deps(pkg_name, manifests, all_needed)

    in_degree = {name: 0 for name in all_needed}
    adj = {name: [] for name in all_needed}

    for name in all_needed:
        data = manifests[name]
        runtime_deps = data.package.dependencies
        build_deps = data.build.dependencies
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
        raise Exception("Dependency cycle detected among packages")

    return ordered

def resolve_group_dependencies(group_name):
    """Returns a topologically sorted list of packages needed to build a group (including all transitive dependencies)."""
    packages_dir = get_packages_dir()
    manifests = load_all_manifests(packages_dir)
    
    target_pkgs = {
        name for name, data in manifests.items()
        if data.package.group == group_name
    }

    all_needed = set()
    for name in target_pkgs:
        collect_deps(name, manifests, all_needed)

    in_degree = {name: 0 for name in all_needed}
    adj = {name: [] for name in all_needed}

    for name in all_needed:
        data = manifests[name]
        runtime_deps = data.package.dependencies
        build_deps = data.build.dependencies
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
        raise Exception("Dependency cycle detected among packages")

    return ordered

def handle_resolve(args):
    """CLI handler for resolve."""
    try:
        if args.pkg:
            ordered = resolve_package_dependencies(args.pkg)
        elif args.group:
            ordered = resolve_group_dependencies(args.group)
        elif args.groups:
            ordered = resolve_dependencies(set(args.groups))
        else:
            raise Exception("Specify either --pkg <pkg_name>, --group <group_name>, or positional group names")
        for pkg in ordered:
            print(pkg)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

def handle_list(args):
    """CLI handler to list packages and groups."""
    try:
        packages_dir = get_packages_dir()
        manifests = load_all_manifests(packages_dir)
        
        groups = {}
        for name, manifest in manifests.items():
            g = manifest.package.group
            if g:
                groups.setdefault(g, []).append(name)
        
        if args.group:
            target_group = args.group
            if target_group not in groups:
                print(f"Error: Group '{target_group}' not found", file=sys.stderr)
                sys.exit(1)
            for pkg in sorted(groups[target_group]):
                version = manifests[pkg].package.version
                print(f"{pkg:<25} ({version})")
        elif args.groups:
            for group in sorted(groups.keys()):
                print(group)
        else:
            for group in sorted(groups.keys()):
                print(f"{group}:")
                for pkg in sorted(groups[group]):
                    version = manifests[pkg].package.version
                    print(f"  {pkg:<25} ({version})")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

# ==============================================================================
# Commands: VERIFY
# ==============================================================================

def check_dependency_cycle(pkg_name: str, manifests: dict) -> Optional[str]:
    """Checks if there is a dependency cycle starting from pkg_name."""
    if pkg_name not in manifests:
        return None
    
    visited = {}  # name -> state: 0=unvisited, 1=visiting, 2=visited
    path = []
    
    def dfs(name):
        if name not in manifests:
            return None
        visited[name] = 1
        path.append(name)
        
        data = manifests[name]
        # Safely extract dependencies, ensuring they are lists and elements are strings
        deps = []
        if hasattr(data, 'package') and data.package:
            pkg_deps = getattr(data.package, 'dependencies', [])
            if isinstance(pkg_deps, list):
                for d in pkg_deps:
                    if isinstance(d, str):
                        deps.append(d)
            elif isinstance(pkg_deps, str):
                deps.append(pkg_deps)
                
        if hasattr(data, 'build') and data.build:
            build_deps = getattr(data.build, 'dependencies', [])
            if isinstance(build_deps, list):
                for d in build_deps:
                    if isinstance(d, str):
                        deps.append(d)
            elif isinstance(build_deps, str):
                deps.append(build_deps)
                
        for dep in sorted(set(deps)):
            if visited.get(dep) == 1:
                cycle_path = path[path.index(dep):] + [dep]
                return " -> ".join(cycle_path)
            elif visited.get(dep) != 2:
                cycle_str = dfs(dep)
                if cycle_str:
                    return cycle_str
                    
        path.pop()
        visited[name] = 2
        return None
        
    return dfs(pkg_name)

def verify_package(pkg_name: str, all_pkg_dirs: set, manifests: dict, packages_dir: str) -> List[str]:
    """Validates a package directory structure and manifests, returning a list of error strings."""
    errors = []
    pkg_dir = os.path.join(packages_dir, pkg_name)
    
    # 1. Structural Checks
    if not os.path.isdir(pkg_dir):
        return [f"Package directory '{pkg_dir}' does not exist."]
        
    manifest_path = os.path.join(pkg_dir, "package.manifest")
    justfile_path = os.path.join(pkg_dir, "package.justfile")
    
    if not os.path.isfile(manifest_path):
        errors.append("package.manifest is missing.")
    if not os.path.isfile(justfile_path):
        errors.append("package.justfile is missing.")
        
    if not os.path.isfile(manifest_path):
        return errors

    # 2. TOML Parsing & Schema Validation
    data = None
    try:
        with open(manifest_path, "rb") as f:
            data = tomllib.load(f)
    except Exception as e:
        errors.append(f"package.manifest is not valid TOML: {e}")
        return errors

    # Check for compiler/linker flags misplaced in root
    misplaced_keys = ["CFLAGS", "CXXFLAGS", "LDFLAGS", "CONFIGURE_ARGS", "MAKE_FLAGS"]
    for key in misplaced_keys:
        if key in data:
            errors.append(f"Build environment variable '{key}' must be placed under [build.environment] or [build.env], not in the root table.")
    
    pkg_data = data.get("package")
    if pkg_data is None:
        errors.append("Missing [package] table.")
    elif not isinstance(pkg_data, dict):
        errors.append("[package] must be a table.")
    else:
        name = pkg_data.get("name")
        if not name:
            errors.append("[package].name is missing or empty.")
        elif not isinstance(name, str):
            errors.append("[package].name must be a string.")
        elif name != pkg_name:
            errors.append(f"[package].name '{name}' does not match the directory name '{pkg_name}'.")
            
        version = pkg_data.get("version")
        if version is None or str(version).strip() == "":
            errors.append("[package].version is missing or empty.")
            
        if "description" not in pkg_data:
            errors.append("[package].description is missing.")
        elif not isinstance(pkg_data.get("description"), str):
            errors.append("[package].description must be a string.")
            
        group = pkg_data.get("group")
        valid_groups = {"base", "builder", "system", "server", "desktop", "extra"}
        if group is None:
            errors.append("[package].group is missing.")
        elif not isinstance(group, str):
            errors.append("[package].group must be a string.")
        elif group not in valid_groups:
            errors.append(f"[package].group '{group}' is invalid. Allowed groups are: {', '.join(sorted(valid_groups))}")
            
        deps = pkg_data.get("dependencies")
        if deps is not None:
            if not isinstance(deps, list):
                errors.append("[package].dependencies must be a list of strings.")
            else:
                for dep in deps:
                    if not isinstance(dep, str):
                        errors.append(f"Dependency '{dep}' in [package].dependencies must be a string.")
                    elif dep not in all_pkg_dirs:
                        errors.append(f"Runtime dependency '{dep}' does not exist under '{packages_dir}'.")
                        
    if isinstance(pkg_data, dict):
        for key in misplaced_keys:
            if key in pkg_data:
                errors.append(f"Build environment variable '{key}' must be placed under [build.environment] or [build.env], not in [package] table.")

    build_data = data.get("build")
    if build_data is not None:
        if not isinstance(build_data, dict):
            errors.append("[build] must be a table.")
        else:
            build_deps = build_data.get("dependencies")
            if build_deps is not None:
                if not isinstance(build_deps, list):
                    errors.append("[build].dependencies must be a list of strings.")
                else:
                    for dep in build_deps:
                        if not isinstance(dep, str):
                            errors.append(f"Dependency '{dep}' in [build].dependencies must be a string.")
                        elif dep not in all_pkg_dirs:
                            errors.append(f"Build dependency '{dep}' does not exist under '{packages_dir}'.")
            
            for key in misplaced_keys:
                if key in build_data:
                    errors.append(f"Build environment variable '{key}' must be placed under [build.environment] or [build.env], not in [build] table.")

    # 3. Sources Check
    sources = data.get("sources")
    if sources is not None:
        if not isinstance(sources, list):
            errors.append("'sources' must be an array of tables.")
        else:
            for idx, src in enumerate(sources):
                if not isinstance(src, dict):
                    errors.append(f"Source at index {idx} must be a table.")
                    continue
                
                keys = [k for k in ["url", "file", "git"] if k in src]
                if len(keys) != 1:
                    errors.append(f"Source at index {idx} must specify exactly one of 'url', 'file', or 'git' (found: {', '.join(keys) if keys else 'none'}).")
                    continue
                
                src_type = keys[0]
                if src_type in ["url", "file"]:
                    checksum = src.get("checksum")
                    if checksum is None:
                        errors.append(f"Source at index {idx} ({src_type}) is missing a 'checksum' table.")
                    elif not isinstance(checksum, dict):
                        errors.append(f"Source at index {idx} has invalid 'checksum' (must be a table).")
                    else:
                        algo = checksum.get("algorithm")
                        val = checksum.get("value")
                        if algo != "sha256":
                            errors.append(f"Source at index {idx} has invalid checksum algorithm '{algo}' (only 'sha256' is supported).")
                        if not val:
                            errors.append(f"Source at index {idx} has missing or empty checksum value.")
                        elif not (isinstance(val, str) and len(val) == 64 and all(c in "0123456789abcdefABCDEF" for c in val)):
                            errors.append(f"Source at index {idx} has invalid SHA256 checksum value format.")
                    
                    if src_type == "file":
                        filename = src.get("file")
                        if isinstance(filename, str):
                            local_file_path = os.path.join(pkg_dir, filename)
                            if not os.path.isfile(local_file_path):
                                errors.append(f"Local file source '{filename}' does not exist at '{local_file_path}'.")
                
                elif src_type == "git":
                    if "checksum" in src:
                        errors.append(f"Source at index {idx} (git) should not have a 'checksum' table.")
                    ref = src.get("ref")
                    if ref is not None and not isinstance(ref, str):
                        errors.append(f"Source at index {idx} (git) has invalid 'ref' (must be a string).")

    # 4. Justfile Check
    if os.path.isfile(justfile_path):
        try:
            with open(justfile_path, "r", encoding="utf-8") as f:
                just_content = f.read()
            
            build_match = re.search(r"^build\b[^:]*:", just_content, re.MULTILINE)
            package_match = re.search(r"^package\b[^:]*:", just_content, re.MULTILINE)
            
            if not build_match:
                errors.append("package.justfile is missing the 'build' target.")
            if not package_match:
                errors.append("package.justfile is missing the 'package' target.")
        except Exception as e:
            errors.append(f"Failed to read package.justfile: {e}")

    # 5. Dependency Cycle Check
    cycle_str = check_dependency_cycle(pkg_name, manifests)
    if cycle_str:
        errors.append(f"Dependency cycle detected: {cycle_str}")

    return errors

def handle_verify(args):
    """CLI handler to verify package(s) validity."""
    packages_dir = get_packages_dir()
    
    if args.pkgname and args.all:
        print("Error: Cannot specify both a package name and --all", file=sys.stderr)
        sys.exit(1)
    if not args.pkgname and not args.all:
        print("Error: Specify either a package name or --all", file=sys.stderr)
        sys.exit(1)
        
    if args.all:
        pkg_names = []
        if os.path.isdir(packages_dir):
            for entry in sorted(os.listdir(packages_dir)):
                if os.path.isdir(os.path.join(packages_dir, entry)) and not entry.startswith("."):
                    pkg_names.append(entry)
        if not pkg_names:
            print("No packages found to verify.", file=sys.stderr)
            sys.exit(0)
    else:
        pkg_names = [args.pkgname]
        
    manifests = load_all_manifests_safe(packages_dir)
    
    all_pkg_dirs = set()
    if os.path.isdir(packages_dir):
        for entry in os.listdir(packages_dir):
            if os.path.isdir(os.path.join(packages_dir, entry)) and not entry.startswith("."):
                all_pkg_dirs.add(entry)
                
    invalid_packages = 0
    total_packages = len(pkg_names)
    
    for pkg_name in pkg_names:
        errors = verify_package(pkg_name, all_pkg_dirs, manifests, packages_dir)
        if errors:
            invalid_packages += 1
            print(f"✗ [{pkg_name}] Package is invalid:")
            for err in errors:
                print(f"  - {err}")
        else:
            print(f"✓ [{pkg_name}] Package is valid.")
            
    if invalid_packages > 0:
        print(f"\nVerification failed: {invalid_packages}/{total_packages} package(s) are invalid.", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"\nVerification successful: {total_packages}/{total_packages} package(s) are valid.")
        sys.exit(0)

# ==============================================================================
# Commands: CONVERT
# ==============================================================================

def build_arch_url(pkgname):
    return f"https://gitlab.archlinux.org/archlinux/packaging/packages/{pkgname}/-/raw/main/PKGBUILD"

def fetch_pkgbuild(url):
    print(f"Fetching PKGBUILD from {url}...")
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as response:
        if response.status != 200:
            raise Exception(f"Unable to retrieve PKGBUILD. [HTTP Status Code: {response.status}]")
        return response.read().decode('utf-8')

def extract_variable(content, var_name, is_array=False):
    if is_array:
        pattern = re.compile(rf'^{var_name}=\(([^)]+)\)', re.MULTILINE)
        match = pattern.search(content)
        if match:
            cleaned = re.sub(r'["\']', '', match.group(1))
            return [item.strip() for item in cleaned.split()]
        return []
    else:
        pattern = re.compile(rf'^{var_name}=([^\n]+)', re.MULTILINE)
        match = pattern.search(content)
        if match:
            return match.group(1).strip('"\' ')
        return ""

def extract_function(content, func_name):
    if func_name == 'package':
        pattern = re.compile(r'^package(?:_[a-zA-Z0-9_-]+)?\s*\(\)\s*\{', re.MULTILINE)
    else:
        pattern = re.compile(rf'^{func_name}\s*\(\)\s*\{{', re.MULTILINE)
        
    match = pattern.search(content)
    if not match:
        return ""
    
    start = match.end()
    brace_count = 1
    i = start
    
    while i < len(content) and brace_count > 0:
        if content[i] == '{':
            brace_count += 1
        elif content[i] == '}':
            brace_count -= 1
        i += 1
        
    body = textwrap.dedent(content[start:i-1]).strip()
    
    body = (body
            .replace('"${pkgdir}"', '"$DESTDIR"')
            .replace('"$pkgdir"', '"$DESTDIR"')
            .replace('${pkgdir}', '$DESTDIR')
            .replace('$pkgdir', '$DESTDIR')
            .replace('"${pkgname}"', '"$PKG_NAME"')
            .replace('"$pkgname"', '"$PKG_NAME"')
            .replace('${pkgname}', '$PKG_NAME')
            .replace('$pkgname', '$PKG_NAME')
            .replace('"${pkgbase}"', '"$PKG_NAME"')
            .replace('"$pkgbase"', '"$PKG_NAME"')
            .replace('${pkgbase}', '$PKG_NAME')
            .replace('$pkgbase', '$PKG_NAME')
            .replace('"${pkgver}"', '"$PKG_VERSION"')
            .replace('"$pkgver"', '"$PKG_VERSION"')
            .replace('${pkgver}', '$PKG_VERSION')
            .replace('$pkgver', '$PKG_VERSION'))
    
    body = re.sub(r'^.*cd\s+.*\$srcdir.*$', '', body, flags=re.MULTILINE).strip()
    return body

def generate_freeside_package(pkgbuild_content):
    pkgname = extract_variable(pkgbuild_content, 'pkgname')
    if not pkgname:
        pkgbase = extract_variable(pkgbuild_content, 'pkgbase')
        if pkgbase:
            pkgname = pkgbase
        else:
            pkgname_array = extract_variable(pkgbuild_content, 'pkgname', is_array=True)
            pkgname = pkgname_array[0] if pkgname_array else ""

    pkgver = extract_variable(pkgbuild_content, 'pkgver')
    pkgdesc = extract_variable(pkgbuild_content, 'pkgdesc')
    depends = extract_variable(pkgbuild_content, 'depends', is_array=True)
    sources = extract_variable(pkgbuild_content, 'source', is_array=True)
    sha256sums = extract_variable(pkgbuild_content, 'sha256sums', is_array=True)
    
    primary_source = sources[0] if sources else ""
    primary_source = (primary_source
                      .replace('"${pkgname}"', pkgname)
                      .replace('"$pkgname"', pkgname)
                      .replace('${pkgname}', pkgname)
                      .replace('$pkgname', pkgname)
                      .replace('"${pkgbase}"', pkgname)
                      .replace('"$pkgbase"', pkgname)
                      .replace('${pkgbase}', pkgname)
                      .replace('$pkgbase', pkgname)
                      .replace('"${pkgver}"', pkgver)
                      .replace('"$pkgver"', pkgver)
                      .replace('${pkgver}', pkgver)
                      .replace('$pkgver', pkgver))
    primary_sha = sha256sums[0] if sha256sums and sha256sums[0] != 'SKIP' else ""
    
    depends_str = '[]' if not depends else '["' + '", "'.join(depends) + '"]'
    
    manifest_toml = textwrap.dedent(f"""\
        [package]
        name = "{pkgname}"
        version = "{pkgver}"
        description = "{pkgdesc}"
        dependencies = {depends_str}

        [[sources]]
        url = "{primary_source}"
        checksum = {{ algorithm = "sha256", value = "{primary_sha}" }}
    """)
    
    build_body = extract_function(pkgbuild_content, 'build')
    package_body = extract_function(pkgbuild_content, 'package')
    
    justfile = ""
    if build_body:
        justfile += "build:\n"
        justfile += textwrap.indent(build_body, "    ") + "\n\n"
        
    if package_body:
        justfile += "package:\n"
        justfile += textwrap.indent(package_body, "    ") + "\n"
    
    return manifest_toml, justfile.strip()

def handle_convert(args):
    """CLI handler for PKGBUILD conversion."""
    pkgname = args.pkgname.strip()
    url = build_arch_url(pkgname)
    try:
        pkgbuild_content = fetch_pkgbuild(url)
        os.makedirs(pkgname, exist_ok=True)
        print(f"Created directory: ./{pkgname}/")
        
        with open(os.path.join(pkgname, "PKGBUILD"), 'w', encoding='utf-8') as f:
            f.write(pkgbuild_content)
        
        manifest, justfile = generate_freeside_package(pkgbuild_content)
        with open(os.path.join(pkgname, "package.manifest"), 'w', encoding='utf-8') as f:
            f.write(manifest)
        with open(os.path.join(pkgname, "package.justfile"), 'w', encoding='utf-8') as f:
            f.write(justfile)
        
        print("\nConversion successful!")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"Error 404: PKGBUILD for '{pkgname}' not found at {url}.", file=sys.stderr)
        else:
            print(f"HTTP Error {e.code}: {e.reason}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)

# ==============================================================================
# Commands: BUILD
# ==============================================================================

def generate_files_ledger(staging_dir):
    """Generates the meta/files.toml file registry list."""
    entries = []
    for root, _, files in os.walk(staging_dir):
        if os.path.relpath(root, staging_dir).startswith("meta"):
            continue
        for file in files:
            full_path = os.path.join(root, file)
            if os.path.islink(full_path):
                continue
            if not os.path.isfile(full_path):
                continue
            
            rel_path = os.path.relpath(full_path, staging_dir)
            path_str = f"./{rel_path}"
            sha256 = compute_sha256(full_path)
            stat = os.stat(full_path)
            size = stat.st_size
            mode = f"{stat.st_mode & 0o7777:04o}"
            uid = stat.st_uid
            gid = stat.st_gid
            
            entries.append(f"[[files]]\npath = \"{path_str}\"\nsha256 = \"{sha256}\"\nsize = {size}\nmode = \"{mode}\"\nuid = {uid}\ngid = {gid}\n")
    return "\n".join(entries)

def install_package(tarball_path, prefix=""):
    """Installs a compiled package tarball into the container root /."""
    print(f"{prefix}Installing {os.path.basename(tarball_path)}")
    subprocess.run(["tar", "-xzf", tarball_path, "--exclude=meta/*", "-C", "/"], check=True)
    
    # Enforce UsrMerge inside the sandbox container
    usr_sbin = "/usr/sbin"
    if os.path.exists(usr_sbin) and not os.path.islink(usr_sbin):
        usr_bin = "/usr/bin"
        for name in os.listdir(usr_sbin):
            src = os.path.join(usr_sbin, name)
            dst = os.path.join(usr_bin, name)
            if os.path.exists(dst):
                if os.path.islink(dst) or os.path.isfile(dst):
                    os.remove(dst)
                else:
                    shutil.rmtree(dst)
            shutil.move(src, dst)
        shutil.rmtree(usr_sbin)
        os.symlink("bin", usr_sbin)


def fetch_source_url(url, dest_dir, checksum_algo=None, checksum_val=None, prefix=""):
    """Downloads source from a URL and verifies checksum."""
    filename = url.split('/')[-1].split('?')[0]
    dest_path = os.path.join(dest_dir, filename)
    print(f"{prefix}  Downloading {url}...")
    
    urllib.request.urlretrieve(url, dest_path)
    
    if checksum_val and checksum_algo == "sha256":
        actual = compute_sha256(dest_path)
        if actual != checksum_val:
            os.remove(dest_path)
            raise Exception(f"Integrity check failed for {filename}! Expected SHA256: {checksum_val}, Got: {actual}")
        print(f"{prefix}  Checksum OK: {filename}")

def build_package_impl(pkg_name, keep_all_logs=False, keep_sandbox=False, current_idx=1, total_count=1):
    """Builds and packages a single package inside the container."""
    progress = f"[{current_idx}/{total_count}]"
    pkg_name_fmt = f"[{pkg_name}]"
    prefix = f"{progress:<10}{pkg_name_fmt:<20}"
    packages_dir = get_packages_dir()
    pkg_dir = os.path.join(packages_dir, pkg_name)
    manifest_path = os.path.join(pkg_dir, "package.manifest")
    
    if not os.path.isfile(manifest_path):
        raise Exception(f"Manifest not found for package {pkg_name} at {manifest_path}")
        
    manifest = load_manifest(manifest_path)
    pkg_version = manifest.package.version
    pkg_description = manifest.package.description
    pkg_group = manifest.package.group or ""
    pkg_dependencies = " ".join(manifest.package.dependencies)
    
    tarball_name = f"{pkg_name}-{pkg_version}-1.tar.gz"
    output_dir = os.environ.get("STRAYLIGHT_BUILDER_OUTPUT_ROOT", "/workspace/build/packages")
    tarball_path = os.path.join(output_dir, tarball_name)
    
    if os.path.isfile(tarball_path):
        print(f"{prefix}Compiling... skipped")
        install_package(tarball_path, prefix)
        return True

    print(f"{prefix}Compiling {pkg_name}-{pkg_version} (group: {pkg_group})...")

    ws_root = os.environ.get("STRAYLIGHT_BUILDER_ROOT", "/workspace/build")
    ws = os.path.join(ws_root, f"workspace/{pkg_name}-{pkg_version}")
    src_dir = f"{ws}/src"
    dest_dir = f"{ws}/dest"
    
    if os.path.exists(ws) and not keep_sandbox:
        shutil.rmtree(ws)
    os.makedirs(src_dir, exist_ok=True)
    os.makedirs(dest_dir, exist_ok=True)
    
    print(f"{prefix}Fetching sources...")
    for source in manifest.sources:
        if source.url:
            algo = source.checksum.algorithm if source.checksum else None
            val = source.checksum.value if source.checksum else None
            fetch_source_url(source.url, src_dir, algo, val, prefix)
        elif source.file:
            src_file_path = os.path.join(pkg_dir, source.file)
            if not os.path.exists(src_file_path):
                raise Exception(f"Local source file not found at {src_file_path}")
            print(f"{prefix}  Copying local file: {source.file}")
            shutil.copy(src_file_path, os.path.join(src_dir, source.file))
        elif source.git:
            git_url = source.git
            ref = source.ref
            print(f"{prefix}  Cloning git repo: {git_url} (ref: {ref})")
            subprocess.run(["git", "clone", "--depth=1", git_url, os.path.join(src_dir, pkg_name)], check=True)
            if ref != "HEAD":
                subprocess.run(["git", "-C", os.path.join(src_dir, pkg_name), "checkout", ref], check=True)

    shutil.copy(os.path.join(pkg_dir, "package.justfile"), os.path.join(ws, "package.justfile"))

    env = os.environ.copy()
    env["PKG_NAME"] = pkg_name
    env["PKG_VERSION"] = pkg_version
    env["PKG_DESCRIPTION"] = pkg_description
    env["PKG_DEPENDENCIES"] = pkg_dependencies
    env["PKG_GROUP"] = pkg_group
    env["DESTDIR"] = dest_dir
    
    for k, v in manifest.build.environment.items():
        env[k] = str(v)

    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_path = os.path.join(ws_root, f"{pkg_name}-{ts}.log")
    print(f"{prefix}Logging build output to {log_path}")

    build_success = False
    try:
        with open(log_path, "w", encoding="utf-8") as log_file:
            print(f"{prefix}Running: just build")
            subprocess.run(
                ["just", "-f", os.path.join(ws, "package.justfile"), "-d", src_dir, "build"], 
                env=env, 
                stdout=log_file,
                stderr=subprocess.STDOUT,
                check=True
            )
            print(f"{prefix}Running: just package")
            subprocess.run(
                ["just", "-f", os.path.join(ws, "package.justfile"), "-d", src_dir, "package"], 
                env=env, 
                stdout=log_file,
                stderr=subprocess.STDOUT,
                check=True
            )
        build_success = True
    except subprocess.CalledProcessError as e:
        print(f"{prefix}Build failed! See log at {log_path}", file=sys.stderr)
        raise e
    finally:
        if build_success and not keep_all_logs:
            try:
                os.remove(log_path)
            except OSError:
                pass

    staging_dir = os.path.join(ws, "staging")
    os.makedirs(os.path.join(staging_dir, "meta"), exist_ok=True)
    shutil.copy(manifest_path, os.path.join(staging_dir, "meta/package.manifest"))
    
    dest_usr = os.path.join(dest_dir, "usr")
    if os.path.exists(dest_usr):
        shutil.copytree(dest_usr, os.path.join(staging_dir, "usr"), symlinks=True)
        
    for entry in os.listdir(dest_dir):
        if entry == "usr":
            continue
        entry_path = os.path.join(dest_dir, entry)
        if os.path.isdir(entry_path):
            shutil.copytree(entry_path, os.path.join(staging_dir, entry), symlinks=True)
        else:
            shutil.copy(entry_path, os.path.join(staging_dir, entry))

    print(f"{prefix}Generating files.toml ledger...")
    ledger_content = generate_files_ledger(staging_dir)
    with open(os.path.join(staging_dir, "meta/files.toml"), "w", encoding="utf-8") as f:
        f.write(ledger_content)

    os.makedirs(output_dir, exist_ok=True)
    print(f"{prefix}Creating tarball: {tarball_name}")
    subprocess.run(["tar", "-czf", tarball_path, "-C", staging_dir, "."], check=True)

    install_package(tarball_path, prefix)

    if not keep_sandbox:
        shutil.rmtree(ws)
    print(f"{prefix}Compiling... done")
    return True

def handle_build(args):
    """CLI handler for package compilation."""
    if os.getuid() != 0:
        print("Error: fspack build command must be run with root/sudo privileges.", file=sys.stderr)
        sys.exit(1)

    if args.group and args.with_deps:
        print("Error: --with-deps is only supported with --pkg", file=sys.stderr)
        sys.exit(1)

    if args.pkg:
        try:
            if args.with_deps:
                print(f"Resolving build order for package: {args.pkg} and its dependencies...")
                ordered_packages = resolve_package_dependencies(args.pkg)
                print(f"Found {len(ordered_packages)} packages to build: {ordered_packages}")
                total = len(ordered_packages)
                for idx, pkg in enumerate(ordered_packages, 1):
                    build_package_impl(pkg, keep_all_logs=args.keep_all_logs, keep_sandbox=args.keep_sandbox, current_idx=idx, total_count=total)
                print(f"\nBuild Complete for: {args.pkg} and dependencies ✓")
            else:
                build_package_impl(args.pkg, keep_all_logs=args.keep_all_logs, keep_sandbox=args.keep_sandbox, current_idx=1, total_count=1)
        except Exception as e:
            print(f"Build Failed: {e}", file=sys.stderr)
            sys.exit(1)
    elif args.group:
        try:
            print(f"Resolving build order for group: {args.group}...")
            ordered_packages = resolve_dependencies({args.group})
            print(f"Found {len(ordered_packages)} packages in group: {ordered_packages}")
            total = len(ordered_packages)
            for idx, pkg in enumerate(ordered_packages, 1):
                build_package_impl(pkg, keep_all_logs=args.keep_all_logs, keep_sandbox=args.keep_sandbox, current_idx=idx, total_count=total)
            print(f"\nGroup Build Complete for: {args.group} ✓")
        except Exception as e:
            print(f"Group Build Failed: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print("Error: Specify either --pkg <pkg_name> or --group <group_name>", file=sys.stderr)
        sys.exit(1)

def handle_info(args):
    """CLI handler to print package metadata."""
    packages_dir = get_packages_dir()
    pkg_dir = os.path.join(packages_dir, args.pkgname)
    manifest_path = os.path.join(pkg_dir, "package.manifest")
    
    if not os.path.isfile(manifest_path):
        print(f"Error: Manifest not found for package {args.pkgname}", file=sys.stderr)
        sys.exit(1)
        
    try:
        manifest = load_manifest(manifest_path)
        if args.simple:
            print(manifest.package.name)
            print(manifest.package.version)
            print(manifest.package.group or "")
            print(pkg_dir)
            print(manifest.package.description)
            print(" ".join(manifest.package.dependencies))
            
            import json as j
            for src in manifest.sources:
                src_dict = {}
                if src.url: src_dict["url"] = src.url
                if src.file: src_dict["file"] = src.file
                if src.git: src_dict["git"] = src.git
                if src.ref != "HEAD": src_dict["ref"] = src.ref
                if src.checksum:
                    src_dict["checksum"] = {
                        "algorithm": src.checksum.algorithm,
                        "value": src.checksum.value
                    }
                print("SOURCE:" + j.dumps(src_dict))
                
            for k, v in manifest.build.environment.items():
                print(f"ENV:{k}={v}")
        else:
            print(f"Package:      {manifest.package.name}")
            print(f"Version:      {manifest.package.version}")
            print(f"Group:        {manifest.package.group or 'None'}")
            print(f"Path:         {pkg_dir}")
            print(f"Description:  {manifest.package.description}")
            print(f"Dependencies: {', '.join(manifest.package.dependencies) if manifest.package.dependencies else 'None'}")
            
            if manifest.sources:
                print("\nSources:")
                for src in manifest.sources:
                    if src.url:
                        checksum_str = f" [{src.checksum.algorithm}: {src.checksum.value}]" if src.checksum else ""
                        print(f"  - {src.url}{checksum_str}")
                    elif src.file:
                        print(f"  - Local File: {src.file}")
                    elif src.git:
                        print(f"  - Git Repo: {src.git} (ref: {src.ref})")
            
            env_vars = {}
            env_vars["PKG_NAME"] = manifest.package.name
            env_vars["PKG_VERSION"] = manifest.package.version
            env_vars["PKG_DESCRIPTION"] = manifest.package.description
            env_vars["PKG_GROUP"] = manifest.package.group or ""
            env_vars["PKG_DEPENDENCIES"] = " ".join(manifest.package.dependencies)
            
            for k, v in manifest.build.environment.items():
                env_vars[k] = str(v)
                
            if env_vars:
                print("\nEnvironment Variables:")
                for k, v in sorted(env_vars.items()):
                    print(f"  - {k} = {v}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

def handle_create(args):
    """CLI handler to create a new package directory with manifest and justfile stubs."""
    packages_dir = get_packages_dir()
    pkg_dir = os.path.join(packages_dir, args.pkgname)
    
    if os.path.exists(pkg_dir):
        print(f"Error: Directory for package '{args.pkgname}' already exists at {pkg_dir}.", file=sys.stderr)
        sys.exit(1)
        
    try:
        os.makedirs(pkg_dir)
        
        # Create package.manifest
        manifest_path = os.path.join(pkg_dir, "package.manifest")
        manifest_content = textwrap.dedent(f"""\
            [package]
            name = "{args.pkgname}"
            version = "{args.version}"
            description = "{args.description or f"Template package description for {args.pkgname}"}"
            dependencies = []
            group = "{args.group}"

            [[sources]]
            url = "https://example.com/{args.pkgname}-{args.version}.tar.gz"
            checksum = {{ algorithm = "sha256", value = "" }}

            [build]
            dependencies = []

            [build.environment]
            CONFIGURE_ARGS = "--prefix=/usr"
        """)
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(manifest_content)
            
        # Create package.justfile
        justfile_path = os.path.join(pkg_dir, "package.justfile")
        justfile_content = textwrap.dedent("""\
            build:
                tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
                cd $PKG_NAME-$PKG_VERSION && ./configure $CONFIGURE_ARGS && make -j$(nproc)

            package:
                cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
                find "$DESTDIR" -type d -exec chmod 755 {} +
                if [ -d "$DESTDIR/usr/lib" ]; then find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; fi
        """)
        with open(justfile_path, "w", encoding="utf-8") as f:
            f.write(justfile_content)
            
        print(f"Successfully created package skeleton for '{args.pkgname}' at {pkg_dir} ✓")
    except Exception as e:
        print(f"Error creating package skeleton: {e}", file=sys.stderr)
        sys.exit(1)

# ==============================================================================
# Main CLI Entrypoint
# ==============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Freeside Package Manager (fspack) Helper Utility"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Resolve Command
    resolve_parser = subparsers.add_parser("resolve", help="Resolve topologically sorted package order")
    resolve_group = resolve_parser.add_mutually_exclusive_group(required=False)
    resolve_group.add_argument("--pkg", help="Resolve dependencies for a single package")
    resolve_group.add_argument("--group", help="Resolve dependencies for a package group")
    resolve_parser.add_argument("groups", nargs="*", help="Groups to resolve (e.g. base builder)")

    # Convert Command
    convert_parser = subparsers.add_parser("convert", help="Convert an Arch Linux PKGBUILD to Freeside format")
    convert_parser.add_argument("pkgname", help="Name of the package on Arch GitLab")

    # Build Command
    build_parser = subparsers.add_parser("build", help="Build package(s) inside the container sandbox")
    build_group = build_parser.add_mutually_exclusive_group(required=True)
    build_group.add_argument("--pkg", help="Build a single package")
    build_group.add_argument("--group", help="Build a package group")
    build_parser.add_argument("--with-deps", action="store_true", help="Build package dependencies too")
    build_parser.add_argument("--keep-all-logs", action="store_true", help="Keep build log files even on success")
    build_parser.add_argument("--keep-sandbox", action="store_true", help="Keep the build sandbox and workspace directories")

    # Info Command
    info_parser = subparsers.add_parser("info", help="Get metadata info for a package")
    info_parser.add_argument("pkgname", help="Name of the package to query")
    info_parser.add_argument("--simple", action="store_true", help="Print raw metadata in simple line-by-line format for scripting")

    # Create Command
    create_parser = subparsers.add_parser("create", help="Create a new package skeleton")
    create_parser.add_argument("pkgname", help="Name of the package to create")
    create_parser.add_argument("--version", default="1.0.0", help="Version of the package (default: 1.0.0)")
    create_parser.add_argument("--description", default="", help="Description of the package")
    create_parser.add_argument("--group", default="extra", help="Group of the package (default: extra)")

    # List Command
    list_parser = subparsers.add_parser("list", help="List package groups and packages")
    list_group = list_parser.add_mutually_exclusive_group(required=False)
    list_group.add_argument("--group", help="List all packages in a given group")
    list_group.add_argument("--groups", action="store_true", help="List only the names of the groups")

    # Verify Command
    verify_parser = subparsers.add_parser("verify", help="Verify package validity")
    verify_parser.add_argument("pkgname", nargs="?", help="Name of the package to verify")
    verify_parser.add_argument("--all", action="store_true", help="Verify all packages in the repository")

    args = parser.parse_args()

    if args.command == "resolve":
        handle_resolve(args)
    elif args.command == "convert":
        handle_convert(args)
    elif args.command == "build":
        handle_build(args)
    elif args.command == "info":
        handle_info(args)
    elif args.command == "create":
        handle_create(args)
    elif args.command == "list":
        handle_list(args)
    elif args.command == "verify":
        handle_verify(args)

if __name__ == "__main__":
    main()
