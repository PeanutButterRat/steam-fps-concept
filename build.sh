PTH=~/Dev/build
FOLDER=testing
PATCH=0
MINOR=2
MAJOR=0

godot --export "Windows Steam" PTH/$FOLDER/duel.exe --path ./project.godot
read -p "Press [Enter] to continue..."