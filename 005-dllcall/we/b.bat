chcp 65001
edub b-run.exe run b.d --build=release lib1.lib c:\dm\lib\stlp45dm_static.lib wininet.lib
::edub b-run.exe run b.d --build=debug lib1.lib c:\dm\lib\stlp45dm_static.lib wininet.lib
if %errorlevel% neq 0 ( exit /b )
