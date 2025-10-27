set PATH=%PATH%;%CD%\cairo-ui--exe-distribution

windows-os\luajit-mconsole.exe demo.lua

rem dont use "start" to debug
rem start windows-os\luajit-mconsole.exe demo.lua

rem use "pause" to debug
pause
