@echo on
echo "BLD.BAT"
python -c "import pathlib; c=pathlib.Path('src/backend/libpq/be-secure-gssapi.c').read_bytes(); print('Source CRLF:', c.count(b'\r\n'), 'LF:', c.count(b'\n')-c.count(b'\r\n'))"

patch -p1 --binary --ignore-whitespace < %RECIPE_DIR%\patches/fix_gssapi_setenv_win.patch
patch -p1 --binary --ignore-whitespace < %RECIPE_DIR%\patches/fix_auth_setenv_win.patch
patch -p1 --binary --ignore-whitespace < %RECIPE_DIR%\patches/fix_x509_name_win.patch
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

meson setup ^
   --prefix=%LIBRARY_PREFIX% ^
   --backend ninja ^
   --buildtype=release ^
   -Dcassert=false ^
   -Dnls=disabled ^
   -Dplperl=disabled ^
   -Dpltcl=disabled ^
   -Dextra_include_dirs=%LIBRARY_INC% ^
   -Dextra_lib_dirs=%LIBRARY_LIB% ^
   build
if errorlevel 1 exit 1

ninja -C build -j %CPU_COUNT%
if errorlevel 1 exit 1

:: Run a minimal set of tests.
meson test --print-errorlogs --no-rebuild -C build --suite setup
if errorlevel 1 exit 1

:: The main regression tests take too long for this purpose. Skipping them.
:: meson test --print-errorlogs --no-rebuild -C build --suite regress
:: if errorlevel 1 exit 1