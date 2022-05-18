# Build Stage:
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake clang

## Add Source Code
ADD . /despacer
WORKDIR /despacer/fuzz

## Build Step
RUN rm -rf build
RUN mkdir build
WORKDIR build
RUN CC=clang CXX=clang++ cmake ..
RUN make

# Package Stage
FROM debian:bullseye-slim
COPY --from=builder /despacer/fuzz/build/fuzz /
