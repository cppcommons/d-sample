chcp 65001

edub vibeapp.exe run ^
vibeapp.d ^
sqlite-win-32bit-3200100-dm32.lib ^
[vibe-d] [dateparser] ^
"[d2sqlite3:  :without-lib]"
if %errorlevel% neq 0 (exit /b)
