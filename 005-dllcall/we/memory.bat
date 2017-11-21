::premake --file memory.pmk --target vs6
::if %errorlevel% neq 0 ( exit /b )
::"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" memory-run.dsp /MAKE ALL /REBUILD
::if %errorlevel% neq 0 ( exit /b )
::memory-run.exe
::c:\dm\bin\dmc -omemory-run-dm32.exe -IC:\dm\stlport\stlport memory.cpp
::memory-run-dm32.exe
cl -MT -GX memory.cpp /link /out:memory-vc6.exe /subsystem:console shell32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )
setlocal
set PATH=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin;%PATH%
memory-vc6.exe
endlocal