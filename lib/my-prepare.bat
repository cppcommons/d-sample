if not exist libcurl.dll copy C:\D\dmd2\windows\bin\libcurl.dll .

::C:\D\dmd2\windows\bin\dmd.exe -I=lib app.d lib/pegged-dm32.lib winhttp-dm32.lib
::C:\D\dmd2\windows\bin\dmd.exe -m32mscoff -I=lib app2.d lib/pegged-ms32.lib winhttp.lib
implib /system sqlite-win-32bit-3200100-dm32.lib sqlite-win-32bit-3200100.dll
setlocal
call "C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/vcvarsall.bat" x86
echo on
if not exist sqlite-win-32bit-3200100-ms32.lib (
  lib /def:sqlite-win-32bit-3200100.def /machine:x86 /out:sqlite-win-32bit-3200100-ms32.lib
 )
endlocal

C:\D\dmd2\windows\bin\dmd -w -m32       -wi -O -release -noboundscheck -lib -ofpegged-dm32.lib pegged/peg.d pegged/grammar.d pegged/parser.d pegged/introspection.d pegged/dynamic/grammar.d pegged/dynamic/peg.d
C:\D\dmd2\windows\bin\dmd -w -m32mscoff -wi -O -release -noboundscheck -lib -ofpegged-ms32.lib pegged/peg.d pegged/grammar.d pegged/parser.d pegged/introspection.d pegged/dynamic/grammar.d pegged/dynamic/peg.d
