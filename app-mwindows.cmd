set PATH=%PATH%;%CD%\cairo-ui--exe-distribution

rem dont use "start" to debug
start windows-os\luajit-mwindows.exe demo.lua

rem use "pause" to debug
rem pause
