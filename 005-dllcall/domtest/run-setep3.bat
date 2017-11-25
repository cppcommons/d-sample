chcp 65001

edub step3.exe run arch=dm32 step3.d ^
sqlite-win-32bit-3200100-dm32.lib qiitalib.lib qiitadb.lib ^
[vibe-d] [dateparser] "[d2sqlite3::without-lib]"
if %errorlevel% neq 0 (exit /b)
