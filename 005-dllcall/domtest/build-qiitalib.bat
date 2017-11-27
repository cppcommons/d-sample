edub qiitalib.lib build arch=dm32 ^
qiitalib.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
[vibe-d] [dateparser]
if %errorlevel% neq 0 (exit /b)
edub qiitadb.lib build arch=dm32 ^
qiitadb.d ^
"[d2sqlite3#  #without-lib]" "[my-hibernated#@hibernated-0.3.2]"
if %errorlevel% neq 0 (exit /b)
