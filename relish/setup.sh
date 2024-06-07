#!/bin/bash

swift build -c release
cp -f .build/release/relish /opt/homebrew/bin/
cp Resources/relishformat.config ~/.relishformat
