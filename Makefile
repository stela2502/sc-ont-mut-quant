BAM_TIDE_REPO ?= https://github.com/stela2502/bam_tide.git
BAM_TIDE_REF  ?= main
TARGET        ?= x86_64-unknown-linux-musl
BUILD_DIR     ?= .build
BAM_TIDE_DIR  ?= $(BUILD_DIR)/bam_tide

.PHONY: help clean clone build install verify regen

help:
	@echo "Targets:"
	@echo "  make regen   Clone bam_tide, build MUSL binaries, install into bin/"
	@echo "  make clean   Remove local build directory"

clean:
	rm -rf $(BUILD_DIR)

clone:
	mkdir -p $(BUILD_DIR)
	if [ ! -d "$(BAM_TIDE_DIR)/.git" ]; then \
		git clone $(BAM_TIDE_REPO) $(BAM_TIDE_DIR); \
	fi
	cd $(BAM_TIDE_DIR) && git fetch --tags && git checkout $(BAM_TIDE_REF)

build: clone
	cd $(BAM_TIDE_DIR) && rustup target add $(TARGET)
	cd $(BAM_TIDE_DIR) && cargo build --release --target $(TARGET)

install: build
	mkdir -p bin
	cp $(BAM_TIDE_DIR)/target/$(TARGET)/release/bam-ont-normalizer bin/
	cp $(BAM_TIDE_DIR)/target/$(TARGET)/release/bam-transcriptome-to-genome bin/
	cp $(BAM_TIDE_DIR)/target/$(TARGET)/release/bam-quant bin/
	chmod +x bin/bam-ont-normalizer
	chmod +x bin/bam-transcriptome-to-genome
	chmod +x bin/bam-quant

verify:
	file bin/bam-ont-normalizer
	file bin/bam-transcriptome-to-genome
	file bin/bam-quant
	ldd bin/bam-ont-normalizer || true
	ldd bin/bam-transcriptome-to-genome || true
	ldd bin/bam-quant || true

regen: clean install verify
