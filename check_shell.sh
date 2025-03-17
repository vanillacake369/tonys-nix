#!/bin/bash

# Define a function that returns 0 (true) if $SHELL contains "zsh"
is_zsh() {
  [[ "$SHELL" == *"zsh"* ]]
}

# Use the function and echo a boolean result
if is_zsh; then
  echo "true"
else
  echo "false"
fi
