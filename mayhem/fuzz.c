// libFuzzer harness for despacer's scalar despace() family (ported from the
// original fork's fuzz/fuzz.c, which mutated libFuzzer's const input buffer —
// this version works on heap copies and cross-checks implementations that
// share the same whitespace semantics).
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "despacer.c"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size == 0)
    return 0;

  char *buf = (char *)malloc(size);
  char *ref = (char *)malloc(size);
  char *dst = (char *)malloc(size);
  if (!buf || !ref || !dst)
    abort();

  // group 1: removes ' ', '\n', '\r'
  memcpy(ref, data, size);
  size_t reflen = despace(ref, size);
  if (reflen > size)
    abort();
  if (reflen != size - countspaces((const char *)data, size))
    abort();
  for (size_t i = 0; i < reflen; i++) {
    char c = ref[i];
    if (c == ' ' || c == '\n' || c == '\r')
      abort();
  }

  memcpy(buf, data, size);
  if (faster_despace(buf, size) != reflen || memcmp(buf, ref, reflen) != 0)
    abort();

  // group 2: removes every byte <= 32
  memcpy(ref, data, size);
  size_t ref32 = despace32(ref, size);
  if (ref32 > size)
    abort();

  memcpy(buf, data, size);
  if (faster_despace32(buf, size) != ref32 || memcmp(buf, ref, ref32) != 0)
    abort();

  // group 3: removes ' ', '\t', '\n', '\r' (src/dst variants)
  memcpy(buf, data, size);
  size_t reftab = despace_branchless(dst, buf, size);
  if (reftab > size)
    abort();
  char *reft = (char *)malloc(size ? size : 1);
  if (!reft)
    abort();
  memcpy(reft, dst, reftab);

  memcpy(buf, data, size);
  if (despace_cmov(dst, buf, size) != reftab || memcmp(dst, reft, reftab) != 0)
    abort();

  memcpy(buf, data, size);
  if (despace_table(dst, buf, size) != reftab || memcmp(dst, reft, reftab) != 0)
    abort();

  free(buf);
  free(ref);
  free(dst);
  free(reft);
  return 0;
}
