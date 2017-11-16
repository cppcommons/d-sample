setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\VC98\Bin\VCVARS32.BAT"
@echo on
cl /MD minimal_client.c ^
 -IE:\opt\svn\vc6\svn-win32-1.8.17-ap24_dev\svn-win32-1.8.17\include ^
 -IE:\opt\svn\vc6\svn-win32-1.8.17-ap24_dev\svn-win32-1.8.17\include\apr ^
 -IE:\opt\svn\vc6\svn-win32-1.8.17-ap24_dev\svn-win32-1.8.17\include\apr-iconv ^
 -IE:\opt\svn\vc6\svn-win32-1.8.17-ap24_dev\svn-win32-1.8.17\include\apr-util ^
 /link /out:mini.exe ^
  /LIBPATH:E:\opt\svn\vc6\svn-win32-1.8.17-ap24_dev\svn-win32-1.8.17\lib ^
  /LIBPATH:E:\opt\svn\vc6\svn-win32-1.8.17-ap24_dev\svn-win32-1.8.17\lib/apr ^
  /LIBPATH:E:\opt\svn\vc6\svn-win32-1.8.17-ap24_dev\svn-win32-1.8.17\lib/apr-iconv ^
  /LIBPATH:E:\opt\svn\vc6\svn-win32-1.8.17-ap24_dev\svn-win32-1.8.17\lib/apr-util ^
  /LIBPATH:E:\opt\svn\vc6\svn-win32-1.8.17-ap24_dev\svn-win32-1.8.17\lib/sasl ^
  /LIBPATH:E:\opt\svn\vc6\svn-win32-1.8.17-ap24_dev\svn-win32-1.8.17\lib/serf ^
		"libapr-1.lib" ^
		"libapriconv-1.lib" ^
		"libaprutil-1.lib" ^
		"xml.lib" ^
		"libsvn_client-1.lib" ^
		"libsvn_delta-1.lib" ^
		"libsvn_diff-1.lib" ^
		"libsvn_fs-1.lib" ^
		"libsvn_fs_base-1.lib" ^
		"libsvn_fs_fs-1.lib" ^
		"libsvn_fs_util-1.lib" ^
		"libsvn_ra-1.lib" ^
		"libsvn_ra_local-1.lib" ^
		"libsvn_ra_serf-1.lib" ^
		"libsvn_ra_svn-1.lib" ^
		"libsvn_repos-1.lib" ^
		"libsvn_subr-1.lib" ^
		"libsvn_wc-1.lib" ^
		"libsasl.lib" ^
		"serf-1.lib" ^
		"svn_client-1.lib" ^
		"svn_delta-1.lib" ^
		"svn_diff-1.lib" ^
		"svn_fs-1.lib" ^
		"svn_ra-1.lib" ^
		"svn_repos-1.lib" ^
		"svn_subr-1.lib" ^
		"svn_wc-1.lib"
endlocal
copy mini.exe E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin
E:\opt\svn\vc6\svn-win32-1.8.17-ap24\svn-win32-1.8.17\bin\mini.exe https://github.com/cppcommons/d-sample/trunk
