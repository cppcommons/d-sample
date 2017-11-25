chcp 65001

edub stocs-ms64.exe run arch=ms64 ^
stocks.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
qiitadb-ms64.lib qiitalib-ms64.lib sqlite-win-64bit-3210000-ms64.lib ^
[vibe-d] [dateparser] "[d2sqlite3:  :without-lib]"
if %errorlevel% neq 0 (exit /b)
