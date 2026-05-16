export REST_HOME="${SRC_DIR}"
if [[ "${target_platform}" == win-* ]]; then
  export REST_EXT_DIR="${PREFIX}/Library/bin"
else
  export REST_EXT_DIR="${PREFIX}/lib"
fi
set -eux
cd rest_regression
# cargo install --path . --profile release --root .
REST_BIN="${PREFIX}/bin/rest"
REST_REG_BIN="${PREFIX}/bin/rest_regression"
if [[ "${target_platform}" == win-* ]]; then
  if [[ -x "${PREFIX}/bin/rest.exe" ]]; then
    REST_BIN="${PREFIX}/bin/rest.exe"
  elif [[ -x "${PREFIX}/Library/bin/rest.exe" ]]; then
    REST_BIN="${PREFIX}/Library/bin/rest.exe"
  fi
  if [[ -x "${PREFIX}/bin/rest_regression.exe" ]]; then
    REST_REG_BIN="${PREFIX}/bin/rest_regression.exe"
  elif [[ -x "${PREFIX}/Library/bin/rest_regression.exe" ]]; then
    REST_REG_BIN="${PREFIX}/Library/bin/rest_regression.exe"
  fi
fi
which "${REST_BIN}"
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
