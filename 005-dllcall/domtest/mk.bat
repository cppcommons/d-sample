edub domtest.exe build src=. ^
app.d ^
arsd/characterencodings.d@https://raw.githubusercontent.com/adamdruppe/arsd/master/characterencodings.d ^
arsd/curl.d@https://raw.githubusercontent.com/adamdruppe/arsd/master/curl.d ^
arsd/dom.d@https://raw.githubusercontent.com/adamdruppe/arsd/master/dom.d ^
../lib_entry.lib
echo errorlevel=%errorlevel%
