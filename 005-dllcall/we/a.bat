cl /MD -oa-main.exe a-main.cpp
if %errorlevel% neq 0 ( exit /b )
c:\dm\bin\dmc -c easywin_loader.cpp
if %errorlevel% neq 0 ( exit /b )
c:\dm\bin\htod -cpp -hc easywin_loader.cpp
if %errorlevel% neq 0 ( exit /b )
::edub a-run.exe run a.d easywin_loader.obj --build=release os.lib lib1.lib c:\dm\lib\stlp45dm_static.lib wininet.lib data=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin
edub a.dll build a.d easywin_loader.obj --build=release os.lib lib1.lib c:\dm\lib\stlp45dm_static.lib wininet.lib data=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin def=WindowsVista
if %errorlevel% neq 0 ( exit /b )
::cmd32 a.dll "https://github.com/cppcommons/d-sample/trunk/README.md"
::cmd32 a.dll "https://github.com/cppcommons/d-sample/trunk"
::run32 a.dll "https://github.com/cppcommons/d-sample/trunk"
start run32 -ac a.dll "https://github.com/cppcommons/d-sample/trunk"
::echo errorlevel=%errorlevel%
