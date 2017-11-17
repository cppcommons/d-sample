::cp vc6.cpp vc6_iface.h
::c:\dm\bin\htod -cpp -hc vc6_iface.h
::cat vc6_iface.d
c:\dm\bin\htod -cpp -hc vc6.cpp
if %errorlevel% neq 0 ( exit /b )
::premake --file vc6-dll.pmk --target vs6
::"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" vc6-dll.dsp /MAKE ALL /REBUILD
premake --file vc6.pmk --target vs6
if %errorlevel% neq 0 ( exit /b )
"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" vc6-run.dsp /MAKE ALL /REBUILD
if %errorlevel% neq 0 ( exit /b )

C:\dm\bin\implib /system vc6-run-dm32.lib vc6-run.dll
if %errorlevel% neq 0 ( exit /b )

exit /b
setlocal
set PATH=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin;%PATH%
vc6-run.exe https://github.com/cppcommons/d-sample/trunk
endlocal
