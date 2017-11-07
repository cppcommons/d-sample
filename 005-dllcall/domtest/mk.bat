chcp 65001
edub domtest.exe run ^
app.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
../lib_entry.lib ^
[jsonizer] [dateparser]
echo errorlevel=%errorlevel%
if %errorlevel% neq 0 ( exit /b )
::domtest.exe 
goto skip

:: https://code.dlang.org/packages/htmld
edub test1.exe build ^
htmld-test.d ^
[htmld]

:: https://github.com/bakkdoor/gumbo-d
edub test2.exe build ^
https://github.com/bakkdoor/gumbo-d/blob/master/examples/find_links.d ^
https://github.com/bakkdoor/gumbo-d/blob/master/source/gumbo/capi.d ^
https://github.com/bakkdoor/gumbo-d/blob/master/source/gumbo/node.d ^
https://github.com/bakkdoor/gumbo-d/blob/master/source/gumbo/parse.d

:skip
