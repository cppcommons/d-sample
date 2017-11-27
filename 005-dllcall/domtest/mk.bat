chcp 65001

goto skip
edub domtest.exe build ^
app.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
../lib_entry.lib ^
[jsonizer] [dateparser]
echo errorlevel=%errorlevel%
if %errorlevel% neq 0 (exit /b)

edub control.exe build ^
def=TEST1 ^
control.d ^
[jsonizer] [dateparser]
if %errorlevel% neq 0 (exit /b)

:skip

edub qiita.exe run ^
qiita.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
sqlite-win-32bit-3200100-dm32.lib ^
[vibe-d{:}data] [dateparser] "[d2sqlite3:  :without-lib]"
if %errorlevel% neq 0 (exit /b)
