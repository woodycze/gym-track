#!/bin/bash
set -e

echo "Installing Flutter dependencies..."
flutter pub get

echo "Building web version for production..."
flutter build web --release

echo "Build completed! Check build/web folder."
ls -la build/web/ 