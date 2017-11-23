chcp 65001

edub step3-ms64.exe run arch=ms64 step3.d qiitalib-ms64.lib [vibe-d] [dateparser]
if %errorlevel% neq 0 (exit /b)
