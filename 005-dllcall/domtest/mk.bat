edub domtest.exe build ^
app.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
curl.d@https://github.com/adamdruppe/arsd/blob/master/curl.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
../lib_entry.lib
echo errorlevel=%errorlevel%

goto skip
edub test1.exe init src=. ^
app.d ^
arsd/characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
arsd/curl.d@https://github.com/adamdruppe/arsd/blob/master/curl.d ^
arsd/dom.d@https://github.com/adamdruppe/arsd/blob/master/dom.d ^
[d2sqlite3:~master:all-included]
:skip