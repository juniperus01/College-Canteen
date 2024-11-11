#!/bin/bash

# Install Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Run Flutter doctor to ensure everything is set up
flutter doctor

# Get Flutter dependencies
flutter pub get

# Build Flutter web app
flutter build web
