edub domtest.exe build ^
app.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
curl.d@https://github.com/adamdruppe/arsd/blob/master/curl.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
../lib_entry.lib ^
[d2sqlite3:~master:all-included]
echo errorlevel=%errorlevel%

::goto skip
edub test1.exe build ^
https://github.com/Bystroushaak/DHTMLParser/blob/master/dhtmlparser.d ^
https://github.com/Bystroushaak/DHTMLParser/blob/master/quote_escaper.d ^
https://github.com/Bystroushaak/DHTMLParser/blob/master/examples/find_links.d ^
[d2sqlite3:~master:all-included]
:skip