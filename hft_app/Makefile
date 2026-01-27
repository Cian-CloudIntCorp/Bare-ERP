# Project Name
TARGET = hft_app

# Compiler
CXX = g++

# DPDK build flags obtained via pkg-config
# PKG_CONFIG_PATH is set to the directory containing libdpdk.pc
PKG_CONFIG_PATH := $(shell echo "/home/cianegan/dpdk-25.11/builddir/meson-private")

# Compiler flags obtained from pkg-config
# Use $(shell ...) to capture the output of pkg-config
CXXFLAGS := $(shell pkg-config --cflags libdpdk)

# Linker flags obtained from pkg-config
LDFLAGS := $(shell pkg-config --libs libdpdk)

# Source files
SRCS = main.cpp

# Object files
OBJS = $(SRCS:.cpp=.o)

# Default target
all: $(TARGET)

$(TARGET): $(OBJS)
	@echo "Linking $(TARGET)..."
	$(CXX) $(OBJS) -o $@ $(LDFLAGS)
	@echo "$(TARGET) built successfully."

%.o: %.cpp
	@echo "Compiling $<..."
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	@echo "Cleaning up..."
	rm -f $(OBJS) $(TARGET)
	@echo "Cleanup complete."

.PHONY: all clean
