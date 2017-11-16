premake --file vc6.pmk --target vs6
"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" vc6-run.dsp /MAKE ALL /REBUILD
::"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" vc6-run.dsp /MAKE ALL /BUILD
::premake --file vc6.pmk --clean
setlocal
set PATH=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin;%PATH%
vc6-run.exe https://github.com/cppcommons/d-sample/trunk
::copy vc6-run.exe E:\opt\svn\vc6\svn-win32-1.7.22\bin
::E:\opt\svn\vc6\svn-win32-1.7.22\bin\vc6-run.exe https://github.com/cppcommons/d-sample/trunk
::copy vc6-run.exe E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin
::E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin\vc6-run.exe https://github.com/cppcommons/d-sample/trunk
::copy vc6-run.exe E:\opt\svn\vc6\svn-win32-1.6.19\bin
::E:\opt\svn\vc6\svn-win32-1.6.19\bin\vc6-run.exe https://github.com/cppcommons/d-sample/trunk
::E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin\svn.exe ls https://github.com/cppcommons/d-sample/trunk
endlocal