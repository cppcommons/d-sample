setlocal
set SCRIPT_CURRENT_DIR=%%~dpz
cd /d %SCRIPT_CURRENT_DIR%
::cd /d %SCRIPT_CURRENT_DIR%\src\svn
::python gen-make.py -t dsp --with-berkeley-db=..\src\db-4.8.30 --with-openssl=..\%HTTPDDIR%\srclib\openssl --with-zlib=..\%HTTPDDIR%\srclib\zlib --enable-nls --with-libintl=..\svn-win32-libintl --enable-bdb-in-apr-util
endlocal