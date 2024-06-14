#!/bin/bash
# Copy configuration files
rm -rf "$HOME/.config/relish/"
mkdir -p "$HOME/.config/relish/"
cp Resources/relishformat.config "$HOME/.config/relish/.relishformat"
cp -r Resources/xcodeproj_verifications "$HOME/.config/relish/xcodeproj_verifications"
cp Resources/Verifications.json "$HOME/.config/relish/Verifications.json"
cp Resources/violations.swiftlint.yml "$HOME/.config/relish/.violations.swiftlint.yml"

# Print messages
echo "Installed"
echo "Please copy Resources/Relish.plist to your project root folder"
echo "Change path to your projects in Relish.plist"

