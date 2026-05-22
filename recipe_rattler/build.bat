@echo on
setlocal enabledelayedexpansion

echo === Working directory ===
cd

echo === Contents of SRC_DIR ===
dir "%SRC_DIR%"

echo === Changing to rest directory ===
cd /d rest || exit /b 1

echo === Current directory ===
cd

echo === Contents of rest directory before checkout ===
dir

if not exist "Cargo.toml" (
  echo === Cargo.toml not found, checking out working tree ===
  git status
  git checkout HEAD -- .
  if errorlevel 1 (
    echo Git checkout failed
    exit /b 1
  )
  echo === Contents of rest directory after checkout ===
  dir
) else (
  echo === Cargo.toml already exists ===
)

if not exist "Cargo.toml" (
  echo Cargo.toml still not found after checkout
  exit /b 1
)

set LIB_EXT=dll
set REST_EXT_DIR=%PREFIX%\Library\bin
set LIBCLANG_PATH=%BUILD_PREFIX%\Library\bin

echo === Creating REST_EXT_DIR ===
if not exist "%REST_EXT_DIR%" (
  mkdir "%REST_EXT_DIR%"
) else (
  echo REST_EXT_DIR already exists: %REST_EXT_DIR%
)

set MOKIT_LIB=%BUILD_PREFIX%\Lib\site-packages\mokit\lib\librest2fch.dll

echo === Checking mokit library ===
if not exist "%MOKIT_LIB%" (
  echo Could not find mokit bridge library: %MOKIT_LIB% 1>&2
  exit /b 1
)
echo Found mokit library: %MOKIT_LIB%

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
  echo Copying from .\basis-set-pool
  xcopy /E /I /Y /Q .\basis-set-pool %PREFIX%\share\rest\
) else (
  echo Warning: basis-set-pool not found
)
