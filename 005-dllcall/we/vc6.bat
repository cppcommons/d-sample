--premake --file vc6-dll.pmk --target vs6
--"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" vc6-dll.dsp /MAKE ALL /REBUILD
premake --file vc6.pmk --target vs6
"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" vc6-run.dsp /MAKE ALL /REBUILD
setlocal
set PATH=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin;%PATH%
vc6-run.exe https://github.com/cppcommons/d-sample/trunk
endlocal
c:\dm\bin\htod -cpp -hc os2.h os2.d
