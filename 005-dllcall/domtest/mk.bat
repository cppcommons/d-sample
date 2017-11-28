chcp 65001

edub app.lib test arch=dm32 inc=. app.d [botan]
if %errorlevel% neq 0 (exit /b)
edub app.lib build arch=dm32 inc=. app.d [botan]
