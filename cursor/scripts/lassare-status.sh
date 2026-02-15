#!/bin/bash
if [ -f ".lassare/mode.txt" ]; then
  echo "Mode: $(cat .lassare/mode.txt | tr -d '[:space:]')"
else
  echo "Mode: inline (default)"
fi
