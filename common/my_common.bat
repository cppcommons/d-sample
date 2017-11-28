chcp 65001

edub my_common.lib test arch=dm32 inc=. my_common.d [botan]
if %errorlevel% neq 0 (exit /b)
edub my_common.lib build arch=dm32 inc=. my_common.d [botan]
