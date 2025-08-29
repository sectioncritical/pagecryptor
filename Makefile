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

all: build

.PHONY: help
help:
	@echo ""
	@echo "-------------"
	@echo "Makefile help"
	@echo "-------------"
	@echo ""
	@echo "build       - build distribution package"
	@echo "test        - run automated tests"
	@echo "testdirty   - run tests without rebuilding environment"
	@echo "lint        - run quality tools and print to console"
	@echo "reports     - generate reports from quality tools, for CI"
	@echo ""
	@echo "clean       - clean test artifacts, reports, and build caches"
	@echo "distclean   - clean plus build dist packages and venv"
	@echo ""
	@echo "venv        - create python virtual environment (automatic when needed)"
	@echo "cleanvenv   - clean the python venv"
	@echo "audit       - run python package checker (automatic when needed)"
	@echo "requirements- generate updated requirements file"
	@echo ""

.PHONY: build
build: |venv
	venv/bin/python3 -m build

.PHONY: test
test:
	tests/runtest.sh

.PHONY: testdirty
testdirty:
	tests/runtest.sh -d

.PHONY: lint
lint:
	-venv/bin/ruff check pagecryptor/pagecryptor.py

.PHONY: reports
reports:
	@echo "Not implemented"

.PHONY: clean
clean:
	rm -rf *.egg-info
	rm -rf build
	rm -rf pagecryptor/*.egg-info
	rm -rf pagecrytpor/__pycache__
	rm -rf tests/output
	rm -rf tests/venv
	rm -rf reports

.PHONY: distclean
distclean: clean cleanvenv
	rm -rf dist

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
	venv/bin/python -m pip freeze > requirements.txt

.PHONY: cleanvenv
cleanvenv:
	rm -rf venv

.PHONY: audit
audit: |venv
	venv/bin/pip-audit
