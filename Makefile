WOLFRAMSCRIPT ?= wolframscript

.DEFAULT_GOAL := check
.PHONY: check test test-mathlib notebooks check-publish publish all

check:
	$(WOLFRAMSCRIPT) -file scripts/check.wls

test:
	$(WOLFRAMSCRIPT) -file scripts/test.wls

test-mathlib:
	$(WOLFRAMSCRIPT) -file scripts/test.wls mathlib

notebooks:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls build

check-publish:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls check

publish:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls publish

all: check test check-publish
