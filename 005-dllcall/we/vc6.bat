pexports e:\opt\opt.m32\usr\bin\msys-svn_subr-1-0.dll > msys-svn_subr-1-0.def
lib /DEF:msys-svn_subr-1-0.def /MACHINE:X86 /OUT:msys-svn_subr-1-0.lib
pexports e:\opt\opt.m32\usr\bin\msys-apr-1-0.dll > msys-apr-1-0.def
lib /DEF:msys-apr-1-0.def /MACHINE:X86 /OUT:msys-apr-1-0.lib
if %errorlevel% neq 0 ( exit /b )

c:\dm\bin\htod -cpp -hc vc6.cpp
if %errorlevel% neq 0 ( exit /b )
premake --file vc6.pmk --target vs6
msdev.com vc6.dsp /MAKE ALL /REBUILD
premake --file vc6-run.pmk --target vs6
msdev.com vc6-run.dsp /MAKE ALL /REBUILD

::C:\dm\bin\implib /system vc6-run-dm32.lib vc6-run.dll
::if %errorlevel% neq 0 ( exit /b )

::exit /b
setlocal
::set PATH=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin;%PATH%
::set PATH=e:\opt\opt.m32\usr\bin;%PATH%
vc6-run.exe https://github.com/cppcommons/d-sample/trunk
endlocal

exit /b

:C:\dm\bin\implib /system libapr-1-dm32.lib E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin\libapr-1.dll
:C:\dm\bin\implib /system libsvn_client-1-dm32.lib E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin\libsvn_client-1.dll
C:\dm\bin\implib libapr-1-dm32.lib E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin\libapr-1.dll
C:\dm\bin\implib /system libsvn_client-1-dm32.lib E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin\libsvn_client-1.dll
C:\dm\bin\implib /system libsvn_fs-1-dm32.lib E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin\libsvn_fs-1.dll
C:\dm\bin\implib /system libsvn_wc-1-dm32.lib E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin\libsvn_wc-1.dll
C:\dm\bin\implib /system libsvn_subr-1-dm32.lib E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin\libsvn_subr-1.dll

C:\dm\bin\dmc -ovc6-run-dm32.exe vc6.cpp os2-dm32.lib ^
 libapr-1-dm32.lib ^
 libsvn_client-1-dm32.lib ^
 libsvn_fs-1-dm32.lib ^
 libsvn_wc-1-dm32.lib ^
 libsvn_subr-1-dm32.lib ^
 -IE:/opt/svn/vc6/svn-win32-1.8.17-ap24_dev/svn-win32-1.8.17/include ^
 -IE:/opt/svn/vc6/svn-win32-1.8.17-ap24_dev/svn-win32-1.8.17/include/apr

setlocal
set PATH=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin;%PATH%
vc6-run-dm32.exe https://github.com/cppcommons/d-sample/trunk
endlocal
