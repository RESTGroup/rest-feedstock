set -ex
cd rest
# mkdir -p ${REST_DEPS}
# mkdir -p ${REST_DEPS}/lib
if [[ "$target_platform" == win-* ]]; then
  LIB_EXT="dll"
  REST_EXT_DIR="${PREFIX}/Library/bin"
  LIBCLANG_PATH="${BUILD_PREFIX}/Library/bin"
elif [[ "$target_platform" == osx-* ]]; then
  LIB_EXT="dylib"
  REST_EXT_DIR="${PREFIX}/lib"
  LIBCLANG_PATH="${BUILD_PREFIX}/lib"
else
  LIB_EXT="so"
  REST_EXT_DIR="${PREFIX}/lib"
  LIBCLANG_PATH="${BUILD_PREFIX}/lib"
fi

mkdir -p "${REST_EXT_DIR}"
# cp ${BUILD_PREFIX}/lib/*.${LIB_EXT} ${REST_EXT_DIR}/
MOKIT_LIB=""
# Some win-64 mokit builds install this library without the "lib" prefix.
MOKIT_CANDIDATES=(
  "${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/mokit/lib/librest2fch.${LIB_EXT}"
  "${BUILD_PREFIX}/Lib/site-packages/mokit/lib/librest2fch.${LIB_EXT}"
  "${BUILD_PREFIX}/Lib/site-packages/mokit/lib/rest2fch.${LIB_EXT}"
)
for CANDIDATE in "${MOKIT_CANDIDATES[@]}"; do
  if [[ -f "${CANDIDATE}" ]]; then
    MOKIT_LIB="${CANDIDATE}"
    break
  fi
done
if [[ -z "${MOKIT_LIB}" ]]; then
  echo "Could not find mokit bridge library after checking:" >&2
  printf '  - %s\n' "${MOKIT_CANDIDATES[@]}" >&2
  exit 1
fi
cp "${MOKIT_LIB}" "${REST_EXT_DIR}/"
export LIBCLANG_PATH
export REST_EXT_DIR
cargo install --path . --profile release --root ${PREFIX}
mkdir -p ${PREFIX}/share/rest/
cp -r ./basis-set-pool ${PREFIX}/share/rest/
# cp ${REST_EXT_DIR}/librestmatr.${LIB_EXT} ${PREFIX}/lib/
# if [[ "$target_platform" == osx-* ]]; then
#   install_name_tool -id "@rpath/librestmatr.dylib" ${PREFIX}/lib/librestmatr.dylib
# fi
# cp ${REST_EXT_DIR}/librest2fch.${LIB_EXT} ${PREFIX}/lib/
# todo: remove the manual copy
