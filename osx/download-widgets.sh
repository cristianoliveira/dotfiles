#!/bin/bash

echo ">> Widgets"
for widget in $(cat apps/widgets | cut -d'=' -f2 | tr '\n' ' ')
do
  echo "Downloading $(basename $widget)"
  curl -# $widget > ~/Downloads/$(basename $widget)
done
