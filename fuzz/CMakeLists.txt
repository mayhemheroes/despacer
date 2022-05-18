cmake_minimum_required(VERSION 3.16)
project(despacer)

add_executable(fuzz fuzz.c)
target_include_directories(fuzz PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../src/)

if (NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    message(FATAL_ERROR "Clang is required for libFuzzer!")
endif()
target_compile_options(fuzz PUBLIC -fsanitize=fuzzer)
target_link_options(fuzz PUBLIC -fsanitize=fuzzer)
