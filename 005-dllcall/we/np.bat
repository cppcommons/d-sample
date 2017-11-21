edub np.dll build np.d --build=release def=WindowsVista c:\dm\lib\stlp45dm_static.lib wininet.lib 
if %errorlevel% neq 0 ( exit /b )
start cmd32 np.dll,runServer a b c
::start run32 -c np.dll,runServer a b c
start cmd32 np.dll,runClient a b c
