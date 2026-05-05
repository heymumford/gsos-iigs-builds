# hello-world/Makefile — POSIX make for cc65 apple2enh smoke test
# Respects CC65_PREFIX and TARGET_DIR environment variables.

.PHONY: all test clean

# Defaults
CC65_PREFIX ?= /usr/local
CC65_BIN := $(CC65_PREFIX)/bin
TARGET := apple2enh
BUILD_DIR := build
TEST_DIR := tests

# Tools (respect PREFIX)
CL65 := $(CC65_BIN)/cl65
CA65 := $(CC65_BIN)/ca65
LD65 := $(CC65_BIN)/ld65
CC65 := $(CC65_BIN)/cc65

# Targets
APP := $(BUILD_DIR)/hello
DSK := $(BUILD_DIR)/hello.dsk

all: $(APP)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Compile: hello.c → hello.s (intermediate assembly)
$(BUILD_DIR)/hello.s: hello.c | $(BUILD_DIR)
	$(CL65) -t $(TARGET) --verbose -E -o $@ $<

# Assemble: hello.s → hello.o
$(BUILD_DIR)/hello.o: $(BUILD_DIR)/hello.s
	$(CA65) -t $(TARGET) -o $@ $<

# Link: hello.o → hello (16-bit S16 application)
$(APP): $(BUILD_DIR)/hello.o
	$(LD65) -t $(TARGET) -o $@ $<

# Test targets
test: test-compile test-artifact
	@echo "[hello-world] all tests passed"

test-compile:
	@bash $(TEST_DIR)/test_compile.sh

test-artifact: $(APP)
	@bash $(TEST_DIR)/test_artifact.sh $(APP)

clean:
	rm -rf $(BUILD_DIR)
