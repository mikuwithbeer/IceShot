CC   = clang
ODIN = odin

ARGS =

NAME        = IceShot
VERSION     = 0.0.0
SOURCE_PATH = src
OBJECT_PATH = ffi
OUTPUT_PATH = build
OUTPUT_NAME = $(OUTPUT_PATH)/$(NAME)

FLAGS_PREPARE = -c -fobjc-arc
FLAGS_DEBUG   = -debug
FLAGS_RELEASE = -o:speed
FLAGS_DEFAULT = -vet -strict-style -extra-linker-flags:"-framework Foundation -framework Cocoa -framework ScreenCaptureKit"

.PHONY: all prepare debug release run clean

all: release

prepare:
	@mkdir -p $(OUTPUT_PATH)
	@$(CC) $(FLAGS_PREPARE) $(OBJECT_PATH)/capture.m -o $(OUTPUT_PATH)/capture.o

debug: prepare
	@$(ODIN) build $(SOURCE_PATH) -out=$(OUTPUT_NAME) $(FLAGS_DEFAULT) $(FLAGS_DEBUG)

release: prepare
	@$(ODIN) build $(SOURCE_PATH) -out=$(OUTPUT_NAME) $(FLAGS_DEFAULT) $(FLAGS_RELEASE)

run: debug
	@./$(OUTPUT_NAME) $(ARGS)

clean:
	@rm -rf $(OUTPUT_PATH)
