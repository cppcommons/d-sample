setlocal
set BUILD=0
if "%1" equ "build" set BUILD=1
if not exist easy-dm32.exe set BUILD=1
if "%BUILD%" equ "1" (
    del easy-dm32.exe
    edub apps.json build :easy --build=release
)
easy-dm32.exe my_library dlltest.dll 800000
easy-dm32.exe sqlite sqlite-win-32bit-3200100.dll 800000
easy-dm32.exe libcurl libcurl.dll 800000
::easy-dm32.exe my_dll main.bld\Release\my_dll.dll 800000

endlocal
