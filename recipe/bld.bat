@echo on

pushd src\tools\msvc

echo $config-^>{openssl} = '%LIBRARY_PREFIX%'; >> config.pl
echo $config-^>{zlib} = '%LIBRARY_PREFIX%';    >> config.pl
echo $config-^>{gss} = '%LIBRARY_PREFIX%';     >> config.pl

REM xref: https://metacpan.org/pod/release/XSAWYERX/perl-5.26.0/pod/perldelta.pod#Removal-of-the-current-directory-%28%22.%22%29-from-@INC
set PERL_USE_UNSAFE_INC=1

:: Appveyor's postgres install is on PATH and interferes with testing
IF NOT "%APPVEYOR%" == "" (
    ECHO Deleting AppVeyor's PostgreSQL installs
    RD /S /Q "C:\Program Files\PostgreSQL"
)

if "%PY_VER%" == "2.7" goto :msbuildpath
if "%PY_VER%" == "3.4" goto :msbuildpath
goto :havemsbuild

:msbuildpath
  :: Need to move a more current msbuild into PATH.  32-bit one in particular on AppVeyor barfs on the solution that
  ::    Postgres writes here.  This one comes from the Win7 SDK (.net 4.0), and is known to work.
  set "PATH=%CD%;C:\Windows\Microsoft.NET\Framework\v4.0.30319;%PATH%"

:havemsbuild


if "%ARCH%" == "32" (
   set ARCH=Win32
) else (
   set ARCH=x64
)

:: lz4-c ships lz4.lib referencing lz4.dll, but only liblz4.dll is packaged.
:: If liblz4.lib exists (references liblz4.dll), patch liblz4.pc so meson
:: links against liblz4.lib and the binary loads liblz4.dll at runtime.
if exist %LIBRARY_LIB%\liblz4.lib (
    powershell -Command "(gc '%LIBRARY_LIB%\pkgconfig\liblz4.pc') -replace '-llz4\b', '-lliblz4' | sc '%LIBRARY_LIB%\pkgconfig\liblz4.pc'"
    if errorlevel 1 exit 1
)

meson setup ^
   --prefix=%LIBRARY_PREFIX% ^
   --backend ninja ^
   --buildtype=release ^
   -Dcassert=false ^
   -Dnls=disabled ^
   -Dplperl=disabled ^
   -Dpltcl=disabled ^
   -Dlz4=enabled ^
   -Dextra_include_dirs=%LIBRARY_INC% ^
   -Dextra_lib_dirs=%LIBRARY_LIB% ^
   -Dpkg_config_path=%LIBRARY_LIB%\pkgconfig ^
   build
if errorlevel 1 exit 1

ninja -C build -j %CPU_COUNT%
if errorlevel 1 exit 1

:: The main regression tests take too long for this purpose. Skipping them.
:: meson test --print-errorlogs --no-rebuild -C build --suite regress
:: if errorlevel 1 exit 1