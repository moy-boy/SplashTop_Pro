#!/bin/bash

echo "🚀 Starting SplashTop with Working Authentication..."

# Kill any existing processes
echo "🔄 Stopping existing processes..."
pkill -f "npm run start:dev" 2>/dev/null || true
pkill -f "node.*dist/main" 2>/dev/null || true
sleep 2

# Start backend
echo "🔧 Starting backend server..."
cd Splashtop-Server
npm run start:dev &
BACKEND_PID=$!
cd ..

# Wait for backend to start
echo "⏳ Waiting for backend to start..."
sleep 10

# Test backend health
echo "🏥 Testing backend health..."
for i in {1..5}; do
    if curl -s http://localhost:3000/health > /dev/null; then
        echo "✅ Backend is healthy!"
        break
    else
        echo "⏳ Backend not ready yet, retrying... ($i/5)"
        sleep 3
    fi
done

# Test authentication
echo "🔐 Testing authentication..."
cd Splashtop_Client
dart test_auth.dart
cd ..

# Start streamer
echo "📺 Starting streamer..."
cd Splashtop-Streamer
if [ -f "build/real_streamer" ]; then
    ./build/real_streamer &
    STREAMER_PID=$!
    echo "✅ Streamer started (PID: $STREAMER_PID)"
else
    echo "⚠️ Streamer not built, building now..."
    mkdir -p build
    cd build
    cmake ..
    make
    cd ..
    ./build/real_streamer &
    STREAMER_PID=$!
    echo "✅ Streamer built and started (PID: $STREAMER_PID)"
fi
cd ..

# Start Flutter app
echo "📱 Starting Flutter app..."
cd Splashtop_Client
flutter run -d linux &
FLUTTER_PID=$!
cd ..

echo ""
echo "🎉 SplashTop is now running!"
echo ""
echo "📊 Process Status:"
echo "   Backend: PID $BACKEND_PID (http://localhost:3000)"
echo "   Streamer: PID $STREAMER_PID (port 8080)"
echo "   Flutter: PID $FLUTTER_PID"
echo ""
echo "🔑 Login Credentials:"
echo "   Email: test@example.com"
echo "   Password: password123"
echo ""
echo "🛑 To stop all services, run: pkill -f 'npm run start:dev' && pkill -f 'real_streamer' && pkill -f 'flutter run'"
echo ""

# Wait for user input to stop
read -p "Press Enter to stop all services..."
echo "🛑 Stopping all services..."
kill $BACKEND_PID 2>/dev/null || true
kill $STREAMER_PID 2>/dev/null || true
kill $FLUTTER_PID 2>/dev/null || true
pkill -f "npm run start:dev" 2>/dev/null || true
pkill -f "real_streamer" 2>/dev/null || true
pkill -f "flutter run" 2>/dev/null || true
echo "✅ All services stopped."

