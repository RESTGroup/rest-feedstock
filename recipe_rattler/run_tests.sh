export REST_HOME="${SRC_DIR}"
if [[ "${target_platform}" == win-* ]]; then
  export REST_EXT_DIR="${PREFIX}/Library/bin"
else
  export REST_EXT_DIR="${PREFIX}/lib"
fi
set -eux
cd rest_regression
# cargo install --path . --profile release --root .
resolve_bin() {
  local name="$1"
  local default_path="${PREFIX}/bin/${name}"
  if [[ "${target_platform}" == win-* ]]; then
    if [[ -x "${PREFIX}/bin/${name}.exe" ]]; then
      echo "${PREFIX}/bin/${name}.exe"
      return 0
    elif [[ -x "${PREFIX}/Library/bin/${name}.exe" ]]; then
      echo "${PREFIX}/Library/bin/${name}.exe"
      return 0
    fi
    echo "Could not find ${name}.exe under ${PREFIX}/bin or ${PREFIX}/Library/bin" >&2
    return 1
  fi
  echo "${default_path}"
}

REST_BIN="$(resolve_bin rest)"
REST_REG_BIN="$(resolve_bin rest_regression)"
test -x "${REST_BIN}"
test -x "${REST_REG_BIN}"
echo ${REST_EXT_DIR}
echo ${REST_HOME}
echo ${PREFIX}
"${REST_REG_BIN}" -r ./bench_pool -p "${REST_BIN}"
# catch the error if rest_regression fail and print the log file
# if ! ${PREFIX}/bin/rest_regression -r ./bench_pool -p ${PREFIX}/bin/rest; then
#     cd bench_pool/CO_HF_Dipole
#     rest
#     exit 1
# fi
