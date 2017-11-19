chcp 65001
edub zero.dll build zero.d --build=release def=WindowsVista c:\dm\lib\stlp45dm_static.lib wininet.lib 
if %errorlevel% neq 0 ( exit /b )
rundll32 zero.dll,_run@16 a b c
echo errorlevel=%errorlevel%
