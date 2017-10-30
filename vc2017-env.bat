@if(0)==(0) echo off
setlocal enabledelayedexpansion
set VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat

set INCLUDE=
set LIB=
set LIBPATH=
set PATH=%SystemRoot%\System32;%SystemRoot%\System32\Wbem
call "%VCVARSALL%" x86
set INCLUDE32=%INCLUDE%
set LIB32=%LIB%
set LIBPATH32=%LIBPATH%
echo [INCLUDE32]
for %%A in ("%INCLUDE32:;=";"%") do (if not "%%~A"=="" echo %%~A)
echo [LIB32]
for %%A in ("%LIB32:;=";"%") do (if not "%%~A"=="" echo %%~A)
echo [LIBPATH32]
for %%A in ("%LIBPATH32:;=";"%") do (if not "%%~A"=="" echo %%~A)
echo [VCPATH32]
set VCPATH32=
for %%A in ("%PATH:;=";"%") do (
  if /i "%%~A" neq "%SystemRoot%\System32" (
    if /i "%%~A" neq "%SystemRoot%\System32\Wbem" (
      echo %%~A
      if "!VCPATH32!" equ "" (set VCPATH32=%%~A) else (set VCPATH32=!VCPATH32!;%%~A)
    )
  )
)
::echo %VCPATH32%

set INCLUDE=
set LIB=
set LIBPATH=
set PATH=%SystemRoot%\System32;%SystemRoot%\System32\Wbem
call "%VCVARSALL%" amd64
set INCLUDE64=%INCLUDE%
set LIB64=%LIB%
set LIBPATH64=%LIBPATH%
echo [INCLUDE64]
for %%A in ("%INCLUDE64:;=";"%") do (if not "%%~A"=="" echo %%~A)
echo [LIB64]
for %%A in ("%LIB64:;=";"%") do (if not "%%~A"=="" echo %%~A)
echo [LIBPATH64]
for %%A in ("%LIBPATH64:;=";"%") do (if not "%%~A"=="" echo %%~A)
echo [VCPATH64]
set VCPATH64=
for %%A in ("%PATH:;=";"%") do (
  if /i "%%~A" neq "%SystemRoot%\System32" (
    if /i "%%~A" neq "%SystemRoot%\System32\Wbem" (
      echo %%~A
      if "!VCPATH64!" equ "" (set VCPATH64=%%~A) else (set VCPATH64=!VCPATH64!;%%~A)
    )
  )
)
::echo %VCPATH64%

set INCLUDE=
set LIB=
set LIBPATH=
set PATH=%SystemRoot%\System32;%SystemRoot%\System32\Wbem
cscript.exe //nologo //E:JScript "%~f0"
endlocal
exit /b
goto :EOF
@end

if (!Array.prototype.contains) {
  Array.prototype.contains = function(x) {
    for (var i=0; i<this.length; i++) {
      if (this[i]==x) return true;
    }
    return false;
  };
}

if (!Array.prototype.remove) {
  Array.prototype.remove = function(x) {
    var result = [];
    for (var i=0; i<this.length; i++) {
      if (this[i]==x) continue;
      result.push(this[i]);
    }
    return result;
  };
}

if (!Array.prototype.removeAll) {
  Array.prototype.removeAll = function(a) {
    var result = [];
    for (var i=0; i<this.length; i++) {
      if (a.contains(this[i])) continue;
      result.push(this[i]);
    }
    return result;
  };
}

var opts = {};
opts.penv         = new ActiveXObject("WScript.Shell").Environment("PROCESS");
opts.uenv         = new ActiveXObject("WScript.Shell").Environment("USER");
opts.include32    = opts.penv.item("INCLUDE32").split(";").remove("");
opts.include64    = opts.penv.item("INCLUDE64").split(";").remove("");
opts.lib32        = opts.penv.item("LIB32").split(";").remove("");
opts.lib64        = opts.penv.item("LIB64").split(";").remove("");
opts.libpath32    = opts.penv.item("LIBPATH32").split(";").remove("");
opts.libpath64    = opts.penv.item("LIBPATH64").split(";").remove("");
opts.path32       = opts.penv.item("VCPATH32").split(";").remove("");
opts.path64       = opts.penv.item("VCPATH64").split(";").remove("");

var selectOk = false;
var num;
while(!selectOk) {
  WScript.StdOut.WriteLine("Šó–]‚·‚é‘€ì‚ð”Žš‚Å‘I‘ð‚µ‚Ä‚­‚¾‚³‚¢ Ë 0=ŠÂ‹«•Ï”‚ðÁ‹Ž  32=32bitŠÂ‹«‚ðÝ’è  64=64bitŠÂ‹«‚ðÝ’è  ‹ó•¶Žš=‰½‚à‚µ‚È‚¢");
  WScript.StdOut.Write("”Žš(0 or 32 or 64)‚ð“ü—Í: ");
  var line = WScript.StdIn.ReadLine();
  num = line.replace(/(^\s+)|(\s+$)/g, ""); // ƒgƒŠƒ€
  switch(num) {
    case '0': case '32': case '64': case '':
      selectOk = true;
      break;
  }
}
switch(num) {
  case '0':
    clearEnv(opts);
    msgbox("ŠÂ‹«•Ï”‚ðÁ‹Ž‚µ‚Ü‚µ‚½");
    break;
  case '32':
    clearEnv(opts);
    put32Env(opts);
    msgbox("32bitŠÂ‹«‚ðÝ’è‚µ‚Ü‚µ‚½");
    break;
  case '64':
    clearEnv(opts);
    put64Env(opts);
    msgbox("64bitŠÂ‹«‚ðÝ’è‚µ‚Ü‚µ‚½");
    break;
  default:
    msgbox("‰½‚à‚µ‚Ü‚¹‚ñ‚Å‚µ‚½");
    break;
}
WScript.Quit();
function msgbox(msg) {
  var shell = new ActiveXObject("WScript.Shell");
  shell.Popup(msg, 0, "Windows Script Host", 0);
}
function initEnv(opts) {
  opts.include = opts.uenv.item("INCLUDE").split(";").remove("");
  opts.lib     = opts.uenv.item("LIB").split(";").remove("");
  opts.libpath = opts.uenv.item("LIBPATH").split(";").remove("");
  opts.path    = opts.uenv.item("PATH").split(";").remove("");
}
function clearEnv(opts) {
  initEnv(opts);
  opts.uenv.item("INCLUDE") = opts.include.removeAll(opts.include32).removeAll(opts.include64).join(";");
  if (opts.uenv.item("INCLUDE") == "") opts.uenv.remove("INCLUDE");
  opts.uenv.item("LIB") = opts.lib.removeAll(opts.lib32).removeAll(opts.lib64).join(";");
  if (opts.uenv.item("LIB") == "") opts.uenv.remove("LIB");
  opts.uenv.item("LIBPATH") = opts.libpath.removeAll(opts.libpath32).removeAll(opts.libpath64).join(";");
  if (opts.uenv.item("LIBPATH") == "") opts.uenv.remove("LIBPATH");
  opts.uenv.item("PATH") = opts.path.removeAll(opts.path32).removeAll(opts.path64).join(";");
  if (opts.uenv.item("PATH") == "") opts.uenv.remove("PATH");
}
function put32Env(opts) {
  initEnv(opts);
  opts.uenv.item("INCLUDE") = opts.include.concat(opts.include32).join(";");
  opts.uenv.item("LIB") = opts.lib.concat(opts.lib32).join(";");
  opts.uenv.item("LIBPATH") = opts.libpath.concat(opts.libpath32).join(";");
  opts.uenv.item("PATH") = opts.path.concat(opts.path32).join(";");
}
function put64Env(opts) {
  initEnv(opts);
  opts.uenv.item("INCLUDE") = opts.include.concat(opts.include64).join(";");
  opts.uenv.item("LIB") = opts.lib.concat(opts.lib64).join(";");
  opts.uenv.item("LIBPATH") = opts.libpath.concat(opts.libpath64).join(";");
  opts.uenv.item("PATH") = opts.path.concat(opts.path64).join(";");
}

