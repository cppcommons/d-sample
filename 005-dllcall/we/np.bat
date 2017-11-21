chcp 65001
edub np.dll build np.d --build=release def=WindowsVista c:\dm\lib\stlp45dm_static.lib wininet.lib 
if %errorlevel% neq 0 ( exit /b )
::start rundll32 np.dll,_run@16 a b c
::pause
::rundll32 np.dll,_runClient@16 a b c
::start run32 np.dll,runServer a b c
start cmd32 np.dll,runServer a b c
start cmd32 np.dll,runClient a b c
::cmd32 np.dll,runServer a b c
