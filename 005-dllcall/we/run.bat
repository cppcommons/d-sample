edub dcmd32.exe build run.d --build=release def=WindowsVista
if %errorlevel% neq 0 ( exit /b )
::start dcmd32 -ac -w 2000 np.dll@:runClient a b c
::start dcmd32 -ac np.dll@:runServer a b c
dcmd32 np.dll a b c
