# Use a Debian 12 (bookworm) base image
FROM debian:bookworm-slim

# Set environment variables to prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and DPDK dependencies
RUN apt-get update && \
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

# Define DPDK environment variables (matching our build configuration)
ENV RTE_SDK=/usr/local/dpdk
ENV RTE_TARGET=x86_64-native-linux-gcc

# Create the DPDK installation directory and set necessary paths
# This helps Meson's install target to place files correctly.
RUN mkdir -p $RTE_SDK/include \
           $RTE_SDK/lib/$RTE_TARGET \
           $RTE_SDK/lib/$RTE_TARGET/pkgconfig \
           /home/dpdk_build

# Download DPDK source code
WORKDIR /home/dpdk_build
RUN wget https://fast.dpdk.org/rel/dpdk-25.11.tar.xz && \
    tar -xf dpdk-25.11.tar.xz && \
    cd dpdk-25.11 && \
    meson setup builddir --prefix=$RTE_SDK -Dtarget=$RTE_TARGET && \
    ninja -C builddir install && \
    # Copy pkgconfig file to the expected location if Meson didn't do it automatically
    # This is a crucial step if Meson's install phase is inconsistent
    if [ ! -f $RTE_SDK/lib/$RTE_TARGET/pkgconfig/libdpdk.pc ]; then \
        cp meson-private/libdpdk.pc $RTE_SDK/lib/$RTE_TARGET/pkgconfig/; \
    fi && \
    # Clean up build artifacts to reduce image size
    rm -rf builddir

# Copy the hft_app project into the Docker image
# Assuming hft_app is in the same directory as the Dockerfile
COPY hft_app /app/hft_app

# Set the working directory for the application
WORKDIR /app/hft_app

# Set environment variables for the application runtime
# Ensure pkg-config can find DPDK's .pc file
ENV PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$RTE_SDK/lib/$RTE_TARGET/pkgconfig
# Add DPDK binaries and necessary directories to the PATH
ENV PATH=$PATH:/usr/sbin:$RTE_SDK/bin:$RTE_SDK/lib/$RTE_TARGET/bin

# Build the hft_app using the Makefile, leveraging the set environment variables
RUN make

# Default command to show the application directory contents
# This command will execute when a container starts without a specific command
CMD ["ls", "-l", "/app/hft_app"]