chcp 65001

edub step1.exe run arch=dm32 step1.d ^
characterencodings.d@https://github.com/adamdruppe/arsd/blob/master/characterencodings.d ^
https://github.com/adamdruppe/arsd/blob/master/dom.d ^
qiitadb.lib qiitalib.lib sqlite-win-32bit-3200100-dm32.lib ^
[vibe-d:data] [dateparser] [my-hibernated#@hibernated-0.3.2] [d2sqlite3##without-lib]
if %errorlevel% neq 0 (exit /b)
