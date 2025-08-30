#!/bin/bash

echo "🚀 SplashTop Test Runner"
echo "======================="
echo

# Function to cleanup on exit
cleanup() {
    echo "🛑 Stopping all processes..."
    pkill -f test_streamer
    pkill -f flutter
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

echo "📡 Starting Streamer..."
cd ../Splashtop-Streamer
./test_streamer &
STREAMER_PID=$!
echo "Streamer started with PID: $STREAMER_PID"

# Wait a moment for streamer to start
sleep 2

echo "📱 Starting Flutter Client..."
cd ../Splashtop_Client
flutter run -d linux &
FLUTTER_PID=$!
echo "Flutter client started with PID: $FLUTTER_PID"

echo
echo "✅ Both components are running!"
echo "   - Streamer: PID $STREAMER_PID (localhost:8080)"
echo "   - Client: PID $FLUTTER_PID (Flutter app)"
echo
echo "🎮 Test Instructions:"
echo "   1. Look for the Flutter app window"
echo "   2. Click 'Connect' button"
echo "   3. Test the input buttons (Mouse, Keyboard, Scroll)"
echo "   4. Press Ctrl+C to stop everything"
echo

# Wait for user to stop
wait
