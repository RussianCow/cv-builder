#!/bin/sh

echo "Watching for changes..."
watchmedo shell-command -W -c 'python builder.py data.yaml' -i './out/'
