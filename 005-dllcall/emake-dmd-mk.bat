::emake-dmd build=release emake-dmd.exe emake-dmd.d emake_common.d
::dmd -ofemake-dmd.exe -g -debug -o- emake-dmd.d emake_common.d
del emake-dmd.exe
rmdir /s /q emake-dmd.exe.bin
dmd -of=emake-dmd.exe -od=emake-dmd.exe.bin emake-dmd.d emake_common.d emake_common_codeblocks.d
if %errorlevel% neq 0 ( exit /b )
copy emake-dmd.exe E:\opt\bin32\
::emake-dmd edit x.exe a.d -IC:\test\import
del x.exe.cbp
rmdir /s /q x.exe.bin
emake-dmd build x.exe a.d -IC:\test\import -- a b c
emake-dmd build=DEBUG x.exe a.d -IC:\test\import -- a b c
