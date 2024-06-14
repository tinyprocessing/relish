#!/bin/bash

swift build -c release
cp -f .build/release/relish /opt/homebrew/bin/
rm -rf ~/.config/relish/
mkdir ~/.config/relish/
cp Resources/relishformat.config ~/.config/relish/.relishformat
cp -r Resources/xcodeproj_verifications ~/.config/relish/xcodeproj_verifications
cp Resources/Verifications.json ~/.config/relish/Verifications.json
cp Resources/violations.swiftlint.yml ~/.config/relish/.violations.swiftlint.yml
echo "Installed"
echo "Please copy Resources/Relish.plist to your project root folder"
echo "Change path to your projects in Relish.plist"
