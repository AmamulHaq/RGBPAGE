#!/bin/bash

# Check if RGB values are provided as arguments
if [ -z "$1" ]; then
    echo "Error: No RGB values provided."
    exit 1
fi

# Pass the RGB values to the Python script
echo "Starting generate_rgb_cube.py..."
python3 /home/amamul/Desktop/page/page1/python/generate_rgb_cube.py "$1"

# Start the Flutter app
echo "Starting Flutter app..."
flutter run
