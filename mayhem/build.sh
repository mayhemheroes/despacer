#!/usr/bin/env bash
# mayhem/build.sh — build despacer's fuzz harness + upstream test suite.
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${CC:=clang}" ; : "${CXX:=clang++}" ; : "${LIB_FUZZING_ENGINE:=-fsanitize=fuzzer}"
: "${MAYHEM_JOBS:=$(nproc)}"
: "${COVERAGE_FLAGS=}"
export SANITIZER_FLAGS DEBUG_FLAGS CC CXX LIB_FUZZING_ENGINE MAYHEM_JOBS COVERAGE_FLAGS

cd "$SRC"

# 1+2) Fuzz harness: the harness #includes src/despacer.c, so the whole fuzzed
#      code path is compiled sanitized + instrumented in one TU (same layout as
#      the original fork's fuzz/fuzz.c). No -march=native: the fuzzer must run
#      on any x86-64 worker, and the scalar family needs no SIMD.
$CC $SANITIZER_FLAGS $DEBUG_FLAGS $LIB_FUZZING_ENGINE \
    -I"$SRC/src" "$SRC/mayhem/fuzz.c" -o /mayhem/fuzz_despacer

$CC $SANITIZER_FLAGS $DEBUG_FLAGS "$STANDALONE_FUZZ_MAIN" \
    -I"$SRC/src" "$SRC/mayhem/fuzz.c" -o /mayhem/fuzz_despacer-standalone

# 3) Upstream test suite (cmake/ctest), built with the project's normal flags.
#    BENCHMARKS=OFF: the benchmark ctest entry is a performance benchmark, not a
#    functional test. test.sh runs `ctest` in build-tests.
rm -rf "$SRC/build-tests"
cmake -S "$SRC" -B "$SRC/build-tests" \
      -DCMAKE_C_COMPILER="$CC" \
      -DCMAKE_BUILD_TYPE=Release \
      -DUNIT_TESTS=ON -DBENCHMARKS=OFF \
      -DCMAKE_C_FLAGS="$COVERAGE_FLAGS" \
      -DCMAKE_EXE_LINKER_FLAGS="$COVERAGE_FLAGS"
cmake --build "$SRC/build-tests" -j"$MAYHEM_JOBS"
