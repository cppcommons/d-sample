premake --file vc6.pmk --target vs6
::"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" vc6-pkg.dsp /MAKE ALL /REBUILD
"C:\Program Files (x86)\Microsoft Visual Studio\Common\MSDev98\Bin\msdev.com" vc6-run.dsp /MAKE ALL /BUILD
::premake --file vc6.pmk --clean
vc6-run.exe