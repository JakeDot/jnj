#!/bin/bash
set -e

echo "[Jules Wrapper] Building Flutter web application..."
flutter build web

echo "[Jules Wrapper] Creating .nojekyll and 404.html for GitHub Pages..."
touch build/web/.nojekyll
cp build/web/index.html build/web/404.html

echo "[Jules Wrapper] Syncing Flutter web build to Android app assets..."
mkdir -p android/app/src/main/assets/web
cp -r build/web/* android/app/src/main/assets/web/

echo "[Jules Wrapper] Done! The Android wrapper app is now packaged with the latest Flutter web build."
