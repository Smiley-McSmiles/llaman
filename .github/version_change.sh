#!/bin/bash
currentVersion=$(head -n 10 ../llaman.1 | grep -o "[0-9].[0-9].[0-9]")
echo "Current version is v$currentVersion"
echo
echo "Please enter the new version number"
echo "EXAMPLE: $currentVersion"
read newVersion

sed -i "s|v$currentVersion|v$newVersion|g" ../README.md
sed -i "s|v$currentVersion|v$newVersion|g" ../llaman.1
sed -i "s|$currentVersion|$newVersion|g" ../scripts/llaman
sed -i "s|$currentVersion|$newVersion|g" ../setup.sh
