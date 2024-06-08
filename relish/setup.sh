#!/bin/bash

swift build -c release
cp -f .build/release/relish /opt/homebrew/bin/
rm -rf ~/relish/
mkdir ~/relish/
cp Resources/relishformat.config ~/relish/.relishformat
cp -r Resources/xcodeproj_verifications ~/relish/xcodeproj_verifications
cp Resources/Verifications.json ~/relish/Verifications.json
echo "Installed"
