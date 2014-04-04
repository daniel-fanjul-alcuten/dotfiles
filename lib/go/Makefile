EXECUTABLES=\
						git-greb \
						gocode \
						gotags

.PHONY: default
default: clean compile install

.PHONY: clean
clean:
	git clean -fdx .

.PHONY: compile
compile:
	go install ./...

.PHONY: install
install: $(foreach filename,$(EXECUTABLES),~/usr/local/bin/$(filename))

~/usr/local/bin/%: ./bin/% compile
	@mkdir -p ~/usr/local/bin
	cp $< $@
