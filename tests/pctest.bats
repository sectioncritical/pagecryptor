#!/usr/bin/env bash
#
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

TEST_DIR="$( cd "$( dirname "${BATS_TEST_FILENAME}" )" >/dev/null 2>&1 && pwd )"

# FILE LEVEL SETUP (all tests)
setup_file() {
    echo "# PRECONDITION CHECK" >&3

    echo '# checking venv' >&3
    if [ -n "${VIRTUAL_ENV}" ]; then
        echo "# ERROR: a virtual environment is already active." >&3
        echo "# deactivate it first before running this test." >&3
        exit 1
    else
        echo "# venv OK" >&3
    fi

    echo "# checking python3" >&3
    if [ -x "$(command -v python3)" ]; then
        echo "# found python3 version $(python3 --version)" >&3
    else
        echo "# python3 not found" >&3
        exit 1
    fi

    echo "# checking node" >&3
    if [ -x "$(command -v node)" ]; then
        echo "# found node version $(node -v)" >&3
    else
        echo "# node not found" >&3
        exit 1
    fi

    # we need to be in the TEST_DIR to create the venv
    cd ${TEST_DIR}

    echo "# setting up venv" >&3
    if [ -d "./venv" ] && [ -n "${TEST_DIRTY_VENV}" ]; then
        echo "# venv reuse was requested and a venv is present" >&3
        echo "# reusing old venv" >&3
        . venv/bin/activate
        if [ $? -ne 0 ]; then
            echo "# unable to activate the existing venv" >&3
            exit 1
        fi
    else
        echo "# cleaning old venv" >&3
        rm -rf venv
        echo "# creating new venv" >&3
        python3 -m venv venv
        if [ $? -ne 0 ]; then
            echo "# unable to activate the new venv" >&3
            exit 1
        fi
        . venv/bin/activate
        if [ $? -ne 0 ]; then
            echo "# unable to activate the existing venv" >&3
            exit 1
        fi
        pip install -q -U pip setuptools wheel
        pip install ..
        if [ $? -ne 0 ]; then
            echo "# pip error installing the test package" >&3
            exit 1
        fi
    fi
        
    echo "# checking that pagecryptor is installed in the venv" >&3
    if [ -x "$(command -v pagecryptor)" ]; then
        echo "# found pagecryptor version $(pagecryptor --version)" >&3
    else
        echo "# something has gone wrong" >&3
        echo "# pagecryptor is not found in the venv" >&3
        exit 1
    fi

    echo "# cleaning old results" >&3
    rm -rf output
    mkdir -p output
}

setup() {
    # load helpers
    # assumes test helpers are located in specific relation to this test file
    load "./test_helper/bats-support/load"
    load "./test_helper/bats-assert/load"

    # ensure running in test directory
    cd "${TEST_DIR}"

    # at the beginning of the test we check to make sure we are not already
    # in a python venv. setup_file() creates and activates the venv we want
    # to use. so at this point we should be in a venv
    if [ -z "${VIRTUAL_ENV}" ]; then
        echo "# ERROR: the expected python venv is not active" >&3
        echo "# in the per-file setup(). something went wrong at the file level setup()" >&3
        exit 1
    fi

    # This bit finds the decrypt.js source file that is embedded in our package
    # this contains the same decrypt function that is used in the generated
    # encrypted web page. This function is used in the unit tests to verify
    # the decryption operates correctly
    DECRYPT_JS_PATH=$(python -c "import pagecryptor, pathlib; print(pathlib.Path(pagecryptor.__file__).parent / 'decrypt.js')")
    if [ -z "${DECRYPT_JS_PATH}" ]; then
        echo "# Error locating path to decrypt.js needed for testing."
        exit 1
    fi
}

# test files naming convention
#
# in "input" directory:
# - testN.html - original file to encrypt
# - testN.expected - what the decrypted file should match
# input files are part of the repo
#
# in the "output" directory:
# output files are generated at test time and are ephemeral
# - testN.html - encrypted html file
# - testN.json - parameters needed for decryption
# - testN.decoded - decrypted html page
#
# why is input .html and .expected different?
# original html is full html page with enclosing <html> and possible <DOCTYPE>
# these are stripped during encryption because the decrypted content is placed
# inside an <html> document
# the .expected files are the same as .html but with enclosing <html> removed
#

# use the pagecryptor python tool to encrypt a static html page
test_encrypt() {
    local testfile="$1"
    local testpass="$2"
    run pagecryptor "input/${testfile}.html" "output/${testfile}.html" --dump-json "output/${testfile}.json" --password "${testpass}"
    assert_success
}

# use the javascript decrypt function to decrypt a previously encrypted
# html page
test_decrypt() {
    local testfile="$1"
    local testpass="$2"
    run node test_decrypt.js "${DECRYPT_JS_PATH}" "output/${testfile}.json" "${testpass}" "output/${testfile}.decoded"
    assert_success
}

# compare the decrypted page with the original page.
# only the file root name is passed. a file naming convention is used
test_compare() {
    local testfile="$1"
    run diff "input/${testfile}.expected" "output/${testfile}.decoded"
    assert_success
}

# I have 5 files/test cases i want to run
# there is probably a better way to do this but for BATS I didnt see how to
# iterate in a loop and still get a separate test case for each file

# each of the 3 sets of test cases below operates on one html file.
# first the file is encrypted. then it is decrypted using the same javascript
# function that is embedded in the encrypted web page.
# finally, it compares the decrypted back to the original

# TEST1
@test "test1-encrypt" {
    test_encrypt "test1" 'foobar'
}
@test "test1-decrypt" {
    test_decrypt "test1" 'foobar'
}
@test "test1-compare" {
    test_compare "test1"
}

# TEST2
@test "test2-encrypt" {
    test_encrypt "test2" 'test123'
}
@test "test2-decrypt" {
    test_decrypt "test2" 'test123'
}
@test "test2-compare" {
    test_compare "test2"
}

# TEST3
@test "test3-encrypt" {
    test_encrypt "test3" 'Pa$$w0rd!'
}
@test "test3-decrypt" {
    test_decrypt "test3" 'Pa$$w0rd!'
}
@test "test3-compare" {
    test_compare "test3"
}

# TEST4
@test "test4-encrypt" {
    test_encrypt "test4" 'üñîçødë-Teßt'
}
@test "test4-decrypt" {
    test_decrypt "test4" 'üñîçødë-Teßt'
}
@test "test4-compare" {
    test_compare "test4"
}

# TEST5
@test "test5-encrypt" {
    test_encrypt "test5" 'ThisIsALongerPassword_ForTestingPurposesOnly123!'
}
@test "test5-decrypt" {
    test_decrypt "test5" 'ThisIsALongerPassword_ForTestingPurposesOnly123!'
}
@test "test5-compare" {
    test_compare "test5"
}

# in the original test1 encrypted page, the "msg" box should be empty
@test "empty-msg" {
    run egrep "<div id=\"msg\"></div>" "output/test1.html"
    assert_success
}

# now re-encrypt test1 but with a message, and verify it
@test "with-msg" {
    # same encrypt as before but include a message for the msg line
    run pagecryptor "input/test1.html" "output/test1m.html" --message "testmessage" --dump-json "output/test1m.json" --password "foobar"
    assert_success

    # make sure it decrypts okay
    test_decrypt "test1m" "foobar"
    run diff "input/test1.expected" "output/test1m.decoded"
    assert_success

    # now check for message in the msg field
    run egrep "<div id=\"msg\">testmessage</div>" output/test1m.html
    assert_success
}
