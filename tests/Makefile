# Makefile for Project/tests

# Compiler settings
FC = h5fc
FLAGS = -cpp -Wall -Wextra

# Directories
SRC_DIR = ../src
OBJECTS_DIR = objects
MODULES_DIR = modules

# Source files
SRC_FILES = $(wildcard $(SRC_DIR)/*.f90)
TEST_FILES = asserts.f90 $(filter-out asserts.f90, $(wildcard *.f90))

# Object files
SRC_OBJ_FILES = $(filter-out $(OBJECTS_DIR)/main.o, $(patsubst $(SRC_DIR)/%.f90, $(OBJECTS_DIR)/%.o, $(SRC_FILES)) )
TEST_OBJ_FILES = $(patsubst %.f90,$(OBJECTS_DIR)/%.o,$(TEST_FILES))

# Module files
SRC_MOD_FILES = $(patsubst $(SRC_DIR)/%.f90, $(MODULES_DIR)/%.mod, $(SRC_FILES))
TEST_MOD_FILES = $(patsubst %.f90,$(MODULES_DIR)/%.mod,$(TEST_FILES))

# Executable
EXECUTABLE = tests

.PHONY: all clean

# Default target
all: $(EXECUTABLE)

# Link object files and create executable
$(EXECUTABLE): $(SRC_OBJ_FILES) $(TEST_OBJ_FILES)
	$(FC) $(FLAGS) $^ -o $@

# Compile source files
$(OBJECTS_DIR)/%.o: $(SRC_DIR)/%.f90 $(MODULES_DIR)/%.mod
	@mkdir -p $(OBJECTS_DIR)
	$(FC) $(FLAGS) -c $< -o $@

# Compile test files
$(OBJECTS_DIR)/%.o: %.f90 $(MODULES_DIR)/%.mod
	@mkdir -p $(OBJECTS_DIR)
	$(FC) $(FLAGS) -c $< -o $@

# Generate module files
$(MODULES_DIR)/%.mod: $(SRC_DIR)/%.f90
	@mkdir -p $(MODULES_DIR)
	$(FC) $(FLAGS) -c $< -o $@

$(MODULES_DIR)/%.mod: %.f90
	@mkdir -p $(MODULES_DIR)
	$(FC) $(FLAGS) -c $< -o $@

# Clean generated files
clean:
	rm -rf $(OBJECTS_DIR)
	rm -rf $(MODULES_DIR)
	rm -f $(EXECUTABLE)