EXECUTABLES=\
						cookies \
						cookies-reset \
						forget-backups \
						fs \
						git-greb \
						glacier

.PHONY: default
default: clean list compile install test

.PHONY: clean
clean:
	rm -rf pkg bin

.PHONY: list
list:
	go list ./...

.PHONY: fix
fix:
	go fix github.com/daniel-fanjul-alcuten/...

.PHONY: vet
vet:
	go vet github.com/daniel-fanjul-alcuten/...

.PHONY: compile
compile: fix vet
	go install ./...

.PHONY: install
install: $(foreach filename,$(EXECUTABLES),~/usr/local/bin/$(filename))

~/usr/local/bin:
	mkdir -p $@

~/usr/local/bin/%: ./bin/% compile ~/usr/local/bin
	cp $< $@

.PHONY: test
test:
	go test github.com/daniel-fanjul-alcuten/...
