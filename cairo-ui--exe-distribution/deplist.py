
#!/usr/bin/env python3
"""
Wrapper script to call deplister.exe and capture its non-interactive textual output.
"""

import subprocess
import sys
import os
import argparse
import json
import shutil

def find_dll_path(dll_name):
    """Find the full path of a DLL using 'where' command."""
    try:
        result = subprocess.run(
            ['where', dll_name],
            capture_output=True,
            text=True,
            check=False
        )
        if result.returncode == 0 and result.stdout.strip():
            # Return the first path found
            return result.stdout.strip().split('\n')[0].strip()
    except Exception:
        pass
    return None

def recursive_invocation_of_deplister(dll_name, processed_dlls=None, depth=0, quiet=False):
    if processed_dlls is None:
        processed_dlls = set()
    if dll_name in processed_dlls:
        return processed_dlls
    processed_dlls.add(dll_name)

    # Call deplister.exe for the given dll_name
    command_string = "deplister.exe"
    args = [dll_name]
    text = run_process(command_string, args, quiet=True)  # Always quiet in recursive mode
    
    list_items = text.splitlines()
    for item in list_items:
        values = item.split(',')
        if values and values[0].strip():
            dep_dll_name = values[0].strip()
            indent = "  " * depth
            if not quiet:
                print(f"{indent}├─ {dep_dll_name} (dependency of {dll_name})")
            returned = recursive_invocation_of_deplister(dep_dll_name, processed_dlls, depth + 1, quiet)
            if returned:
                # merge returned set into processed_dlls set
                processed_dlls.update(returned)
    return processed_dlls

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description='Wrapper for deplister.exe to analyze DLL dependencies',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('target', help='Executable or DLL file to analyze')
    parser.add_argument('-r', '--recursive', action='store_true',
                        help='Recursively analyze all dependencies')
    parser.add_argument('-f', '--format', choices=['list', 'tree', 'json'],
                        default='list', help='Output format (default: list)')
    
    args = parser.parse_args()
    
    # Always use quiet mode and recursive mode by default
    args.quiet = True
    args.recursive = True
    
    command_string = "deplister.exe"
    text = run_process(command_string, [args.target], quiet=args.quiet)

    # Do something with the captured output
    set_of_dlls = set()
    list_items = text.splitlines()
    for item in list_items:
        # split comma-separated values
        values = item.split(',')
        # if first value is valid add it to set_of_dlls
        if values and values[0].strip():
            dll_name = values[0].strip()
            if not args.quiet:
                print(f"Found DLL: {dll_name}")
            set_of_dlls.add(dll_name)
    
    # If recursive mode, process each DLL's dependencies
    all_dlls = set(set_of_dlls)
    if args.recursive:
        if not args.quiet and args.format == 'tree':
            print(f"\n=== Dependency Tree for {args.target} ===")
        
        for dll in list(set_of_dlls):
            if args.format == 'tree' and not args.quiet:
                print(f"\n{dll}:")
            deps = recursive_invocation_of_deplister(dll, set(), 1, args.quiet or args.format != 'tree')
            all_dlls.update(deps)
    
    # Output based on format
    if args.format == 'list':
        # Build list of (dll, path) tuples
        dll_paths = []
        for dll in all_dlls:
            path = find_dll_path(dll)
            dll_paths.append((dll, path if path else 'NOT_FOUND'))
        
        # Sort by path, then by dll name
        dll_paths.sort(key=lambda x: (x[1].lower(), x[0].lower()))
        
        # Filter out System32 and NOT_FOUND by default
        filtered_paths = [
            (dll, path) for dll, path in dll_paths 
            if path != 'NOT_FOUND' and 'system32' not in path.lower()
        ]
        
        # Print filtered list
        for dll, path in filtered_paths:
            print(path)
    elif args.format == 'tree':
        if args.quiet:
            print(f"Total unique DLLs found: {len(all_dlls)}")
    elif args.format == 'json':
        dll_info = []
        for dll in sorted(all_dlls):
            path = find_dll_path(dll)
            dll_info.append({
                'name': dll,
                'path': path if path else 'NOT_FOUND'
            })
        output = {
            'target': args.target,
            'total_dlls': len(all_dlls),
            'dlls': dll_info
        }
        print(json.dumps(output, indent=2))

    return 0

def run_process(command_string, args=None, quiet=False):
    """Call command_string and print its output."""
    if args is None:
        args = []
    
    try:
        # Look for command_string in the same directory as this script
        script_dir = os.path.dirname(os.path.abspath(__file__))
        deplister_path = os.path.join(script_dir, command_string)
        
        # If not found in script directory, assume it's in PATH
        if not os.path.exists(deplister_path):
            deplister_path = command_string
        
        # Run command_string with arguments and capture output
        result = subprocess.run(
            [deplister_path] + args,
            capture_output=True,
            text=True,
            check=False  # Don't raise exception on non-zero exit code
        )
        
        # Print the output only if not quiet
        if not quiet:
            print(result.stdout, end='')
        
        # Print stderr if any (usually warnings or errors)
        if result.stderr and not quiet:
            print(result.stderr, end='', file=sys.stderr)

        #############################
        # Process the captured output
        text = result.stdout
        return text
        
    except FileNotFoundError:
        print(f"Error: command_string not found.", file=sys.stderr)
        print(f"Please ensure command_string is in the same directory as this script or in your PATH.", file=sys.stderr)
        return ""
        
    except subprocess.CalledProcessError as e:
        print(f"Error: command_string exited with code {e.returncode}", file=sys.stderr)
        if e.stdout:
            print(e.stdout, end='')
        if e.stderr:
            print(e.stderr, end='', file=sys.stderr)
        return ""
        
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return ""


if __name__ == "__main__":
    sys.exit(main())

