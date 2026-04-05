export REST_HOME="${SRC_DIR}"
export REST_EXT_DIR="${PREFIX}/lib"
set -eux
cd rest_regression
# cargo install --path . --profile release --root .
which rest
echo ${REST_EXT_DIR}
echo ${REST_HOME}
echo ${PREFIX}
${PREFIX}/bin/rest_regression -r ./bench_pool -p ${PREFIX}/bin/rest
# catch the error if rest_regression fail and print the log file
# if ! ${PREFIX}/bin/rest_regression -r ./bench_pool -p ${PREFIX}/bin/rest; then
#     cd bench_pool/CO_HF_Dipole
#     rest
#     exit 1
# fi
