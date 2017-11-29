chcp 65001

edub app-dm32.exe run arch=dm32 inc=. app.d ^
[my_common-lib#@E:\d-dev\d-sample\common\my_common.lib.bin] ^
[vibe-d:data]
if %errorlevel% neq 0 (exit /b)
::edub app.lib build arch=dm32 inc=. app.d [botan]
