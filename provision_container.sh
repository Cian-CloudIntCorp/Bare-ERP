#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting LXC Container Provisioning ---"

# --- Install Dependencies ---
echo "--- Installing build tools and DPDK dependencies ---"
apt-get update
apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    make \
    pkg-config \
    python3 \
    python3-pip \
    python3-pyelftools \
    meson \
    ninja-build \
    ethtool \
    && rm -rf /var/lib/apt/lists/*

# --- Set DPDK Environment Variables and Paths ---
echo "--- Setting DPDK environment variables and paths ---"
# Use /usr/local/dpdk as the prefix for DPDK installation
export RTE_SDK=/usr/local/dpdk
export RTE_TARGET=x86_64-native-linux-gcc

# Ensure pkg-config can find DPDK's .pc files from the build directory
# This is crucial as the installation path might not be standard
export PKG_CONFIG_PATH=/home/dpdk_build/dpdk-25.11/builddir/meson-private:/usr/local/dpdk/lib/$RTE_TARGET/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig

# Add necessary binaries to PATH
export PATH=$PATH:/usr/sbin:$RTE_SDK/bin:$RTE_SDK/lib/$RTE_TARGET/bin

# --- Download and Build DPDK from Source ---
echo "--- Downloading and building DPDK 25.11 ---"
mkdir -p /home/dpdk_build
cd /home/dpdk_build
wget https://fast.dpdk.org/rel/dpdk-25.11.tar.xz
tar -xf dpdk-25.11.tar.xz
cd dpdk-25.11

# Configure DPDK using Meson, installing to RTE_SDK
# Ensure the target architecture is correctly specified for meson setup
meson setup builddir --prefix=$RTE_SDK -Dtarget=$RTE_TARGET

# Build DPDK
ninja -C builddir

# Install DPDK - this should place headers in $RTE_SDK/include/dpdk
# and libraries in $RTE_SDK/lib/$RTE_TARGET/
ninja -C builddir install

# Ensure pkgconfig files are accessible by copying them to the expected location if missing
# This is a fallback in case Meson's install does not correctly place libdpdk.pc
if [ ! -d $RTE_SDK/lib/$RTE_TARGET/pkgconfig ]; then
    mkdir -p $RTE_SDK/lib/$RTE_TARGET/pkgconfig
    # Find and copy the .pc file from the build directory
    cp meson-private/libdpdk.pc $RTE_SDK/lib/$RTE_TARGET/pkgconfig/
fi

# Clean up build artifacts to reduce container size
rm -rf builddir

# --- Copy and Build hft_app ---
echo "--- Copying and building hft_app ---"
mkdir -p /app/hft_app
# Copy your hft_app source code from a temporary directory
cp -r /tmp/hft_app_src/* /app/hft_app/
cd /app/hft_app

# Build the application using the Makefile, which now uses pkg-config
# Ensure the correct pkg-config path is available to make
# Pass CC and CXX explicitly to ensure they use the compiler found by pkg-config
make CC="gcc" CXX="g++"

echo "--- DPDK and hft_app setup complete inside the container ---"
echo "You can now run your application using: ./hft_app"