chcp 65001

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

edub qiita.exe run ^
qiita.d ^
[jsonizer] [dateparser]
if %errorlevel% neq 0 (exit /b)
