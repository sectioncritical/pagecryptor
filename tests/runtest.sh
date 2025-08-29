#!/usr/bin/env bash

check_exit() {
    local exit_code=$1
    local message=$2
    if [ "$exit_code" -ne 0 ]; then
        echo "$message"
        exit 1
    fi
}

# process command line args

if [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "Usage:"
    echo "  runtest.sh [-d]"
    echo "  runtest.sh [-h | --help]"
    exit 0
fi

# "dirty" allows to reuse previous venv, to avoid constant rebuilding
# in development. for a real test, dirty should not be used
if [ "$1" == "-d" ]
then
    dirty=1
fi

# figure out paths we need

SCRIPT_DIR="$(dirname $(realpath $0))"
VENV="$(realpath ${SCRIPT_DIR}/../venv)"

printf "Starting pagecryptor test ...\n"
date "+%Y-%m-%d% %H:%M:%S"

cd $SCRIPT_DIR

# do some initial checks

# make sure not already in a venv
if [ -n "${VIRTUAL_ENV}" ]
then
    printf "A virtual environment is already active.\n"
    printf "Deactivate it first before running this test script.\n"
    exit 1
fi

printf "Checking python3: "
if [ -x "$(command -v python3)" ]
then
    printf "%s\n" "$(python3 --version)"
else
    printf "not found\n"
    exit 1
fi

printf "Checking node: "
if [ -x "$(command -v node)" ]
then
    printf "%s\n" "$(node -v)"
else
    printf "not found\n"
    exit 1
fi

# allow use of existing venv if it is there and the user asked for it
# this saves on needing to constantly rebuild the venv during development

if [ -d "./venv" ] && [ -n "$dirty" ]
then
    printf -- "-d (dirty) was requested and it appears there is a venv\n"
    printf "therefore I will skip making a new venv\n"
    . venv/bin/activate
    check_exit $? "Could not activate the venv for some reason."
else
    # clean old  venv and create a new one
    printf "Cleaning old venv\n"
    rm -rf venv
    printf "Creating new venv\n"
    printf "********************\n"
    python3 -m venv venv
    . venv/bin/activate
    check_exit $? "Could not activate the venv for some reason."
    pip install -q -U pip setuptools wheel
    pip install ..
    check_exit $? "pip error installing the test package"
    printf "********************\n"
fi

# venv has been activated so all python commands from here are using venv

# validate our module actually was installed in the venv

printf "Checking pagecryptor is installed: "
if [ -x "$(command -v pagecryptor)" ]
then
    printf "%s\n" "$(pagecryptor --version)"
else
    printf "Something went wrong. pagecryptor should be present in the\n"
    printf "python virtual environment but doesn't seem to be there.\n"
    exit 1
fi

printf "Clean old results\n"
rm -rf output
mkdir -p output

# start running test:
# generate encrypted page from test files in ./input/
# run the decrypt test, verify ok
# diff the decrypted output against the input

DECRYPT_JS_PATH=$(python -c "import pagecryptor, pathlib; print(pathlib.Path(pagecryptor.__file__).parent / 'decrypt.js')")
if [ -z "${DECRYPT_JS_PATH}" ]
then
    echo "Error locating path to decrypt.js needed for testing."
    exit 1
fi

testlist=(  "test1" "foobar"        \
            "test2" "test123"       \
            "test3" "Pa$$w0rd!"     \
            "test4" "üñîçødë-Teßt"  \
            "test5" "ThisIsALongerPassword_ForTestingPurposesOnly123!")

for ((i=0; i<${#testlist[@]}; i+=2))
do
    testfile="${testlist[i]}"
    testpass="${testlist[i+1]}"
    echo "Testing [$testfile] using password [$testpass]"
    echo "encrypting ..."
    pagecryptor "input/${testfile}.html" "output/${testfile}.html" --dump-json "output/${testfile}.json" --password "${testpass}"
    check_exit $? "Error encrypting the web page"
    echo "decrypting ..."
    node test_decrypt.js "${DECRYPT_JS_PATH}" "output/${testfile}.json" "${testpass}" "output/${testfile}.decoded"
    check_exit $? "Error decrypting the web page"
    echo "diffing ..."
    diff "input/${testfile}.expected" "output/${testfile}.decoded"
    check_exit $? "Decrypted web page does not match"
done

echo "Test completed with no errors"
