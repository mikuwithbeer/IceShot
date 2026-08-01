CC   = clang
ODIN = odin

ARGS        =
NAME        = IceShotWorker
VERSION     = 0.0.0

SOURCE_PATH = source
NATIVE_PATH = native
OUTPUT_PATH = output
OUTPUT_NAME = $(OUTPUT_PATH)/$(NAME)

FLAGS_PREPARE = -c -fobjc-arc
FLAGS_DEBUG   = -debug
FLAGS_RELEASE = -o:speed
FLAGS_DEFAULT = -vet -strict-style -extra-linker-flags:"-framework Foundation -framework Cocoa -framework ScreenCaptureKit -framework Vision"

.PHONY: all prepare debug release run clean

all: release

prepare:
	@mkdir -p $(OUTPUT_PATH)
	@$(CC) $(FLAGS_PREPARE) $(NATIVE_PATH)/native.m -o $(OUTPUT_PATH)/native.o

debug: prepare
	@$(ODIN) build $(SOURCE_PATH) -out=$(OUTPUT_NAME) $(FLAGS_DEFAULT) $(FLAGS_DEBUG)

release: prepare
	@$(ODIN) build $(SOURCE_PATH) -out=$(OUTPUT_NAME) $(FLAGS_DEFAULT) $(FLAGS_RELEASE)

run: debug
	@./$(OUTPUT_NAME) $(ARGS)

clean:
	@rm -rf $(OUTPUT_PATH)
