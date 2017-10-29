::emake-dmd build=release easy.exe easy.d
eshell C:\D\dmd2\windows\bin\dmd -ofeasy.exe easy.d
if %errorlevel% neq 0 ( exit /b )
easy.exe my_library dlltest.dll 800000
easy.exe sqlite sqlite-win-32bit-3200100.dll 800000
easy.exe libcurl libcurl.dll 800000
::easy.exe my_dll main.bld\Release\my_dll.dll 800000
