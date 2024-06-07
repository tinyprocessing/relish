#!/bin/bash

swift build -c release
cp -f .build/release/relish /opt/homebrew/bin/
cp Resources/relishformat.config ~/.relishformat
rm -rf ~/relish/
mkdir ~/relish/
cp -r Resources/xcodeproj_verifications ~/relish/xcodeproj_verifications
echo "Installed"
