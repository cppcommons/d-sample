chcp 65001

edub step3.exe run arch=dm32 step3.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
sqlite-win-32bit-3200100-dm32.lib ^
[vibe-d:data] [dateparser] [d2sqlite3##without-lib] [my-dmdscript#@./DMDScript-master]
if %errorlevel% neq 0 (exit /b)
