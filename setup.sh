#!/bin/bash

swift build -c release
cp -f .build/release/relish /opt/homebrew/bin/
rm -rf ~/relish/
mkdir ~/relish/
cp Resources/relishformat.config ~/relish/.relishformat
cp -r Resources/xcodeproj_verifications ~/relish/xcodeproj_verifications
cp Resources/Verifications.json ~/relish/Verifications.json
cp Resources/violations.swiftlint.yml ~/relish/.violations.swiftlint.yml
echo "Installed"
echo "Please copy Resources/Relish.plist to your project root folder"
