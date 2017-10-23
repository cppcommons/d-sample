setlocal
del app2-dm32.exe
dub build :app2 --build=release
del *_data.c
del *_data.obj
app2-dm32.exe my_library release/dlltest.dll 409600
endlocal
