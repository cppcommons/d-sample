::dub run :idl --build=release
::dub run :idl --build=debug
chcp 65001 &::utf-8
dub build :idl --build=debug
idl-dm32.exe idl-test.txt
