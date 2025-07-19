#!/bin/bash
echo "Installing Flutter dependencies..."
flutter pub get

echo "Building web version..."
flutter build web

echo "Build completed! Check build/web folder." 