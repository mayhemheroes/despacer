#ifdef __AVX512VBMI2__

#include <stddef.h>
#include <x86intrin.h>

size_t vbmi2_despace(char *bytes, size_t howmany);

#endif
