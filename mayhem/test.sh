#!/usr/bin/env bash
# mayhem/test.sh — RUN despacer's upstream ctest suite (built by mayhem/build.sh).
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
: "${MAYHEM_JOBS:=$(nproc)}"
cd "$SRC"

# emit_ctrf <tool> <passed> <failed> [skipped] [pending] [other]
emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

if [ ! -x "$SRC/build-tests/despacer_unit" ]; then
  echo "FATAL: build-tests/despacer_unit missing — mayhem/build.sh did not build the suite" >&2
  emit_ctrf "cmake-ctest" 0 1
  exit 1
fi

# Run the upstream unit suite (the one ctest registers as `unit`) directly and
# golden-check its OUTPUT: 128 per-iteration progress dots plus the final
# "the code looks ok." verdict that main() prints only after every DESPACE_CHECK
# assertion passed. Exit code alone is not trusted (anti-reward-hacking).
out="$("$SRC/build-tests/despacer_unit" 2>&1)"
rc=$?
echo "$out"

dots="$(printf '%s' "$out" | tr -cd '.' | wc -c)"
if [ "$rc" -eq 0 ] && echo "$out" | grep -q "the code looks ok" && [ "$dots" -ge 129 ]; then
  emit_ctrf "cmake-ctest" 1 0
else
  echo "FAIL: despacer_unit rc=$rc dots=$dots (expected >=129 incl. verdict) or missing verdict" >&2
  emit_ctrf "cmake-ctest" 0 1
fi
