#!/bin/bash
convert ../../graphic-assets/alternate_colors/BRO_3000_3000.png -brightness-contrast -10 -background gray80 -flatten -quality 30 src/assets/BRO_bg.jpg
cp ../../graphic-assets/basic/BRO_64_64.png src/assets/BRO_64_64.png
cp ../../graphic-assets/alternate/BRO_64_64.png public/favicon.png
