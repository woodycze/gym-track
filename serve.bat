@echo off
echo Building web version...
flutter build web

echo Starting local server...
cd build/web
python -m http.server 8080

echo Web app is running at: http://localhost:8080
echo Press Ctrl+C to stop 