edub np.dll build np.d --build=release def=WindowsVista c:\dm\lib\stlp45dm_static.lib wininet.lib 
if %errorlevel% neq 0 ( exit /b )
::start cmd /c run32 np.dll,runClient a b c
start run32 -ac np.dll,runClient a b c
run32 np.dll,runServer a b c
