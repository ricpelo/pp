# PP
# Copyright (C) 2015, 2016, 2017 Christophe Delord
# http://www.cdsoft.fr/pp
#
# This file is part of PP.
#
# PP is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PP is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PP.  If not, see <http://www.gnu.org/licenses/>.

SHELL = /bin/bash
.SHELLFLAGS = -o pipefail -c

title = /bin/echo -e "\x1b[1m\x1b[32m\#\#\#\# $1\x1b[0m"
ok = /bin/echo -e "\x1b[1m\x1b[32m[OK] $1\x1b[0m"

#####################################################################
# Platform detection
#####################################################################

OS = $(shell uname)

BIN_DIR := $(shell stack path --local-install-root)/bin

# Linux
ifeq "$(OS)" "Linux"

PP = $(BIN_DIR)/pp

all: $(PP)
all: README.md doc/pp.html
all: pp.tgz
all: pp-linux-$(shell uname -m).txz

# MacOS
else ifeq "$(OS)" "Darwin"

PP 	= $(BIN_DIR)/pp

all: $(PP)
all: README.md doc/pp.html
all: pp.tgz
all: pp-darwin-$(shell uname -m).txz

# Windows
else ifeq "$(shell echo $(OS) | grep 'MSYS\|MINGW\|CYGWIN' >/dev/null && echo Windows)" "Windows"

PP 	= $(BIN_DIR)/pp.exe

all: $(PP)
all: doc/pp.html

# Unknown platform (please contribute ;-)
else
$(error "Unknown platform: $(OS)")
endif

BUILD = .stack-work

TAG = src/Tag.hs
$(shell ./tag.sh $(TAG))

install: $(PP)
	@$(call title,"installing $<")
	stack install
	@$(call ok,"installation done")

clean:
	stack clean
	rm -rf $(BUILD)
	rm -f doc/pp.html
	rm -rf doc/img
	rm -f pp*.tgz pp-win.7z pp-linux-*.txz pp-darwin-*.txz
	rm -f src/$(PLANTUML).c

.DELETE_ON_ERROR:

#####################################################################
# README
#####################################################################

README.md: $(PP)
README.md: doc/pp.md
	@$(call title,"preprocessing $<")
	@mkdir -p doc/img
	$(PP) -en -img=doc/img -DREADME $< | pandoc -f markdown -t markdown_github > $@
	@$(call ok,"$@")

#####################################################################
# archives
#####################################################################

pp.tgz: Makefile $(wildcard app/*) $(wildcard doc/pp.*) $(wildcard src/*) $(wildcard test/*) README.md LICENSE .gitignore Setup.hs pp.cabal stack.yaml
	@$(call title,"source archive: $@")
	tar -czf $@ $^

pp-win.7z: $(PP) doc/pp.html
	@$(call title,"Windows binary archive: $@")
	7z -mx9 a $@ $^

pp-linux-%.txz: $(PP) doc/pp.html
	@$(call title,"Linux binary archive: $@")
	tar cJf $@ --transform='s,.*/,,' $^

pp-darwin-%.txz: $(PP) doc/pp.html
	@$(call title,"MacOS binary archive: $@")
	tar cJf $@ --transform='s,.*/,,' $^

#####################################################################
# Dependencies
#####################################################################

PLANTUML = plantuml
PLANTUML_URL = http://sourceforge.net/projects/plantuml/files/$(PLANTUML).jar

$(BUILD)/%.c: $(BUILD)/%.jar
	@$(call title,"converting $< to C")
	@mkdir -p $(dir $@)
	xxd -i $< $@
	sed -i -e 's/_stack_work_//g' $@
	@$(call ok,"$@")

$(BUILD)/$(PLANTUML).jar:
	@$(call title,"downloading $(notdir $@)")
	@mkdir -p $(dir $@)
	wget $(PLANTUML_URL) -O $@
	@$(call ok,"$@")

#####################################################################
# PP
#####################################################################

LIB_SOURCES = $(wildcard src/*.hs) $(BUILD)/$(PLANTUML).c
PP_SOURCES = app/pp.hs

$(PP): $(PP_SOURCES) $(LIB_SOURCES)
	@$(call title,"building $@")
	stack build
	@$(call ok,"$@")

doc/pp.html: $(PP) doc/pp.css
doc/pp.html: doc/pp.md
	@$(call title,"preprocessing $<")
	@mkdir -p $(dir $@) doc/img
	$(PP) -en -img=doc/img $< | pandoc -S --toc --self-contained -c doc/pp.css -f markdown -t html5 > $@
	@$(call ok,"$@")

#####################################################################
# tests
#####################################################################

.PHONY: test hspec test-md test-rst

test: hspec test-md test-rst test-md-d
	@$(call ok,"all pp tests passed!")

# Hspec tests

hspec: test/Spec.hs $(LIB_SOURCES)
	stack test

# Markdown test

test-md: $(BUILD)/pp-test.output test/pp-test.ref
	@$(call title,"checking $<")
	diff -b -B $^
	@$(call ok,"Markdown test passed!")

$(BUILD)/pp-test.output: $(PP) doc/pp.css
$(BUILD)/pp-test.output: test/pp-test.md test/pp-test.i test/pp-test-lib.i
	@$(call title,"preprocessing $<")
	@mkdir -p $(BUILD)/img
	TESTENVVAR=42 $(PP) -md -img="[$(BUILD)/]img" -en -html -import=test/pp-test-lib.i $< > $@
	pandoc -S --toc -c doc/pp.css -f markdown -t html5 $@ -o $(@:.output=.html)

.PHONY: ref
ref: $(BUILD)/pp-test.output
	meld $< test/pp-test.ref 2>/dev/null

# reStructuredText test

test-rst: $(BUILD)/pp-test-rst.output test/pp-test-rst.ref
	@$(call title,"checking $<")
	diff -b -B $^
	@$(call ok,"reStructuredText test passed!")

$(BUILD)/pp-test-rst.output: $(PP) doc/pp.css
$(BUILD)/pp-test-rst.output: test/pp-test.rst
	@$(call title,"preprocessing $<")
	@mkdir -p $(BUILD)/img
	TESTENVVAR=42 $(PP) -rst -img="[$(BUILD)/]img" -en -html $< > $@
	pandoc -S --toc -c doc/pp.css -f rst -t html5 $@ -o $(@:.output=.html)

.PHONY: ref-rst
ref-rst: $(BUILD)/pp-test-rst.output
	meld $< test/pp-test-rst.ref 2>/dev/null

# Dependency list test

test-md-d: $(BUILD)/pp-test.d test/pp-test.d.ref
	@$(call title,"checking $<")
	diff -b -B $^
	@$(call ok,"Dependency test passed!")

$(BUILD)/pp-test.d: $(PP)
$(BUILD)/pp-test.d: test/pp-test.md test/pp-test.i test/pp-test-lib.i
	@$(call title,"tracking dependencies of $<")
	@mkdir -p $(BUILD)/img
	TESTENVVAR=42 $(PP) -M outputfile -md -img="[$(BUILD)/]img" -en -html -import=test/pp-test-lib.i $< > $@

.PHONY: ref-d
ref-d: $(BUILD)/pp-test.d
	meld $< test/pp-test.d.ref 2>/dev/null

