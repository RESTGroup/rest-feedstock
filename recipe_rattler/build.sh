set -ex

cat > Cargo.toml << 'EOF'
[workspace]
resolver = "2"

members = [
    "rest_tensors",
    "rest_libcint",
    "rest",
    "rest_regression",
]

[profile.release]
opt-level = 3
lto = "fat"
codegen-units = 1
EOF

if [[ "$target_platform" == win-64 ]]; then
  LIB_EXT="dll"
  REST_EXT_DIR="${PREFIX}/Library/bin"
  HDF5_DIR="${PREFIX}"

  MOKIT_LIB="${PREFIX}/Lib/site-packages/mokit/lib/librest2fch.${LIB_EXT}"

  export CONDA_BUILD_WINSDK="${BUILD_PREFIX}/x86_64-w64-mingw32/sysroot"
  export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER="${CC}"
else
  if [[ "$target_platform" == osx-* ]]; then
    LIB_EXT="dylib"
  else
    LIB_EXT="so"
  fi

  REST_EXT_DIR="${PREFIX}/lib"
  HDF5_DIR="${BUILD_PREFIX}"
  MOKIT_LIB="${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/mokit/lib/librest2fch.${LIB_EXT}"
fi

cd rest
mkdir -p "${REST_EXT_DIR}"

if [[ ! -f "${MOKIT_LIB}" ]]; then
  echo "Could not find mokit bridge library: ${MOKIT_LIB}" >&2
  exit 1
fi
cp "${MOKIT_LIB}" "${REST_EXT_DIR}/"

export HDF5_DIR
export LIBCLANG_PATH="${BUILD_PREFIX}/lib"
export REST_EXT_DIR

if [[ "$target_platform" == win-64 ]]; then
  cargo install --path . --profile release --target x86_64-pc-windows-gnu --root ${PREFIX}
else
  cargo install --path . --profile release --root ${PREFIX}
fi

mkdir -p ${PREFIX}/share/rest/
cp -r ./basis-set-pool ${PREFIX}/share/rest/
