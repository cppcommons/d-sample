c:\dm\bin\dmc -c easywin_loader.cpp
c:\dm\bin\htod -cpp -hc easywin_loader.cpp
if %errorlevel% neq 0 ( exit /b )
chcp 65001
edub a-run.exe run a.d easywin_loader.obj --build=release os.lib lib1.lib c:\dm\lib\stlp45dm_static.lib wininet.lib data=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin
if %errorlevel% neq 0 ( exit /b )
