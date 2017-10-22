setlocal
dub build :app2 --build=release
app2-dm32.exe > dll_data.c
::sakura dll_data.h
endlocal
