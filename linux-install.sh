#!/usr/bin/env bash

set -e  # fail on error
set -u # do not allow unset variables

cd linux

echo "\n\n\n\n\n----------------------Running scripts-------------------\n\n\n\n\n"
bash ./scripts-install.sh

echo "Setup linux machine"
bash ./setup.sh
