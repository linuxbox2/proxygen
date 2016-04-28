#!/bin/bash

## Run this script to build proxygen and run the tests. If you want to
## install proxygen to use in another C++ project on this machine, run
## the sibling file `reinstall.sh`.

# Parse args
JOBS=8
USAGE="./deps.sh [-j num_jobs]"
while [ "$1" != "" ]; do
  case $1 in
    -j | --jobs ) shift
                  JOBS=$1
                  ;;
    * )           echo $USAGE
                  exit 1
esac
shift
done

set -e
start_dir=`pwd`
trap "cd $start_dir" EXIT

# Must execute from the directory containing this script
cd "$(dirname "$0")"

# Some extra dependencies (updated for Fedora 23)
sudo dnf install -y \
    cmake \
    gcc-c++ \
    flex \
    bison \
    krb5-devel \
    cyrus-sasl-devel \
    numactl-devel \
    pkgconfig \
    openssl-devel \
    libcap-devel \
    gperf \
    autoconf-archive \
    libevent-devel \
    libtool \
    boost-devel \
    jemalloc-devel \
    snappy-devel \
    wget \
    gflags-devel \
    glog-devel \
    double-conversion-devel \
    libatomic \
    unzip

# Get folly
if [ ! -e folly/folly ]; then
    echo "Cloning folly"
    git clone https://github.com/facebook/folly
fi
cd folly/folly
git fetch
git checkout master

# Build folly
autoreconf --install
./configure
make -j$JOBS
sudo make install

if test $? -ne 0; then
	echo "fatal: folly build failed"
	exit -1
fi
cd ../..

# Get wangle
if [ ! -e wangle/wangle ]; then
    echo "Cloning wangle"
    git clone https://github.com/linuxbox2/wangle
fi
cd wangle/wangle
git fetch
git checkout cpp14

# Build wangle
cmake .
make -j$JOBS
sudo make install

if test $? -ne 0; then
	echo "fatal: wangle build failed"
	exit -1
fi
cd ../..

# Build proxygen
autoreconf -ivf
./configure
make -j$JOBS

# Run tests
LD_LIBRARY_PATH=/usr/local/lib make check

# Install the libs
sudo make install
