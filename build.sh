#!/bin/bash

set -x

export CC=gcc

mkdir -p deps
make -j`nproc` deps
pushd deps

# The OpenSSL, wolfSSL, mbedtls libraries are necessary for the non-SGX
# clients. We do not use their package versions since we need them to
# be compiled with specific flags.

if [[ ! -d mbedtls ]] ; then
    git clone https://github.com/ARMmbed/mbedtls.git
    pushd mbedtls
    git checkout mbedtls-2.5.1
    # Add  -DCMAKE_BUILD_TYPE=Debug for Debug
    patch -p1 < ../../mbedtls-enlarge-cert-write-buffer.patch
    patch -p1 < ../../mbedtls-ssl-server.patch
    patch -p1 < ../../mbedtls-client.patch
    cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_PROGRAMS=off -DCMAKE_CC_COMPILER=$CC -DCMAKE_C_FLAGS="-fPIC -O2 -DMBEDTLS_X509_ALLOW_UNSUPPORTED_CRITICAL_EXTENSION" . || exit 1
    make -j`nproc` || exit 1
    cmake -D CMAKE_INSTALL_PREFIX=$(readlink -f ../local) -P cmake_install.cmake || exit 1
    popd
fi

popd # deps

# Copy client certificates required to talk to Intel's Attestation
# Service
# cp ../../certs/ias-client*.pem .

echo "Building wolfSSL SGX library ..."
# The "make ... clean"s make sure there is no residual state from
# previous builds lying around that might otherwise confuse the
# build system.
make -f ratls-wolfssl.mk clean || exit 1
make -f ratls-wolfssl.mk || exit 1
make -f ratls-wolfssl.mk clean || exit 1

pushd deps
if [[ ! -d wolfssl-examples ]] ; then
    echo "Building SGX-SDK-based wolfSSL sample server (HTTPS) ..."
    
    git clone https://github.com/wolfSSL/wolfssl-examples.git || exit 1
    pushd wolfssl-examples
    git checkout 94b94262b45d264a40d484060cee595b26bdbfd7
    patch -p1 < ../../wolfssl-examples.patch || exit 1
    # Copy certificates required to talk to Intel Attestation Service
    ln -s ../../../ias-client-key.pem SGX_Linux/ias-client-key.pem
    ln -s ../../../ias-client-cert.pem SGX_Linux/ias-client-cert.pem
    popd
fi
popd

echo "Building non-SGX-SDK sample clients ..."
make clients || exit 1
make clean || exit 1

make sgxsdk-server || exit 1
