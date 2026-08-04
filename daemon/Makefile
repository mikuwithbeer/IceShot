CC = clang

ARGS        =
NAME        = IceShotDaemon
VERSION     = 0.0.0

SOURCE_PATH = source
OUTPUT_PATH = output
OUTPUT_NAME = $(OUTPUT_PATH)/$(NAME)

FLAGS_DEBUG   = -g -gdwarf -fstandalone-debug -Og
FLAGS_RELEASE = -O3
FLAGS_LINKING = -framework Foundation -framework Cocoa -framework Carbon
FLAGS_DEFAULT = -Wall -Wextra -Wpedantic

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
