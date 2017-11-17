c:\dm\bin\htod -cpp -hc os2.h os2.d
if %errorlevel% neq 0 ( exit /b )
rm -rf os2.dll.bin
edub os2.dll build os2_impl.d
if %errorlevel% neq 0 ( exit /b )
C:\dm\bin\implib /system os2-dm32.lib os2.dll
if %errorlevel% neq 0 ( exit /b )
rm -rf os2.exe.bin
edub os2_main.exe run os2_main.d os2-dm32.lib vc6-run-dm32.lib
if %errorlevel% neq 0 ( exit /b )
pexports os2.dll > os2.def
if %errorlevel% neq 0 ( exit /b )
setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\VC98\Bin\VCVARS32.BAT"
@echo on
lib /DEF:os2.def /MACHINE:X86 /OUT:os2-vc6.lib
if %errorlevel% neq 0 ( exit /b )
endlocal
