export REST_HOME="${SRC_DIR}"
export REST_EXT_DIR="${PREFIX}/lib"
set -eux
cd rest
cargo test
cd ..
cd rest_regression
# cargo install --path . --profile release --root .
which rest
echo ${REST_EXT_DIR}
echo ${REST_HOME}
echo ${PREFIX}
${PREFIX}/bin/rest_regression -r ./bench_pool -p ${PREFIX}/bin/rest
# cat ./work_pool/HI_RHF_GRAD.log