#!/bin/bash
# GODOT_BUILD_LOCATION is a environment variable set beforehand.
EXPORT_PRESET_NAME="Windows"
VERSION_NAME="beta"

# Semantic versioning numbers.
read -p "[MAJOR Version]: " MAJOR
read -p "[MINOR Version]: " MINOR
read -p "[PATCH Number] : " PATCH

godot --path .\project.godot --export $EXPORT_PRESET_NAME --no-window

FOLDER=$MAJOR.$MINOR.$PATCH.$VERSION_NAME
cd $GODOT_BUILD_LOCATION

mkdir $FOLDER

cp ./dependencies/* $FOLDER
mv ./bin/* $FOLDER
7z a ./$FOLDER.zip ./$FOLDER

read -p "Press any key to continue."
