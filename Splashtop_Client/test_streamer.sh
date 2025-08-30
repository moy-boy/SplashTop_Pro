#!/bin/bash

echo "🚀 SplashTop Streamer & Client Test Script"
echo "=========================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Please run this script from the Splashtop_Client directory"
    exit 1
fi

echo "📦 Installing Flutter dependencies..."
flutter pub get

echo ""
echo "🔧 Building the Flutter app..."
flutter build linux --debug

echo ""
echo "🎯 Starting the Flutter client..."
echo "   The app will open and you can click 'Connect' to test with your streamer"
echo "   Make sure your streamer is running on localhost:8080"
echo ""

# Run the Flutter app
flutter run -d linux
