EXECUTABLES=\
						cookies \
						cookies-reset \
						forget-backups \
						fs \
						git-greb \
						glacier \
						mining \
						osdb \
						ts

.PHONY: default
default: clean list compile install test vim

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

.PHONY: lint
lint:
	go get -v github.com/golang/lint/golint
	~/lib/go/bin/golint github.com/daniel-fanjul-alcuten/...

.PHONY: compile
compile: fix
	go get -v github.com/jstemmer/gotags
	go get -v github.com/oz/osdb/cmd/osdb
	go get -v github.com/rdwilliamson/glacier
	go get -v golang.org/x/tools/cmd/godoc
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
