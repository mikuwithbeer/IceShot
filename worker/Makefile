CC   = clang
ODIN = odin

ARGS    =
NAME    = IceShotWorker
VERSION = 2026.08.13

SOURCE_PATH = source
NATIVE_PATH = native
OUTPUT_PATH = output
OUTPUT_NAME = $(OUTPUT_PATH)/$(NAME)

FLAGS_NATIVE_DEBUG   = -Og -g
FLAGS_NATIVE_RELEASE = -O3
FLAGS_NATIVE_DEFAULT = -c -fobjc-arc -mmacosx-version-min=14.0

FLAGS_DEBUG   = -debug
FLAGS_RELEASE = -o:speed
FLAGS_LINKING = -framework Cocoa \
                -framework IOKit \
                -framework QuartzCore \
                -framework CoreFoundation \
                -framework CoreGraphics \
                -framework ScreenCaptureKit \
                -framework Vision
FLAGS_DEFAULT = -define:VERSION="$(VERSION)" -vet -strict-style -extra-linker-flags:"$(FLAGS_LINKING)"

.PHONY: all debug release run clean

all: release

debug:
	@mkdir -p $(OUTPUT_PATH)
	@$(CC) $(FLAGS_PREPARE) $(NATIVE_PATH)/native.m -o $(OUTPUT_PATH)/native.o $(FLAGS_NATIVE_DEFAULT) $(FLAGS_NATIVE_DEBUG)
	@$(ODIN) build $(SOURCE_PATH) -out=$(OUTPUT_NAME) $(FLAGS_DEFAULT) $(FLAGS_DEBUG)

release:
	@mkdir -p $(OUTPUT_PATH)
	@$(CC) $(FLAGS_PREPARE) $(NATIVE_PATH)/native.m -o $(OUTPUT_PATH)/native.o $(FLAGS_NATIVE_DEFAULT) $(FLAGS_NATIVE_RELEASE)
	@$(ODIN) build $(SOURCE_PATH) -out=$(OUTPUT_NAME) $(FLAGS_DEFAULT) $(FLAGS_RELEASE)

run: debug
	@./$(OUTPUT_NAME) $(ARGS)

clean:
	@rm -rf $(OUTPUT_PATH)
