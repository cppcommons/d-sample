edub os2.dll build os2_impl.d
pexports os2.dll > os2.def
setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\VC98\Bin\VCVARS32.BAT"
@echo on
lib /DEF:os2.def /MACHINE:X86 /OUT:os2-vc6.lib
endlocal
