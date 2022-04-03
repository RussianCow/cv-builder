#!/bin/sh

echo "Watching for changes..."
watchmedo shell-command -c 'python builder.py data.yaml' -i './out.html;*.css'
