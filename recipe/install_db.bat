meson install --no-rebuild -C build
:: lz4-c conda package ships liblz4.dll but postgres links against lz4.dll
if not exist %LIBRARY_BIN%\lz4.dll copy %LIBRARY_BIN%\liblz4.dll %LIBRARY_BIN%\lz4.dll
