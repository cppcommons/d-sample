premake --file memory.pmk --target vs6
if %errorlevel% neq 0 ( exit /b )
"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" memory-run.dsp /MAKE ALL /REBUILD
if %errorlevel% neq 0 ( exit /b )
memory-run.exe
c:\dm\bin\dmc -omemory-run-dm32.exe -IC:\dm\stlport\stlport memory.cpp
memory-run-dm32.exe
