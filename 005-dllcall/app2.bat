setlocal
del app2-dm32.exe
dub build :app2 --build=release
del easy_win_*.c
del easy_win_*.obj
::app2-dm32.exe my_library release/dlltest.dll 409600
app2-dm32.exe my_library dlltest.dll 800000
app2-dm32.exe sqlite sqlite-win-32bit-3200100.dll 800000
app2-dm32.exe libcurl libcurl.dll 800000

endlocal
