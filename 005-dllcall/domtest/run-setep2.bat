chcp 65001

edub step2-ms64.exe run arch=ms64 step2.d [vibe-d] [dateparser]
if %errorlevel% neq 0 (exit /b)
