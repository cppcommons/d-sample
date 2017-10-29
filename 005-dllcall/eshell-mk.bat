emake-dmd build=release eshell.exe eshell.d emake_common.d
if %errorlevel% neq 0 ( exit /b )
copy eshell.exe E:\opt\bin32\
::emake-cpp build=release ___vcapp1.exe vcapp1.cpp -Ihidden easy_win_*.c* -LINK=-p512
::eshell C:\dm\bin\dmc -c easy_win_*.c*
