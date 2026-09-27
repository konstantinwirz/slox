SLOX := $(shell pwd)/.build/debug/LoxCLI
CRAFTING_INTERPRETERS_DIR := $(shell pwd)/../craftinginterpreters

# $(call run-tests,<chapter>,<mode>)
define run-tests
	cd $(CRAFTING_INTERPRETERS_DIR) && dart tool/bin/test.dart $(1) -a $(2) -a -f --interpreter $(SLOX)
endef

build: $(SLOX)
	swift build

test-chap04-scanning: build
	$(call run-tests,chap04_scanning,tokenize)

test-chap06-parsing: build
	$(call run-tests,chap06_parsing,parse)

test-chap07-evaluating: build
	$(call run-tests,chap07_evaluating,eval)

test-chap08-statements: build
	$(call run-tests,chap08_statements,eval)

test-chap09-control: build
	$(call run-tests,chap09_control,eval)

test-chap10-functions: build
	$(call run-tests,chap10_functions,eval)

test-chap11-resolving: build
	$(call run-tests,chap11_resolving,eval)

test-chap12-classes: build
	$(call run-tests,chap12_classes,eval)

test-chap13-inheritance: build
	$(call run-tests,chap13_inheritance,eval)

test-jlox: build
	$(call run-tests,jlox,eval)

# Only chapters that currently pass; add more as they're implemented.
test-all: test-chap04-scanning test-chap06-parsing test-chap07-evaluating

.PHONY: build test-all test-jlox test-chap04-scanning test-chap06-parsing test-chap07-evaluating \
	test-chap08-statements test-chap09-control test-chap10-functions test-chap11-resolving \
	test-chap12-classes test-chap13-inheritance
