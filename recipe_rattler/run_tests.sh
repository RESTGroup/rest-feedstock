export REST_HOME="${SRC_DIR}"
export REST_EXT_DIR="${PREFIX}/lib"
set -eux
cd rest_regression
# cargo install --path . --profile release --root .
which rest
echo ${REST_EXT_DIR}
echo ${REST_HOME}
echo ${PREFIX}
# catch the error if rest_regression fail and print the log file
${PREFIX}/bin/rest_regression -r ./bench_pool -p ${PREFIX}/bin/rest || cat ./work_pool/HI_RHF_GRAD.log