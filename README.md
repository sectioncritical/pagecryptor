# PageCryptor

`pagecryptor` is a command-line tool for generating encrypted HTML pages that
can be decrypted directly in the browser. It encrypts the contents of a
complete HTML file, including `<head>` and `<body>`, and produces a standalone
HTML page that prompts for a password and displays the original content upon
successful decryption. All decryption happens in completely local in the
browser. The decrypted web page does not leave your computer.

## License

This project is licensed under the MIT License. See the
[LICENSE.md](./LICENSE.md) file for details.

## Rationale

I know there already exist some tools similar to this. I made this just for my
own entertainment and learning. My use case is that I want to be able to store
some secret in a way that can be retrievable by a web browser anywhere. This
method does not require you to download an encrypted file from a sharing
service (Dropbox for example) and then run a program to decrypt it locally.
Although I admit that's exactly what this does except it is all contained in
your browser.

## Security

I am not a security expert. This encryption method uses AES-GCM and I think I
am using it correctly. But I don't know much about it and my expert consultants
was "the internet".

**USE AT YOUR OWN RISK**

## How it Works

First you prepare the secret content in an HTML page. Perhaps your grocery list
that you only want to read on your phone in the grocery store. This should be
a complete static and valid HTML page that you can view locally in your own
browser prior to encryption. The web page can have styling, but do not bother
to put any script in there, it will not run.

Once you have your web page ready to go, you use the `pagecryptor` tool to
encrypt it. When you run the tool, it will ask you for a password. This is the
same password you will use to decrypt the page, and it should be a "strong"
password.

The result will be a new web page that simply shows a password box. All of your
original page is stored in this new page in encrypted form. The encrypted page
contains a javascript function that will decrypt it after you enter your
password. If the decryption is successful, it completely replaces the
"password" page with your original page that has now been decrypted.

When you entered your password, it was only used by the script function running
in your browser. It is not transmitted to any server. If you close the browser
tab, when you visit the page again, you will see the password page again.

## Installing

I recommend you install this tool using pip, directly from the GitHub
repository. At the time of this writing, I have not made this available on
PyPi. I also recommend that you use a python virtual environment for all your
pip-installing needs. I use `python -m venv` but there are several ways to
manage python environments.

This tool requires Python 3.9 or later.

```bash
# create the python virtual environment
python3 -m venv venv
# activate the venv
. venv/bin/activate
# install pagecryptor
pip install git+https://github.com/sectioncritical/pagecryptor.git
```

## Usage

Command line help:

```
usage: pagecryptor [-h] [-m MESSAGE] [--dump-json JSONFILE]
                   [--password PASSWORD] [--version]
                   input_html output_html

Generate encrypted HTML page

positional arguments:
  input_html            HTML page to encrypt
  output_html           Encrypted HTML file with client side decrypt

options:
  -h, --help            Show this help message and exit
  -m MESSAGE, --message MESSAGE
                        Optional brief message or instruction
  --dump-json JSONFILE  Write encryption parms to JSON file (for test)
  --password PASSWORD   Encryption password (insecure, test only)
  --version             show program's version number and exit

The input HTML file should be a complete HTML file with <head> and <body>. For
security, do not use --password to specify the password. Instead, let the
program ask you for the encryption password. The resulting output file is a
standalone HTML page you can open in a browser. It will ask for the password,
and if correct, will decrypt and display your original page. All decryption
occurs in the browser, nothing is sent off your machine.
```

Example:

```bash
pagecryptor input.html output.html
```

This will prompt you for a password and generate `output.html` as a
self-contained encrypted page.

If you use the optional `--message` option, you can show a brief message that
will appear under the password box.

## Development and Testing

In case you want to develop or test this on your own, you can clone the repo
and use the Makefile to perform some common tasks.

For your development environment you need a "typical" posix-like system with
the usual tools, such as the following probably incomplete list:

* git
* make
* bash - test script uses bashisms
* diff
* python 3.9 or greater, with pip and venv
* node (was tested with 22.18, not sure about older versions)
* generate example

Some things you can do with the Makefile:

* build python dist package
* run the tests
* perform some quality checks (lint)

You can get some help:

```bash
make help
```
