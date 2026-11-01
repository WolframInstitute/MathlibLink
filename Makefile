WOLFRAMSCRIPT ?= wolframscript

.DEFAULT_GOAL := check
.PHONY: check test test-mathlib notebooks check-publish publish all

check:
	$(WOLFRAMSCRIPT) -file scripts/check.wls

test:
	$(WOLFRAMSCRIPT) -file scripts/test.wls

test-mathlib:
	$(WOLFRAMSCRIPT) -file scripts/test.wls mathlib MathlibLink/Tests/Integration/Namespace.wlt
	$(WOLFRAMSCRIPT) -file scripts/test.wls mathlib MathlibLink/Tests/Integration/Values.wlt
	$(WOLFRAMSCRIPT) -file scripts/test.wls mathlib MathlibLink/Tests/Integration/Proof.wlt
	$(WOLFRAMSCRIPT) -file scripts/test.wls mathlib MathlibLink/Tests/Integration/ProofRejection.wlt
	$(WOLFRAMSCRIPT) -file scripts/test.wls mathlib MathlibLink/Tests/Integration/Objects.wlt
	$(WOLFRAMSCRIPT) -file scripts/test.wls mathlib MathlibLink/Tests/Integration/Timeout.wlt

notebooks:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls build

check-publish:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls check

publish:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls publish

all: check test check-publish
