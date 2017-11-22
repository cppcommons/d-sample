::edub np.dll build np.d --build=release def=WindowsVista c:\dm\lib\stlp45dm_static.lib wininet.lib 
edub np.dll build np.d arch=ms32 --build=release def=WindowsVista c:\dm\lib\stlp45dm_static.lib wininet.lib 
if %errorlevel% neq 0 ( exit /b )
run32 np.dll
::start cmd /c run32 np.dll@:runClient a b c
start run32 -ac -w 2000 np.dll@:runClient a b c
::run32 np.dll@:runServer a b c
start run32 -ac np.dll@:runServer a b c
