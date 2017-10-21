setlocal
dub build :mylib --build=release
dub run :app1 --build=release
::dub build :app2 --build=release
endlocal
