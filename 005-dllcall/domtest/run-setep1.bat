chcp 65001

edub step1-ms64.exe run arch=ms64 step1.d ^
sqlite-win-64bit-3210000-ms64.lib ^
[vibe-d] [dateparser] "[d2sqlite3::without-lib]"
if %errorlevel% neq 0 (exit /b)
