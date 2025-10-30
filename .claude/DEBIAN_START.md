# Quick Start for Debian Session

## 🚀 What to Tell Claude AI

When you open Claude AI in Debian, start with:

```
Continuing from Windows session - testing cross-platform CMake setup.
Last commit: 896886c
Check .claude/SESSION_CONTEXT.md for full context.
```

## ✅ What's Already Done (on Windows)

1. ✅ CMake build system configured
2. ✅ VS Code integration complete
3. ✅ Platform-specific configs (Linux/Windows)
4. ✅ Documentation in docs/markdown/
5. ✅ All committed and pushed to GitHub

## 🎯 First Things to Test on Debian

1. **Open the project in VS Code**
   ```bash
   cd ~/Dropbox/.../c_ui_sdl_cairo_base
   code .
   ```

2. **Build with CMake**
   ```bash
   cmake -B build -DCMAKE_BUILD_TYPE=Debug
   cmake --build build
   ```

3. **Test debugging**
   - Press F5
   - Select: "Debug C Application (CMake) - Linux"

4. **Report results to Claude AI**
   - What worked?
   - Any errors or issues?

## 📝 Files to Show Claude AI if Issues

- `.vscode/launch.json` - Debug configurations
- `.vscode/c_cpp_properties.json` - IntelliSense config
- `CMakeLists.txt` - Build configuration
- Build output errors

## 🔗 Session Continuity Tips

- Git history shows all changes: `git log --oneline`
- Modified files list: `git diff HEAD~1 --name-only`
- Documentation: `docs/markdown/CMAKE_DEVELOPMENT.md`
