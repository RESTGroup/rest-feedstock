set -ex
cd rest

if [[ "$target_platform" == osx-* ]]; then
  LIB_EXT="dylib"
else
  LIB_EXT="so"
fi

REST_EXT_DIR="${PREFIX}/lib"
LIBCLANG_PATH="${BUILD_PREFIX}/lib"

mkdir -p "${REST_EXT_DIR}"

MOKIT_LIB="${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/mokit/lib/librest2fch.${LIB_EXT}"
if [[ ! -f "${MOKIT_LIB}" ]]; then
  echo "Could not find mokit bridge library: ${MOKIT_LIB}" >&2
  exit 1
fi
cp "${MOKIT_LIB}" "${REST_EXT_DIR}/"

export LIBCLANG_PATH
export REST_EXT_DIR
cargo install --path . --profile release --root ${PREFIX}
mkdir -p ${PREFIX}/share/rest/
cp -r ./basis-set-pool ${PREFIX}/share/rest/
