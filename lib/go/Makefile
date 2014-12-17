EXECUTABLES=\
						cookies \
						cookies-reset \
						forget-backups \
						fs \
						git-greb \
						glacier \
						ts

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
	go get -v golang.org/x/tools/cmd/vet
	go vet github.com/daniel-fanjul-alcuten/...

.PHONY: compile
compile: fix vet
	go get -v github.com/nsf/gocode
	go get -v code.google.com/p/rog-go/exp/cmd/godef
	go get -v golang.org/x/tools/cmd/goimports
	go get -v golang.org/x/tools/cmd/oracle
	go get -v golang.org/x/tools/cmd/gorename
	go get -v github.com/golang/lint/golint
	go get -v github.com/kisielk/errcheck
	go get -v github.com/jstemmer/gotags
	go install github.com/daniel-fanjul-alcuten/...

.PHONY: install
install: $(foreach filename,$(EXECUTABLES),~/usr/local/bin/$(filename))

~/usr/local/bin:
	mkdir -p $@

~/usr/local/bin/%: ./bin/% compile ~/usr/local/bin
	cp -f $< $@

.PHONY: test
test:
	go test github.com/daniel-fanjul-alcuten/...

.PHONY: vim
vim:
	vim -c ':GoInstallBinaries' -c :q
