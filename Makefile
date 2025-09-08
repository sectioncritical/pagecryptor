# SPDX-License-Identifier: MIT
#
# MIT License
#
# Copyright (c) 2025 Joseph Kroesche
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# uses some bashism so we need to enforce bash for the github CI runner
SHELL:=$(shell command -v bash)

all: build

.PHONY: help
help:
	@echo ""
	@echo "-------------"
	@echo "Makefile help"
	@echo "-------------"
	@echo ""
	@echo "build       - build distribution package"
	@echo "test        - run automated tests, with reports"
	@echo "testpretty  - run automated test, output only to console"
	@echo "testdirty   - run tests without rebuilding environment (for debug)"
	@echo "ruff        - run ruff code quality and style scanner, with reports"
	@echo "mypy        - run mypy type annotation checker, with reports"
	@echo "example     - generate the example encrypted page"
	@echo "gh-pages    - create gh-pages branch with example file"
	@echo ""
	@echo "clean       - clean test artifacts, reports, and build caches"
	@echo "distclean   - clean plus build dist packages and venv"
	@echo ""
	@echo "venv        - create python virtual environment (automatic when needed)"
	@echo "cleanvenv   - clean the python venv"
	@echo "audit       - run python package checker (automatic when needed)"
	@echo "requirements- generate updated requirements file"
	@echo "submodules  - check out the BATS submodules (only for test)"
	@echo ""

.PHONY: build
build: |venv
	venv/bin/python3 -m build

# create the reports subdir
reports:
	@mkdir -p  $@

# runs the test script
# prints report to console
# generates junit file
# generates html report from junit
.PHONY: test
test: submodules |reports
	@echo ""
	@echo "****RUNNING TESTS****"
	@echo ""
	@./tests/bats-core/bin/bats --report-formatter "junit" --output ./reports ./tests/pctest.bats; \
	exit_status=$$?; \
	echo ""; \
	echo "Generating test report"; \
	echo ""; \
	mv ./reports/report.xml ./reports/test-report.xml; \
	venv/bin/junit2html ./reports/test-report.xml ./reports/test-report.html; \
	exit $$exit_status

# run the test and just show results to console, no test report file
.PHONY: testpretty
testpretty: submodules
	./tests/bats-core/bin/bats --formatter "pretty" ./tests/pctest.bats

# run the test and reuse the existing venv instead of making a new one
# this is useful when debugging the test as it runs faster and avoids pulling
# modules from who-knows-where every single time you run the test
.PHONY: testdirty
testdirty: submodules
	TEST_DIRTY_VENV=1 ./tests/bats-core/bin/bats --formatter "pretty" ./tests/pctest.bats

# run mypy scan and generate junit report
# also prints errors to console
# this also creates a "type coverage" html report
# also convert junit report to html for human browsing
.PHONY: mypy
mypy: venv |reports
	@echo ""
	@echo "****RUNNING MYPY****"
	@echo ""
	@venv/bin/mypy pagecryptor/pagecryptor.py --html-report ./reports/mypy-type-report --no-error-summary --junit-xml ./reports/mypy-report.xml; \
	exit_status=$$?; \
	echo ""; \
	echo "Generating mypy report"; \
	echo ""; \
	venv/bin/junit2html ./reports/mypy-report.xml ./reports/mypy-report.html; \
	exit $$exit_status

# run ruff scanner
# generates junit report and html file
.PHONY: ruff
ruff: venv |reports
	@echo ""
	@echo "****RUNNING RUFF****"
	@echo ""
	@-venv/bin/ruff check pagecryptor/pagecryptor.py
	@echo ""
	@echo "Generating ruff report"
	@echo ""
	@venv/bin/ruff check pagecryptor/pagecryptor.py --output-format "junit" >./reports/ruff-report.xml; \
	exit_status=$$?; \
	venv/bin/junit2html ./reports/ruff-report.xml ./reports/ruff-report.html; \
	exit $$exit_status

.PHONY: example
example: |venv
	venv/bin/pagecryptor "example/grocery.html" "example/grocery-secret.html" --password "pickles" --message "password is 'pickles'"
	@echo "example encrypted page is in example/grocery-secret.html"

.PHONY: gh-pages
gh-pages: |venv
	venv/bin/ghp-import -n -o example

.PHONY: clean
clean:
	rm -rf *.egg-info
	rm -rf build
	rm -rf pagecryptor/*.egg-info
	rm -rf pagecrytpor/__pycache__
	rm -rf tests/output
	rm -rf tests/venv
	rm -rf reports
	rm -f example/grocery-secret.html

.PHONY: distclean
distclean: clean cleanvenv
	rm -rf dist

./tests/bats-core/bin/bats:
	git submodule update --init --recursive

.PHONY: submodules
submodules: ./tests/bats-core/bin/bats

########################################
# PYTHON VIRTUAL ENVIRONMENT MAINTENANCE
########################################

venv: venv/bin/activate

venv/bin/activate: requirements.txt
	test -d venv || python3 -m venv venv
	venv/bin/python -m pip install -U pip setuptools wheel
	venv/bin/python -m pip install -U pip-audit
	venv/bin/python -m pip install --no-deps -r $<
	touch $@
	-venv/bin/pip-audit

.PHONY: requirements
requirements:
	rm -rf venv
	python3 -m venv venv
	venv/bin/python -m pip install -U pip setuptools wheel
	venv/bin/python -m pip install -Ur requirements.in
	venv/bin/python -m pip freeze --exclude-editable > requirements.txt
	@echo "-e ." >> requirements.txt

.PHONY: cleanvenv
cleanvenv:
	rm -rf venv

.PHONY: audit
audit: |venv
	venv/bin/pip-audit
