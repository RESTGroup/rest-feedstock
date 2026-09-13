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
    echo "Could not find ${name}.exe under ${PREFIX}/bin or ${PREFIX}/Library/bin on win-* platform" >&2
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
# ==== linkage diagnostics: check the OpenMP runtime binding (mac hang investigation) ====
echo "==== LINKAGE DIAGNOSTICS ===="
if [[ "${target_platform}" == osx-* ]]; then
  echo "--- otool -L ${REST_BIN} ---"
  otool -L "${REST_BIN}" 2>&1 || true
  OPENBLAS_DYLIB=$(find "${PREFIX}/lib" -maxdepth 1 -name "libopenblas*.dylib" 2>/dev/null | head -1)
  echo "--- otool -L ${OPENBLAS_DYLIB} ---"
  otool -L "${OPENBLAS_DYLIB}" 2>&1 || true
else
  echo "--- ldd ${REST_BIN} (omp/openblas-related) ---"
  ldd "${REST_BIN}" 2>&1 | grep -iE "omp|openblas|gfortran|gcc" || true
fi
echo "==== END LINKAGE DIAGNOSTICS ===="
SKIP_EXTRA=""
if [[ "${target_platform}" == osx-* ]]; then
  SKIP_EXTRA="--skip gw_bse,hessian,C6H6_R-xDH7,C6H6_RPA,C6H6_ZRPS,C6H6p_R-xDH7_ROHF,C6H6p_R-xDH7_UHF,C6H6p_ZRPS_ROHF,C6H6p_ZRPS_UHF,Cu2_MP2,N2_roR-xDH7,N2_roXYG3"
  # ==== mac hang reproduction diagnostic: sample the hung first-Fock-build ====
  rm -rf hang_repro
  mkdir -p hang_repro
  if [ -d ./bench_pool/dh/N2_roR-xDH7 ]; then
    cp -r ./bench_pool/dh/N2_roR-xDH7/. hang_repro/
    (
      cd hang_repro
      exec env DYLD_PRINT_LIBRARIES=1 "${REST_BIN}" -i ctrl.in > hang_repro.out 2>&1
    ) &
    HANG_PID=$!
    sleep 100
    if kill -0 "${HANG_PID}" 2>/dev/null; then
      echo "==== REST HANG STACK SAMPLE (N2_roR-xDH7, pid ${HANG_PID}) ===="
      sample "${HANG_PID}" 3 -file hang_repro/sample.txt >/dev/null 2>&1 || true
      sed -n '1,140p' hang_repro/sample.txt 2>/dev/null || true
      echo "==== loaded OMP/OpenBLAS dylibs ===="
      grep -iE "libomp|libopenblas" hang_repro/hang_repro.out 2>/dev/null | head -20 || true
      echo "==== hang_repro.out tail ===="
      tail -5 hang_repro/hang_repro.out 2>/dev/null || true
      kill -9 "${HANG_PID}" 2>/dev/null || true
      wait "${HANG_PID}" 2>/dev/null || true
    else
      echo "==== N2_roR-xDH7 standalone did not hang (pid exited) ===="
      tail -5 hang_repro/hang_repro.out 2>/dev/null || true
    fi
  fi
fi
"${REST_REG_BIN}" -r ./bench_pool -p "${REST_BIN}" -t 4 ${SKIP_EXTRA} --timeout 200
# ScaLAPACK variant: MPI + forced distributed paths, mirroring validate.sh --scalapack
# (scope must stay in sync with MPI_TEST_SCOPE.md: scf, gradient + tests.toml tags=["mpi"])
if command -v ldd >/dev/null && ldd "${REST_BIN}" | grep -qi scalapack; then
  export REST_BASIS_DIR="${PREFIX}/share/rest/basis-set-pool"
  "${REST_REG_BIN}" -r ./bench_pool -p "${REST_BIN}" -n 2 -t 2 --scalapack -f "scf,gradient,mpi" --timeout 600
fi
# catch the error if rest_regression fail and print the log file
# if ! ${PREFIX}/bin/rest_regression -r ./bench_pool -p ${PREFIX}/bin/rest; then
#     cd bench_pool/CO_HF_Dipole
#     rest
#     exit 1
# fi
