# Copyright 2013 Afiniate All Rights Reserved.
#
# You can control some aspects of the build with next variables (e.g.
# make VARIABLE_NAME="some-value")
#
#  * PARALLEL_JOBS=N let ocamlbuild run N jobs in parallel. The recommended
#    value is the number of cores of your machine. Note that we don't want to
#    use make's own parallel flag (-j), as it will spawn several ocamlbuild jobs
#    competing with each other
#  * BUILD_FLAGS flags used to compile non production ocaml code (e.g tools,
#    tests ...)
#  * BUILD_PROD_FLAGS flags used to compile production ocaml code
#
# =============================================================================
# VARS
# =============================================================================
BUILD_DIR := $(CURDIR)/_build
LIB_DIR := $(BUILD_DIR)/lib

PREFIX := /usr

### Knobs
PARALLEL_JOBS ?= 2
BUILD_FLAGS ?= -use-ocamlfind -cflags -bin-annot -lflags -g

### Test bits
TESTS_DIR := $(BUILD_DIR)/tests
TEST_RUN_SRCS := $(shell find $(CURDIR)/lib -name "*_tests_run.ml")
TEST_RUN_EXES := $(notdir $(TEST_RUN_SRCS:%.ml=%))
TEST_RUN_CMDS := $(addprefix $(TESTS_DIR)/, $(TEST_RUN_EXES))
TEST_RUN_TARGETS:= $(addprefix run-, $(TEST_RUN_EXES))

# =============================================================================
# Descriptive Vars
# =============================================================================
NAME=ddbi
LICENSE="OSI Approved :: Apache Software License v2.0"
AUTHOR="Afiniate, Inc."
HOMEPAGE="https://github.com/afiniate/ddbi"

DEV_REPO="git@github.com:afiniate/ddbi.git"
BUG_REPORTS="https://github.com/afiniate/ddbi/issues"

DESC="Async based interface to AWS services"

BUILD_DEPS=vrt oUnit
DEPS=core core_extended async async_unix cohttp aws_async sexplib fieldslib

# =============================================================================
# Created Vars
# =============================================================================

MOD_DEPS=$(foreach DEP,$(DEPS), --depends $(DEP))
MOD_BUILD_DEPS=$(foreach DEP,$(BUILD_DEPS), --build-depends $(DEP))

UTOP_MODS=$(foreach DEP,$(DEPS), \#require \"$(DEP)\";; )

UTOP_INIT=$(BUILD_DIR)/init.ml
# =============================================================================
# COMMANDS
# =============================================================================

BUILD := ocamlbuild -j $(PARALLEL_JOBS) -build-dir $(BUILD_DIR) $(BUILD_FLAGS)

# =============================================================================
# Rules to build the system
# =============================================================================

.PHONY: all build rebuild opam install test utop

.PRECIOUS: %/.d

%/.d:
	mkdir -p $(@D)
	touch $@

all: build

rebuild: clean all

build:
	$(BUILD) $(NAME)_exec.native $(NAME)_exec.byte $(NAME).cma $(NAME).cmx \
	$(NAME).cmxa $(NAME).a $(NAME).cmxs

test: build
	$(BUILD) $(NAME)_unit_tests_run.byte
	$(LIB_DIR)/$(NAME)_unit_tests_run.byte

metadata:
	vrt prj make-opam \
	--homepage $(HOMEPAGE) \
	--dev-repo $(DEV_REPO) \
	--lib-dir $(LIB_DIR) \
	--license $(LICENSE) \
	--name $(NAME) \
	--author $(AUTHOR) \
	--maintainer $(AUTHOR) \
	--bug-reports $(BUG_REPORTS) \
	--build-cmd "make" \
	--install-cmd "make \"install\" \"PREFIX=%{prefix}%\"" \
	--remove-cmd "make \"remove\" \"PREFIX=%{prefix}%\"" \
	$(MOD_BUILD_DEPS)
	$(MOD_DEPS) \
	--desc $(DESC)

install:
	cd $(LIB_DIR); ocamlfind install $(NAME) META $(NAME).cmi $(NAME).cmo $(NAME).o \
	                                           $(NAME).cmx $(NAME).a \
	                                           $(NAME).cmxa
	cp $(LIB_DIR)/$(NAME)_exec.native $(PREFIX)/bin/$(NAME)

remove:
	ocamlfind remove $(NAME)
	rm $(PREFIX)/bin/$(NAME)

clean:
	rm -rf $(BUILD_DIR)

# =============================================================================
# Rules for testing
# =============================================================================
compile-tests: $(TEST_RUN_CMDS)

integ-test: $(filter %_integ_tests_run, $(TEST_RUN_TARGETS))

# =============================================================================
# Support
# =============================================================================
$(UTOP_INIT): build
	@echo "$(UTOP_MODS)" > $(UTOP_INIT)
	@echo "open Core.Std;;" >> $(UTOP_INIT)
	@echo "open Async.Std;;" >> $(UTOP_INIT)
	@echo "#load \"$(NAME).cma\";;" >> $(UTOP_INIT)

utop: $(UTOP_INIT)
	utop -I $(LIB_DIR) -I $(LIB_DIR)/types -init $(UTOP_INIT)
