@echo off
setlocal enabledelayedexpansion

echo === Creating workspace Cargo.toml ===
(
echo [workspace]
echo resolver = "2"
echo.
echo members = [
echo     "rest_tensors",
echo     "rest_libcint",
echo     "rest",
echo     "rest_regression",
echo ]
echo.
echo [profile.release]
echo opt-level = 3
echo lto = "fat"
echo codegen-units = 1
) > "%SRC_DIR%\Cargo.toml"

echo === Changing to rest directory ===
cd /d rest || exit /b 1

set LIB_EXT=dll
set REST_EXT_DIR=%PREFIX%\Library\bin
set LIBCLANG_PATH=%BUILD_PREFIX%\Library\bin

echo === Creating REST_EXT_DIR ===
if not exist "%REST_EXT_DIR%" (
  mkdir "%REST_EXT_DIR%"
)

set MOKIT_LIB=%BUILD_PREFIX%\Lib\site-packages\mokit\lib\librest2fch.dll

echo === Checking mokit library ===
if not exist "%MOKIT_LIB%" (
  echo Could not find mokit bridge library: %MOKIT_LIB% 1>&2
  exit /b 1
)

copy "%MOKIT_LIB%" "%REST_EXT_DIR%\"

set LIBCLANG_PATH=%LIBCLANG_PATH%
set REST_EXT_DIR=%REST_EXT_DIR%

echo === Running cargo install ===
cargo install --path . --profile release --root %PREFIX%

echo === Copying basis-set-pool ===
if not exist %PREFIX%\share\rest\ (
  mkdir %PREFIX%\share\rest\
)

if exist .\basis-set-pool (
  xcopy /E /I /Y /Q .\basis-set-pool %PREFIX%\share\rest\
) else (
  echo Warning: basis-set-pool not found
)
