::emake-dmd build=release edub2.exe edub2.d emake_common.d
del edub2.exe
rmdir /s /q edub2.exe.bin
dmd -of=edub2.exe -od=edub2.exe.bin -g -debug edub2.d
if %errorlevel% neq 0 ( exit /b )
rmdir /s /q edub2.exe.bin

::[test]
::edub2 app1.dub.json --cleanup --build=release
::echo errorlevel=%errorlevel%
::edub2 apps.json build :app3
::edub2 app1.dub.json generate visuald
goto skip
edub2 test1.exe init app1.d ^
source=..\abc\source1 ^
src=..\abc\source2 ^
resource=..\abc\data1 ^
res=..\abc\data2 ^
include=..\abc\import1 ^
inc=..\abc\import2 ^
libs=gdi32.lib:kernel32.lib ^
[d2sqlite3A] ^
[d2sqlite3B:~master] ^
[d2sqlite3C:~master:without-lib] ^
[d2sqlite3D:~master:without{:}lib] ^
"  [d2sqlite3E:~master:without-lib]  "
echo errorlevel=%errorlevel%
:skip
edub2 test2.exe build app1.d curl.d lib_entry.lib [d2sqlite3:~master:without-lib] --build=release
echo errorlevel=%errorlevel%
