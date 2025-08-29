# pagecryptor

`pagecryptor` is a command-line tool for generating encrypted HTML pages that
can be decrypted directly in the browser. It encrypts the contents of a
complete HTML file, including `<head>` and `<body>`, and produces a standalone
HTML page that prompts for a password and displays the original content upon
successful decryption. All decryption happens in the browser; no data is sent
over the network.

## License

This project is licensed under the MIT License. See the
[LICENSE.md](./LICENSE.md) file for details.

## Installing

You can install `pagecryptor` directly from the GitHub repository using pip:

```bash
pip install git+https://github.com/yourusername/pagecryptor.git
```

*(Replace the URL with the actual repository URL.)*

## Usage

Command line help:

```
usage: pagecryptor.py [-h] [--dump-json JSONFILE] [--password PASSWORD] [--version] input_html output_html

Generate encrypted HTML page

positional arguments:
  input_html            HTML page to encrypt
  output_html           Encrypted HTML file with client side decrypt

options:
  -h, --help            Show this help message and exit
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

## Development and Testing

* Development environment requirements:

  * Python 3.x
  * Node.js (for testing the decryption in JavaScript)
  * Other tools: \[fill in later]

* Common development tasks are automated via the included Makefile. Use:

```bash
make help
```

to see available commands.

* Test scripts and test cases are located in the `tests` directory. You can run
  the tests using the Makefile:

```bash
make test
```

