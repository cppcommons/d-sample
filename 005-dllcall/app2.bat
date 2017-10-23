setlocal
del app2-dm32.exe
dub build :app2 --build=release
del dll_data*.c
app2-dm32.exe my_library release/dlltest.dll 409600
endlocal
