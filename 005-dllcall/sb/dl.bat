setlocal
set SCRIPT=%~0
for /f "delims=\ tokens=*" %%z in ("%SCRIPT%") do (set SCRIPT_CURRENT_DIR=%%~dpz)
cd /d %SCRIPT_CURRENT_DIR%
if not exist src/apr       svn co https://svn.apache.org/repos/asf/apr/apr/tags/1.6.2 src/apr
if not exist src/apr-util (
	svn co https://svn.apache.org/repos/asf/apr/apr-util/tags/1.6.0 src/apr-util
	svn patch apr-util.patch src\apr-util
)
if not exist src/apr-iconv svn co https://svn.apache.org/repos/asf/apr/apr-iconv/tags/1.2.1 src/apr-iconv
if not exist src/svn svn co https://svn.apache.org/repos/asf/subversion/tags/1.8.18 src/svn
wget -nc --no-check-certificate http://download.oracle.com/berkeley-db/db-4.8.30.zip
::if not exist src/db-4.8.30 unzip -d src db-4.8.30.zip -x src/db-4.8.30/docs* db-4.8.30/examples* db-4.8.30/test*
if not exist src/db-4.8.30 7z x -osrc -x!db-4.8.30/docs "-x!db-4.8.30/examples*" "-x!db-4.8.30/test*" db-4.8.30.zip
if not exist src/db-4.8.30/build_windows/Win32/Release/libdb48s.lib (
  cd /d %SCRIPT_CURRENT_DIR%\src\db-4.8.30\build_windows
  "C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" db_static.dsp /MAKE ALL /BUILD
)
cd /d %SCRIPT_CURRENT_DIR%
wget -nc --no-check-certificate http://www.openssl.org/source/openssl-1.0.2l.tar.gz
if not exist src/openssl-1.0.2l tar xvf openssl-1.0.2l.tar.gz -C src
if not exist src/openssl-1.0.2l/out32/libeay32.lib (
  cd /d %SCRIPT_CURRENT_DIR%\src\openssl-1.0.2l
  perl Configure no-asm no-shared VC-WIN32
  call ms\do_nt.bat
  nmake -f ms\nt.mak init lib
)
cd /d %SCRIPT_CURRENT_DIR%
wget -nc --no-check-certificate -O zlib-1.2.11.zip https://github.com/madler/zlib/archive/v1.2.11.zip
if not exist src/zlib-1.2.11 7z x -osrc zlib-1.2.11.zip
if not exist src/zlib-1.2.11/zlib.lib (
  cd /d %SCRIPT_CURRENT_DIR%\src\zlib-1.2.11
  nmake -f win32/Makefile.msc
)
wget -nc http://www.sqlite.org/2017/sqlite-amalgamation-3190300.zip
if not exist src/sqlite-amalgamation-3190300 7z x -osrc sqlite-amalgamation-3190300.zip
cp -rp src/sqlite-amalgamation-3190300 src/svn/sqlite-amalgamation
