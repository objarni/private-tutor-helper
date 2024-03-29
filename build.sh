#!/bin/bash
set -e
mkdir -p output/js
elm make src/Main.elm --output=output/js/app.js
cp src/index.html output
cp src/*.py output
