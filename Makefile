# Copyright 2013 Afiniate All Rights Reserved.

NAME := ddbi
LICENSE := "OSI Approved :: Apache Software License v2.0"
AUTHOR := "Afiniate, Inc."
HOMEPAGE := "https://github.com/afiniate/ddbi"

DEV_REPO := "git@github.com:afiniate/ddbi.git"
BUG_REPORTS := "https://github.com/afiniate/ddbi/issues"

DESC_FILE=$(CURDIR)/description

BUILD_DEPS := vrt ounit
DEPS=core core_extended async async_unix cohttp aws_async sexplib fieldslib

EXTRA_TARGETS:=$(NAME)_exec.native

vrt.mk:
	vrt prj gen-mk

-include vrt.mk

install-extra:
	cp $(LIB_DIR)/$(NAME)_exec.native $(PREFIX)/bin/$(NAME)
