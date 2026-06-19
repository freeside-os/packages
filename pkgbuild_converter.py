#!/usr/bin/env python3
import os
import sys
import re
import urllib.request
import urllib.error
import textwrap


def build_arch_url(pkgname):
    """Constructs the Arch Linux GitLab URL for a given package."""
    return f"https://gitlab.archlinux.org/archlinux/packaging/packages/{pkgname}/-/raw/main/PKGBUILD"

def fetch_pkgbuild(url):
    """Fetches the PKGBUILD content from a given URL."""
    print(f"Fetching PKGBUILD from {url}...")
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as response:
        status_code = response.status  # Alternately: response.getcode()
        if status_code != 200:
            raise Exception(f"Unable to retrieve PKGBUILD. [HTTP Statuc Code: {status_code}]")
        return response.read().decode('utf-8')

def extract_variable(content, var_name, is_array=False):
    """Extracts bash variables from the PKGBUILD using Regex."""
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
    """Extracts the body of a bash function from the PKGBUILD."""
    # Relaxed regex: Catch 'package()', 'package_findutils()', etc.
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
    
    # Freeside cleanup: map Arch's variables to Freeside's standard variables
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
    
    # Strip out standard cd "$srcdir/$pkgname" as justfiles usually run in the extracted dir
    body = re.sub(r'^.*cd\s+.*\$srcdir.*$', '', body, flags=re.MULTILINE).strip()
    
    return body

def generate_freeside_package(pkgbuild_content):
    """Maps the PKGBUILD components to Freeside's manifest and justfile."""
    
    # 1. Parse Metadata for package.manifest
    pkgname = extract_variable(pkgbuild_content, 'pkgname')
    
    # Handle split packages and array declarations
    if not pkgname:
        pkgbase = extract_variable(pkgbuild_content, 'pkgbase')
        if pkgbase:
            pkgname = pkgbase
        else:
            pkgname_array = extract_variable(pkgbuild_content, 'pkgname', is_array=True)
            pkgname = pkgname_array if pkgname_array else ""

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

        [source]
        url = "{primary_source}"
        sha256 = "{primary_sha}"
    """)
    
    # 2. Parse Functions for package.justfile
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

def main():
    if len(sys.argv) != 2:
        print("Usage: ./pkgbuild_converter.py <package_name>")
        print("Example: ./pkgbuild_converter.py findutils")
        sys.exit(1)

    pkgname = sys.argv[1].strip()
    url = build_arch_url(pkgname)
    
    try:
        pkgbuild_content = fetch_pkgbuild(url)
        
        # Create a directory for the package
        os.makedirs(pkgname, exist_ok=True)
        print(f"Created directory: ./{pkgname}/")
        
        # Write the raw PKGBUILD
        pkgbuild_path = os.path.join(pkgname, "PKGBUILD")
        with open(pkgbuild_path, 'w', encoding='utf-8') as f:
            f.write(pkgbuild_content)
        print(f"Saved: {pkgbuild_path}")
        
        # Generate and write Freeside files
        manifest, justfile = generate_freeside_package(pkgbuild_content)
        
        manifest_path = os.path.join(pkgname, "package.manifest")
        with open(manifest_path, 'w', encoding='utf-8') as f:
            f.write(manifest)
        print(f"Saved: {manifest_path}")
        
        justfile_path = os.path.join(pkgname, "package.justfile")
        with open(justfile_path, 'w', encoding='utf-8') as f:
            f.write(justfile)
        print(f"Saved: {justfile_path}")
        
        print("\nConversion successful! You can now review the files and fix any complex Bash logic mapped to the Justfile.")
        
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"Error 404: PKGBUILD for '{pkgname}' not found at {url}.")
        else:
            print(f"HTTP Error {e.code}: {e.reason}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    main()

