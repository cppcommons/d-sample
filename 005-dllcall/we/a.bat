chcp 65001
edub a-run.exe run a.d --build=release os.lib lib1.lib c:\dm\lib\stlp45dm_static.lib wininet.lib data=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin
if %errorlevel% neq 0 ( exit /b )
