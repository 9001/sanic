#!/bin/bash
set -e

rm -f -- *.js avc.*

wget -nc \
  https://mbebenita.github.io/Broadway/{Decoder,YUVCanvas,Player,stream}.js \
  https://mbebenita.github.io/Broadway/avc.{wasm,wast,temp.asm.js} || true

sed -ri 's`"(avc\.)(wasm|wast|temp\.asm\.js)"`"broadway/\1\2"`g' Decoder.js
