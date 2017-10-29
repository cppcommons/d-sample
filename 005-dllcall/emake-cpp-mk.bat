emake-dmd build=release emake-cpp.exe emake-cpp.d emake_common.d
if %errorlevel% neq 0 ( exit /b )
copy emake-cpp.exe E:\opt\bin32\
::emake-cpp build=release vcapp1_dll.dll vcapp1.cpp -Ihidden
::emake-cpp build=release vcapp1_lib.lib vcapp1.cpp -Ihidden
::emake-cpp build=release vcapp1.exe vcapp1.cpp -Ihidden easy_win_*.c easy_win_*.cpp
emake-cpp build=release vcapp1.exe vcapp1.cpp -Ihidden easy_win_*.c*
