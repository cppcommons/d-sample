setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\VC98\Bin\VCVARS32.BAT"
@echo on
cl /MD -oa-main.exe a-main.cpp
if %errorlevel% neq 0 ( exit /b )
endlocal
c:\dm\bin\dmc -c easywin_loader.cpp
if %errorlevel% neq 0 ( exit /b )
c:\dm\bin\htod -cpp -hc easywin_loader.cpp
if %errorlevel% neq 0 ( exit /b )
chcp 65001
::edub a-run.exe run a.d easywin_loader.obj --build=release os.lib lib1.lib c:\dm\lib\stlp45dm_static.lib wininet.lib data=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin
edub a-dll.dll build a.d easywin_loader.obj --build=release os.lib lib1.lib c:\dm\lib\stlp45dm_static.lib wininet.lib data=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin
if %errorlevel% neq 0 ( exit /b )
a-main.exe a b c