@echo off
setlocal enabledelayedexpansion

cd rest

set LIB_EXT=dll
set REST_EXT_DIR=%PREFIX%\Library\bin
set LIBCLANG_PATH=%BUILD_PREFIX%\Library\bin

mkdir "%REST_EXT_DIR%"

set MOKIT_LIB=%BUILD_PREFIX%\Lib\site-packages\mokit\lib\librest2fch.dll

if not exist "%MOKIT_LIB%" (
  echo Could not find mokit bridge library: %MOKIT_LIB% 1>&2
  exit /b 1
)

copy "%MOKIT_LIB%" "%REST_EXT_DIR%\"

set LIBCLANG_PATH=%LIBCLANG_PATH%
set REST_EXT_DIR=%REST_EXT_DIR%

cargo install --path . --profile release --root %PREFIX%

mkdir %PREFIX%\share\rest\
xcopy /E /I /Y .\basis-set-pool %PREFIX%\share\rest\
