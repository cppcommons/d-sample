edub qiitalib-ms64.lib build arch=ms64 ^
qiitalib.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
[vibe-d] [dateparser]
if %errorlevel% neq 0 (exit /b)
edub qiitadb-ms64.lib build arch=ms64 ^
qiitadb.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
"[d2sqlite3:  :without-lib]"
if %errorlevel% neq 0 (exit /b)
