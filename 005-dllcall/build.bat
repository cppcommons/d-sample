qmake.exe dlltest.pro -spec win32-g++ "CONFIG+=release"
mingw32-make -f Makefile.Release
del main.exe
C:\D\dm\bin\dmc main.cpp lib_entry.cpp ^
  my_library_0_data.c ^
  my_library_1_data.c ^
  my_library_2_data.c ^
  my_library_3_data.c ^
  my_library_4_data.c ^
  my_library_5_data.c ^
  my_library_6_data.c
del lib_entry.lib
C:\D\dm\bin\lib -c -p32 lib_entry.lib lib_entry.obj ^
  my_library_0_data.obj ^
  my_library_1_data.obj ^
  my_library_2_data.obj ^
  my_library_3_data.obj ^
  my_library_4_data.obj ^
  my_library_5_data.obj ^
  my_library_6_data.obj ^
  my_library_7_data.obj
main.exe
