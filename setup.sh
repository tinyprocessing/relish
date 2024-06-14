#!/bin/bash

swift build -c release
cp -f .build/release/relish /opt/homebrew/bin/
rm -rf ~/.config/relish/
cp -rf relish ~/.config/
echo "Please copy Resources/Relish.plist to your project root folder"
echo "Change path to your projects in Relish.plist"
