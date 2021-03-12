.PHONY: clean
clean:
	eldev clean all

.PHONY: prepare
prepare:
	eldev -C --unstable -p -dtT prepare

.PHONY: compile
compile:
	eldev clean elc
	eldev -C --unstable -a -dtT compile

.PHONY: lint
lint:
	eldev -C --unstable -p -dtT lint

.PHONY: test
test:
	eldev -C --unstable -p -dtT test
