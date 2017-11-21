setlocal
set SCRIPT=%~0
for /f "delims=\ tokens=*" %%z in ("%SCRIPT%") do (set SCRIPT_CURRENT_DIR=%%~dpz)
cd /d %SCRIPT_CURRENT_DIR%
cd /d %SCRIPT_CURRENT_DIR%\src\svn
python gen-make.py -t dsp --with-libintl=..\svn-win32-libintl --with-berkeley-db=..\db-4.8.30 --with-openssl=..\openssl-1.0.2l --with-zlib=..\zlib-1.2.11 --enable-nls --enable-bdb-in-apr-util --with-apr=..\apr --with-apr-util=..\apr-util --disable-shared
::"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" subversion_msvc.dsw /USEENV /MAKE "__ALL_TESTS__ - Win32 Release"
::unix2dos *.dsw
::cd /d %SCRIPT_CURRENT_DIR%\src\svn\build\win32\msvc-dsp
::unix2dos *.dsp
cd /d %SCRIPT_CURRENT_DIR%\src\svn
"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" subversion_msvc.dsw /USEENV /MAKE "__ALL__ - Win32 Release"
::cd /d %SCRIPT_CURRENT_DIR%\src\svn\build\win32\msvc-dsp
::msdev.com libsvn_client_msvc.dsp /MAKE ALL /BUILD
cd /d %SCRIPT_CURRENT_DIR%
endlocal
