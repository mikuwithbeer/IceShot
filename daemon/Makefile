CC = clang

ARGS    =
NAME    = IceShotDaemon
VERSION = 2026.08.09

SOURCE_PATH = source
OUTPUT_PATH = output
OUTPUT_NAME = $(OUTPUT_PATH)/$(NAME)

FLAGS_DEBUG   = -Og -g
FLAGS_RELEASE = -O3 -flto
FLAGS_LINKING = -framework Foundation -framework Cocoa -framework Carbon -framework ServiceManagement
FLAGS_DEFAULT = -mmacosx-version-min=14.0 -fobjc-arc -DVERSION=\"$(VERSION)\" \
                -Wall -Wextra -Wpedantic -Wshadow -Wconversion \
                -Wno-gnu-auto-type

.PHONY: all debug release run clean

all: release

debug:
	@mkdir -p $(OUTPUT_PATH)
	@$(CC) $(SOURCE_PATH)/main.m -o $(OUTPUT_NAME) $(FLAGS_DEFAULT) $(FLAGS_DEBUG) $(FLAGS_LINKING)

release:
	@mkdir -p $(OUTPUT_PATH)
	@$(CC) $(SOURCE_PATH)/main.m -o $(OUTPUT_NAME) $(FLAGS_DEFAULT) $(FLAGS_RELEASE) $(FLAGS_LINKING)

run: debug
	@./$(OUTPUT_NAME)

clean:
	@rm -rf $(OUTPUT_PATH)
