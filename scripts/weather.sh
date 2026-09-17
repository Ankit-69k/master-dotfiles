#!/bin/bash

# Output my currect location weather

weather=$(curl -sf --retry 5 --retry-delay 1 --max-time 2 'wttr.in/?format=1' 2>/dev/null | tr -s " ")

echo "${weather:-Weather N/A}"
