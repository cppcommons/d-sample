::edub apps.json run :idl --build=release
::edub apps.json run :idl --build=debug
chcp 65001 &::utf-8
edub apps.json build :idl --build=debug
idl-dm32.exe idl-test.txt
