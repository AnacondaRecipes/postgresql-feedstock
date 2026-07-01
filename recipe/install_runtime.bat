meson install --no-rebuild -C build

mkdir backup
MOVE %LIBRARY_BIN%\libpq.dll backup
MOVE %LIBRARY_BIN%\pg_config.exe backup
RD /s /q %LIBRARY_BIN%
mkdir %LIBRARY_BIN%
MOVE backup\* %LIBRARY_BIN%

REM Meson installs server/contrib modules into Library\lib.  Those modules
REM belong to the postgresql output, not libpq, and pull in server-only DSOs.
IF EXIST "%LIBRARY_LIB%\*.dll" DEL /Q "%LIBRARY_LIB%\*.dll"
