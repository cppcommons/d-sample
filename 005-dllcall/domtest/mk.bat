chcp 65001

edub app.lib test app.d inc=.
if %errorlevel% neq 0 (exit /b)
