chcp 65001
edub a-run.exe run a.d --build=release os.lib lib1.lib c:\dm\lib\stlp45dm_static.lib wininet.lib
if %errorlevel% neq 0 ( exit /b )
