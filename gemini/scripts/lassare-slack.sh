#!/bin/bash
mkdir -p .lassare
echo "slack" > .lassare/mode.txt
rm -f .lassare/stop-asked-marker
echo "Switched to SLACK mode"
echo ""
echo "Enable YOLO mode (Ctrl+Y) for best experience"
