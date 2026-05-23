@echo on
setlocal enabledelayedexpansion

echo === Working directory ===
cd

echo === Contents of SRC_DIR ===
dir "%SRC_DIR%"

echo.
echo === Checking rest directory ===
if exist "%SRC_DIR%\rest" (
  echo Directory exists: %SRC_DIR%\rest
  dir "%SRC_DIR%\rest"
  if exist "%SRC_DIR%\rest\.git" (
    echo .git directory exists
    dir "%SRC_DIR%\rest\.git"
  ) else (
    echo WARNING: No .git directory in rest
  )
  if exist "%SRC_DIR%\rest\.ok" (
    echo .ok file exists
  ) else (
    echo WARNING: No .ok file in rest
  )
  if exist "%SRC_DIR%\rest\Cargo.toml" (
    echo rest/Cargo.toml: FOUND
  ) else (
    echo rest/Cargo.toml: MISSING
  )
) else (
  echo ERROR: rest directory does not exist
)

echo.
echo === Checking rest_tensors directory ===
if exist "%SRC_DIR%\rest_tensors" (
  echo Directory exists: %SRC_DIR%\rest_tensors
  dir "%SRC_DIR%\rest_tensors"
  if exist "%SRC_DIR%\rest_tensors\.git" (
    echo .git directory exists
    dir "%SRC_DIR%\rest_tensors\.git"
  ) else (
    echo WARNING: No .git directory in rest_tensors
  )
  if exist "%SRC_DIR%\rest_tensors\.ok" (
    echo .ok file exists
  ) else (
    echo WARNING: No .ok file in rest_tensors
  )
  if exist "%SRC_DIR%\rest_tensors\Cargo.toml" (
    echo rest_tensors/Cargo.toml: FOUND
  ) else (
    echo rest_tensors/Cargo.toml: MISSING
  )
) else (
  echo ERROR: rest_tensors directory does not exist
)

echo.
echo === Checking rest_libcint directory ===
if exist "%SRC_DIR%\rest_libcint" (
  echo Directory exists: %SRC_DIR%\rest_libcint
  dir "%SRC_DIR%\rest_libcint"
  if exist "%SRC_DIR%\rest_libcint\.git" (
    echo .git directory exists
    dir "%SRC_DIR%\rest_libcint\.git"
  ) else (
    echo WARNING: No .git directory in rest_libcint
  )
  if exist "%SRC_DIR%\rest_libcint\.ok" (
    echo .ok file exists
  ) else (
    echo WARNING: No .ok file in rest_libcint
  )
) else (
  echo ERROR: rest_libcint directory does not exist
)

echo.
echo === Checking rest_regression directory ===
if exist "%SRC_DIR%\rest_regression" (
  echo Directory exists: %SRC_DIR%\rest_regression
  dir "%SRC_DIR%\rest_regression"
  if exist "%SRC_DIR%\rest_regression\.git" (
    echo .git directory exists
    dir "%SRC_DIR%\rest_regression\.git"
  ) else (
    echo WARNING: No .git directory in rest_regression
  )
  if exist "%SRC_DIR%\rest_regression\.ok" (
    echo .ok file exists
  ) else (
    echo WARNING: No .ok file in rest_regression
  )
  if exist "%SRC_DIR%\rest_regression\Cargo.toml" (
    echo rest_regression/Cargo.toml: FOUND
  ) else (
    echo rest_regression/Cargo.toml: MISSING
  )
) else (
  echo ERROR: rest_regression directory does not exist
)

echo.
echo === Starting build ===

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
set CARGO_BUILD_TARGET=x86_64-pc-windows-gnu

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
