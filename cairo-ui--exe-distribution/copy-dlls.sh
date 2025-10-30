#!/bin/bash
# Copy all required DLLs for the target executable to the current directory

if [ $# -eq 0 ]; then
    echo "Usage: $0 <executable>"
    echo "Example: $0 cairo-imgui-demo.exe"
    exit 1
fi

TARGET="$1"

echo "Finding dependencies for $TARGET..."

# Get the list of DLL paths and copy each one
python deplist.py "$TARGET" | while IFS= read -r dll_path; do
    # Convert Windows path to Unix-style path for bash
    unix_path=$(cygpath "$dll_path" 2>/dev/null || echo "$dll_path")
    
    if [ -f "$unix_path" ]; then
        echo "Copying: $(basename "$dll_path")"
        cp "$unix_path" .
    else
        echo "Warning: File not found: $dll_path"
    fi
done

echo "Done! DLLs copied to current directory."
