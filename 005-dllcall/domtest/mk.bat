chcp 65001

edub domtest.exe run ^
app.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
../lib_entry.lib ^
[jsonizer] [dateparser] ^
-- 2017-11
echo errorlevel=%errorlevel%
if %errorlevel% neq 0 (exit /b)

edub control.exe run ^
def=TEST1 ^
control.d ^
[jsonizer] [dateparser]
if %errorlevel% neq 0 (exit /b)
