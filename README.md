# dminjs

An ES2015 compliant JavaScript minifier written in D. While it only strips out comments and excess whitespace, it is very fast and low memory since it only needs to read one line at a time, and parses the code in a single pass.

## Dependencies

* dmd v2.077.0
* POSIX compatible operating system (because of usage of `isatty` function and `make`)

## Installation

* Clone or download this repository
* `cd` into the project folder and run `make`

## Usage

(Assumes you have already run `make`) Either specify an input file (`./bin/dminjs app.js > app.min.js`) or pipe the files into dminjs (`cat app1.js app2.js | ./bin/dminjs > app.min.js`)

## Caveats

* Only removes comments and excess whitespace (does not rename long variables or prune unused code)
* Might not work correctly if you use newlines instead of semicolons to end statements

## License

dminjs is released under the MIT License. See license.txt for more details.