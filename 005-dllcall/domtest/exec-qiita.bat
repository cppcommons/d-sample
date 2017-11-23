chcp 65001

edub qiita.exe run ^
qiita.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
sqlite-win-32bit-3200100-dm32.lib ^
[vibe-d] [dateparser] "[d2sqlite3:  :without-lib]"
if %errorlevel% neq 0 (exit /b)
