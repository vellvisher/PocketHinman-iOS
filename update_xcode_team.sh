#!/bin/bash

# Check if the script is called with at least one parameter
if [ $# -eq 0 ]; then
  echo "Usage: $0 <DEVELOPMENT_TEAM>"
  exit 1
fi

# Store the DEVELOPMENT_TEAM value from the first parameter
new_team=$1

# Find all the project.pbxproj files in the current directory and its subdirectories
files=$(find . -name "project.pbxproj")

# Iterate over the files and replace the DEVELOPMENT_TEAM template
for file in $files; do
  # Use sed to perform the replacement
  sed -i '' -e "s/\$DEVELOPMENT_TEAM/$new_team/g" "$file"
  echo "Updated $file"
done
