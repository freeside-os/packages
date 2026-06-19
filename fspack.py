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
    return os.path.dirname(os.path.abspath(__file__))

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

def install_package(tarball_path):
    """Installs a compiled package tarball into the container root /."""
    print(f"Installing {os.path.basename(tarball_path)} into container root (/)....")
    subprocess.run(["tar", "-xzf", tarball_path, "--exclude=meta/*", "-C", "/"], check=True)

def fetch_source_url(url, dest_dir, checksum_algo=None, checksum_val=None):
    """Downloads source from a URL and verifies checksum."""
    filename = url.split('/')[-1].split('?')[0]
    dest_path = os.path.join(dest_dir, filename)
    print(f"  Downloading {url} -> {dest_path}...")
    
    urllib.request.urlretrieve(url, dest_path)
    
    if checksum_val and checksum_algo == "sha256":
        actual = compute_sha256(dest_path)
        if actual != checksum_val:
            os.remove(dest_path)
            raise Exception(f"Integrity check failed for {filename}! Expected SHA256: {checksum_val}, Got: {actual}")
        print(f"  Checksum OK: {filename}")

def build_package_impl(pkg_name):
    """Builds and packages a single package inside the container."""
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
    output_dir = "/workspace/build/packages"
    tarball_path = os.path.join(output_dir, tarball_name)
    
    if os.path.isfile(tarball_path):
        print(f"[{pkg_name}] Already built — skipping compilation ({tarball_name})")
        install_package(tarball_path)
        return True

    print("=" * 64)
    print(f"[{pkg_name}] Building {pkg_name}-{pkg_version} (group: {pkg_group})")
    print("=" * 64)

    ws = f"/workspace/build/workspace/{pkg_name}-{pkg_version}"
    src_dir = f"{ws}/src"
    dest_dir = f"{ws}/dest"
    
    if os.path.exists(ws):
        shutil.rmtree(ws)
    os.makedirs(src_dir, exist_ok=True)
    os.makedirs(dest_dir, exist_ok=True)
    
    print(f"[{pkg_name}] Fetching sources...")
    for source in manifest.sources:
        if source.url:
            algo = source.checksum.algorithm if source.checksum else None
            val = source.checksum.value if source.checksum else None
            fetch_source_url(source.url, src_dir, algo, val)
        elif source.file:
            src_file_path = os.path.join(pkg_dir, source.file)
            if not os.path.exists(src_file_path):
                raise Exception(f"Local source file not found at {src_file_path}")
            print(f"  Copying local file: {source.file}")
            shutil.copy(src_file_path, os.path.join(src_dir, source.file))
        elif source.git:
            git_url = source.git
            ref = source.ref
            print(f"  Cloning git repo: {git_url} (ref: {ref})")
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

    print(f"[{pkg_name}] Running: just build")
    subprocess.run(
        ["just", "-f", os.path.join(ws, "package.justfile"), "-d", src_dir, "build"], 
        env=env, 
        check=True
    )

    print(f"[{pkg_name}] Running: just package")
    subprocess.run(
        ["just", "-f", os.path.join(ws, "package.justfile"), "-d", src_dir, "package"], 
        env=env, 
        check=True
    )

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

    print(f"[{pkg_name}] Generating files.toml ledger...")
    ledger_content = generate_files_ledger(staging_dir)
    with open(os.path.join(staging_dir, "meta/files.toml"), "w", encoding="utf-8") as f:
        f.write(ledger_content)

    os.makedirs(output_dir, exist_ok=True)
    print(f"[{pkg_name}] Creating tarball: {tarball_name}")
    subprocess.run(["tar", "-czf", tarball_path, "-C", staging_dir, "."], check=True)

    install_package(tarball_path)

    shutil.rmtree(ws)
    print(f"[{pkg_name}] Done ✓")
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
                for pkg in ordered_packages:
                    build_package_impl(pkg)
                print(f"\nBuild Complete for: {args.pkg} and dependencies ✓")
            else:
                build_package_impl(args.pkg)
        except Exception as e:
            print(f"Build Failed: {e}", file=sys.stderr)
            sys.exit(1)
    elif args.group:
        try:
            print(f"Resolving build order for group: {args.group}...")
            ordered_packages = resolve_dependencies({args.group})
            print(f"Found {len(ordered_packages)} packages in group: {ordered_packages}")
            
            for pkg in ordered_packages:
                build_package_impl(pkg)
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
        """)
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(manifest_content)
            
        # Create package.justfile
        justfile_path = os.path.join(pkg_dir, "package.justfile")
        justfile_content = textwrap.dedent("""\
            build:
                tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
                cd $PKG_NAME-$PKG_VERSION && ./configure --prefix=/usr && make -j$(nproc)

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

if __name__ == "__main__":
    main()
