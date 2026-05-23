set -ex

if [[ "$target_platform" == win-64 ]]; then
  LIB_EXT="dll"
  REST_EXT_DIR="${PREFIX}/Library/bin"

#   mkdir -p "${SRC_DIR}/.cargo"
#   cat > "${SRC_DIR}/.cargo/config.toml" << EOF
# [build]
# target = "x86_64-pc-windows-gnu"

# [target.x86_64-pc-windows-gnu]
# linker = "x86_64-w64-mingw32-gcc"
# ar = "x86_64-w64-mingw32-ar"
# EOF

  MOKIT_LIB="${BUILD_PREFIX}/Lib/site-packages/mokit/lib/librest2fch.${LIB_EXT}"
else
  if [[ "$target_platform" == osx-* ]]; then
    LIB_EXT="dylib"
  else
    LIB_EXT="so"
  fi

  REST_EXT_DIR="${PREFIX}/lib"
  MOKIT_LIB="${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/mokit/lib/librest2fch.${LIB_EXT}"
fi

cd rest
mkdir -p "${REST_EXT_DIR}"

if [[ ! -f "${MOKIT_LIB}" ]]; then
  echo "Could not find mokit bridge library: ${MOKIT_LIB}" >&2
  exit 1
fi
cp "${MOKIT_LIB}" "${REST_EXT_DIR}/"

export LIBCLANG_PATH="${BUILD_PREFIX}/lib"
export REST_EXT_DIR

if [[ "$target_platform" == win-64 ]]; then
  cargo install --path . --profile release --target x86_64-pc-windows-gnu --root ${PREFIX}
else
  cargo install --path . --profile release --root ${PREFIX}
fi

mkdir -p ${PREFIX}/share/rest/
cp -r ./basis-set-pool ${PREFIX}/share/rest/
