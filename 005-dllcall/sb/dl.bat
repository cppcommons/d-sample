:: https://apr.apache.org/compiling_win32.html
setlocal
set SCRIPT=%~0
for /f "delims=\ tokens=*" %%z in ("%SCRIPT%") do (set SCRIPT_CURRENT_DIR=%%~dpz)

set PATH=E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin;%PATH%

cd /d %SCRIPT_CURRENT_DIR%
if not exist src/apr       svn export https://svn.apache.org/repos/asf/apr/apr/tags/1.6.2 src/apr
::if not exist src/apr       svn export https://svn.apache.org/repos/asf/apr/apr/tags/1.6.3 src/apr
if not exist src/apr-util (
rem	wget -nc --no-check-certificate http://www.apache.org/dist/apr/apr-util-1.6.1-win32-src.zip
rem	wget -nc --no-check-certificate https://archive.apache.org/dist/apr/apr-util-1.6.0-win32-src.zip
rem	wget -nc --no-check-certificate https://archive.apache.org/dist/apr/apr-util-1.5.4-win32-src.zip
	wget -nc --no-check-certificate https://archive.apache.org/dist/apr/apr-util-1.4.1-win32-src.zip
	7z x -osrc apr-util-1.4.1-win32-src.zip
	mv src/apr-util-1.4.1 src/apr-util
rem	svn export https://svn.apache.org/repos/asf/apr/apr-util/tags/1.6.0 src/apr-util
rem	svn export https://svn.apache.org/repos/asf/apr/apr-util/tags/1.6.1 src/apr-util
rem	svn patch apr-util.patch src\apr-util
)
if not exist src/apr-iconv svn export https://svn.apache.org/repos/asf/apr/apr-iconv/tags/1.2.1 src/apr-iconv
::if not exist src/apr-iconv svn export https://svn.apache.org/repos/asf/apr/apr-iconv/tags/1.2.2 src/apr-iconv
if not exist src/svn svn export https://svn.apache.org/repos/asf/subversion/tags/1.8.18 src/svn
wget -nc --no-check-certificate http://download.oracle.com/berkeley-db/db-4.8.30.zip
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
if not exist src/svn/sqlite-amalgamation (
  7z x -y -osrc sqlite-amalgamation-3190300.zip
  cp -rp src/sqlite-amalgamation-3190300 src/svn/sqlite-amalgamation
)
cd /d %SCRIPT_CURRENT_DIR%\src\apr
sed -i -e "s/^#define APR_HAVE_IPV6\([[:blank:]]*\) 1$/#define APR_HAVE_IPV6\1 0/" include/apr.hw
cl /MD tools\gen_test_char.c /link /OUT:tools\gen_test_char.exe
::tools\gen_test_char.exe > include\private\apr_escape_test_char.h
tools\gen_test_char.exe > include\apr_escape_test_char.h
::exit /b
msdev.com apr.dsp /MAKE "apr - Win32 Release" /BUILD
cd /d %SCRIPT_CURRENT_DIR%\src\apr-iconv
msdev.com apriconv.dsp /MAKE "apriconv - Win32 Release" /BUILD
::exit /b
cd /d %SCRIPT_CURRENT_DIR%\src\apr-util
rm -rf 0
touch 0
cp 0 ldap\apr_ldap_init.c
cp 0 ldap\apr_ldap_option.c
cp 0 ldap\apr_ldap_rebind.c
cp 0 ldap\apr_ldap_stub.c
cp 0 ldap\apr_ldap_url.c
cp 0 dbd\apr_dbd_odbc.c
msdev aprutil.dsw /MAKE "aprutil - Win32 Release"
cd /d %SCRIPT_CURRENT_DIR%
wget -nc http://subversion.tigris.org/files/documents/15/20739/svn-win32-libintl.zip
if not exist src/svn-win32-libintl 7z x -osrc svn-win32-libintl.zip
