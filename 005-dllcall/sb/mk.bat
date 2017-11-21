setlocal
set SCRIPT=%~0
for /f "delims=\ tokens=*" %%z in ("%SCRIPT%") do (set SCRIPT_CURRENT_DIR=%%~dpz)
cd /d %SCRIPT_CURRENT_DIR%
cd /d %SCRIPT_CURRENT_DIR%\src\svn
python gen-make.py -t dsp --with-berkeley-db=..\db-4.8.30 --with-openssl=..\openssl-1.0.2l --with-zlib=..\zlib-1.2.11 --enable-nls --enable-bdb-in-apr-util --with-apr=..\apr --with-apr-util=..\apr-util
cd /d %SCRIPT_CURRENT_DIR%
endlocal
