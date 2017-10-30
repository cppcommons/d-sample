setlocal
::emake-dmd build=release emake-dmd.exe emake-dmd.d emake_common.d
::dmd -ofemake-dmd.exe -g -debug -o- emake-dmd.d emake_common.d
dmd -of=emake-dmd.exe -od=emake-dmd.exe.bin emake-dmd.d emake_common.d
if %errorlevel% neq 0 ( exit /b )
copy emake-dmd.exe E:\opt\bin32\
emake-dmd edit x.exe a.d -IC:\test\import
emake-dmd build x.exe a.d -IC:\test\import
endlocal