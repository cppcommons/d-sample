copy edub2.d edub.d
del edub.exe
rmdir /s /q edub.exe.bin
dmd -of=edub.exe -od=edub.exe.bin -g -debug edub.d
if %errorlevel% neq 0 ( exit /b )
copy edub.exe E:\opt\bin32\
copy edub.exe C:\Users\Public\dev1\bin32
rmdir /s /q edub.exe.bin
del edub.exe
