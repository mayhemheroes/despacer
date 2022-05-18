#include "despacer.c"

int LLVMFuzzerTestOneInput(char* data, size_t size) {

    int test = despace(data, size);
    return 0;
}