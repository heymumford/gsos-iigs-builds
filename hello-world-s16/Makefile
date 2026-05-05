.POSIX:

# Hello World S16 — ORCA/C + Golden Gate Build
# Produces OMF file type $B3 (S16 executable)

BUILD_DIR := build
ARTIFACT := $(BUILD_DIR)/hello.S16
SOURCE := hello.c

.PHONY: all clean test verify

all: $(ARTIFACT)

$(ARTIFACT): $(SOURCE)
	@mkdir -p $(BUILD_DIR)
	iix compile -o $@ $<

verify: $(ARTIFACT)
	@echo "Verifying OMF S16 artifact..."
	@if [ ! -f $(ARTIFACT) ]; then \
		echo "FAIL: artifact not found: $(ARTIFACT)"; \
		exit 1; \
	fi
	@if [ ! -s $(ARTIFACT) ]; then \
		echo "FAIL: artifact is empty"; \
		exit 1; \
	fi
	@echo "OK: $(ARTIFACT) (size=$$(stat -f%z $(ARTIFACT)) bytes)"
	@xxd -l 32 $(ARTIFACT) | head -1

test: verify tests/test_compile.sh tests/test_artifact.sh
	@echo "Running Phase 2 compile gate..."
	@bash tests/test_compile.sh
	@echo "Running artifact validation..."
	@bash tests/test_artifact.sh

clean:
	rm -rf $(BUILD_DIR)
