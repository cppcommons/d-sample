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
::edub2 apps.json debug
::goto skip
::src=C:\D\dmd2\src\phobos 
edub2 test1.dll debug app1.d ../*.d emake*.d .\emake*.d ^
arsd/dom.d@https://raw.githubusercontent.com/adamdruppe/arsd/master/dom.d ^
defines=A:@B ^
defs=C:@D ^
main=main.d ^
data=..\abc\data1 ^
data=..\abc\data2 ^
include=..\abc\import1 ^
inc=..\abc\import2 ^
libs=gdi32.lib:kernel32.lib ^
[d2sqlite3A] ^
[d2sqlite3B#~master] ^
[d2sqlite3C#~master#without-lib] ^
[d2sqlite3D#~master#without{#}lib] ^
"  [d2sqlite3E#~master#without-lib]  " [d2sqlite3F##without{#}lib] "[hibernated#@hibernated-0.3.2]"
echo errorlevel=%errorlevel%
:skip
::edub2 test2.exe build app1.d curl.d lib_entry.lib [d2sqlite3:~master:without-lib] --build=release
::echo errorlevel=%errorlevel%
