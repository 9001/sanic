#!/bin/bash
set -e

rm -f -- *.js *.html

wget -nc https://github.com/phoboslab/jsmpeg/raw/master/{jsmpeg.min.js,view-stream.html}

# JSMpeg.WASM_BINARY_INLINED="
