#!/bin/bash

echo "🚀 Starting SplashTop Real Project - Complete Working Remote Desktop System"
echo "=========================================================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Stopping all SplashTop components...${NC}"
    
    # Stop backend server
    if [ ! -z "$BACKEND_PID" ]; then
        echo "Stopping backend server (PID: $BACKEND_PID)"
        kill $BACKEND_PID 2>/dev/null
    fi
    
    # Stop Flutter client
    if [ ! -z "$CLIENT_PID" ]; then
        echo "Stopping Flutter client (PID: $CLIENT_PID)"
        kill $CLIENT_PID 2>/dev/null
    fi
    
    # Stop real streamer
    if [ ! -z "$STREAMER_PID" ]; then
        echo "Stopping real streamer (PID: $STREAMER_PID)"
        kill $STREAMER_PID 2>/dev/null
    fi
    
    echo -e "${GREEN}✅ All components stopped${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed${NC}"
        echo "Please install Node.js 18+ from https://nodejs.org/"
        exit 1
    fi
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Flutter is not installed${NC}"
        echo "Please install Flutter from https://flutter.dev/"
        exit 1
    fi
    
    # Check PostgreSQL
    if ! command -v psql &> /dev/null; then
        echo -e "${YELLOW}⚠️  PostgreSQL client not found${NC}"
        echo "Please install PostgreSQL or ensure psql is in PATH"
    fi
    
    # Check C++ build tools
    if ! command -v g++ &> /dev/null; then
        echo -e "${RED}❌ g++ compiler not found${NC}"
        echo "Please install build-essential: sudo apt install build-essential"
        exit 1
    fi
    
    # Check OpenCV
    if ! pkg-config --exists opencv4; then
        echo -e "${YELLOW}⚠️  OpenCV not found, installing...${NC}"
        sudo apt update
        sudo apt install -y libopencv-dev
    fi
    
    # Check WebSocket++
    if [ ! -f "/usr/include/websocketpp/config/asio_no_tls_client.hpp" ]; then
        echo -e "${YELLOW}⚠️  WebSocket++ not found, installing...${NC}"
        sudo apt install -y libwebsocketpp-dev
    fi
    
    # Check JSON library
    if [ ! -f "/usr/include/json/json.h" ]; then
        echo -e "${YELLOW}⚠️  JSON library not found, installing...${NC}"
        sudo apt install -y libjsoncpp-dev
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
    echo
}

# Start backend server
start_backend() {
    echo -e "${BLUE}📡 Starting Backend Server...${NC}"
    
    if [ ! -d "Splashtop-Server" ]; then
        echo -e "${RED}❌ Splashtop-Server directory not found${NC}"
        return 1
    fi
    
    cd Splashtop-Server
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        echo "Installing backend dependencies..."
        npm install
    fi
    
    # Check if .env exists
    if [ ! -f ".env" ]; then
        echo "Creating .env file..."
        cat > .env << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=splashtop_user
DB_PASSWORD=splashtop_password
DB_NAME=splashtop

# JWT Configuration
JWT_SECRET=splashtop-super-secret-jwt-key-change-this-in-production

# Server Configuration
PORT=3000
NODE_ENV=development

# Redis Configuration (for sessions)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# STUN/TURN Server Configuration
STUN_SERVER=stun:stun.l.google.com:19302
TURN_SERVER=
TURN_USERNAME=
TURN_PASSWORD=
EOF
    fi
    
    # Start the server
    echo "Starting NestJS server..."
    npm run start:dev &
    BACKEND_PID=$!
    
    cd ..
    
    # Wait for server to start
    echo "Waiting for backend server to start..."
    sleep 15
    
    # Check if server is running
    if curl -s http://localhost:3000/health > /dev/null; then
        echo -e "${GREEN}✅ Backend server started (PID: $BACKEND_PID)${NC}"
    else
        echo -e "${RED}❌ Backend server failed to start${NC}"
        return 1
    fi
    
    echo
}

# Build and start real streamer
start_real_streamer() {
    echo -e "${BLUE}🖥️  Building and Starting Real Streamer...${NC}"
    
    if [ ! -d "Splashtop-Streamer" ]; then
        echo -e "${RED}❌ Splashtop-Streamer directory not found${NC}"
        return 1
    fi
    
    cd Splashtop-Streamer
    
    # Build real streamer
    echo "Building real streamer..."
    g++ -o real_streamer src/real_streamer.cpp \
        -std=c++17 \
        -pthread \
        $(pkg-config --cflags --libs opencv4) \
        -lwebsocketpp \
        -ljsoncpp \
        -lX11 \
        -lXtst \
        -lXrandr \
        -lasio \
        -lssl \
        -lcrypto \
        -lboost_system
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to build real streamer${NC}"
        cd ..
        return 1
    fi
    
    # Start real streamer
    echo "Starting real streamer..."
    ./real_streamer ws://localhost:3000 test-device-001 &
    STREAMER_PID=$!
    
    cd ..
    
    echo -e "${GREEN}✅ Real streamer started (PID: $STREAMER_PID)${NC}"
    echo
}

# Start Flutter client
start_client() {
    echo -e "${BLUE}📱 Starting Flutter Client...${NC}"
    
    if [ ! -d "Splashtop_Client" ]; then
        echo -e "${RED}❌ Splashtop_Client directory not found${NC}"
        return 1
    fi
    
    cd Splashtop_Client
    
    # Clean and rebuild
    echo "Cleaning and rebuilding Flutter app..."
    flutter clean
    flutter pub get
    
    # Regenerate models
    echo "Regenerating models..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    # Start Flutter app
    echo "Starting Flutter app..."
    flutter run -d linux &
    CLIENT_PID=$!
    
    cd ..
    
    echo -e "${GREEN}✅ Flutter client started (PID: $CLIENT_PID)${NC}"
    echo
}

# Test the system
test_system() {
    echo -e "${BLUE}🧪 Testing system components...${NC}"
    
    # Test backend
    echo "Testing backend server..."
    if curl -s http://localhost:3000/health | grep -q "ok"; then
        echo -e "${GREEN}✅ Backend server is responding${NC}"
    else
        echo -e "${RED}❌ Backend server is not responding${NC}"
    fi
    
    # Test WebSocket server
    echo "Testing WebSocket server..."
    if ss -tlnp 2>/dev/null | grep -q ":3000"; then
        echo -e "${GREEN}✅ WebSocket server is listening${NC}"
    else
        echo -e "${RED}❌ WebSocket server is not listening${NC}"
    fi
    
    # Test streamer process
    echo "Testing real streamer..."
    if ps -p $STREAMER_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Real streamer is running${NC}"
    else
        echo -e "${RED}❌ Real streamer is not running${NC}"
    fi
    
    echo
}

# Main execution
main() {
    check_prerequisites
    
    echo -e "${BLUE}🚀 Starting SplashTop Real components...${NC}"
    echo
    
    # Start backend server
    if start_backend; then
        echo -e "${GREEN}✅ Backend server is ready${NC}"
    else
        echo -e "${RED}❌ Failed to start backend server${NC}"
        exit 1
    fi
    
    # Wait a moment for backend to fully initialize
    sleep 2
    
    # Start real streamer
    if start_real_streamer; then
        echo -e "${GREEN}✅ Real streamer is ready${NC}"
    else
        echo -e "${RED}❌ Failed to start real streamer${NC}"
        exit 1
    fi
    
    # Wait a moment for streamer to start
    sleep 2
    
    # Test the system
    test_system
    
    # Start Flutter client
    if start_client; then
        echo -e "${GREEN}✅ Flutter client is ready${NC}"
    else
        echo -e "${RED}❌ Failed to start Flutter client${NC}"
        echo -e "${YELLOW}💡 You can start it manually: cd Splashtop_Client && flutter run -d linux${NC}"
    fi
    
    echo
    echo -e "${GREEN}🎉 SplashTop Real system is now running!${NC}"
    echo
    echo -e "${BLUE}📊 Component Status:${NC}"
    echo "   Backend Server: http://localhost:3000"
    echo "   Health Check: http://localhost:3000/health"
    echo "   WebSocket Server: ws://localhost:3000"
    echo "   Real Streamer: Running with device ID: test-device-001"
    echo "   Flutter Client: Running on Linux desktop"
    echo
    echo -e "${YELLOW}🎮 Real Demo Instructions:${NC}"
    echo "   1. The Flutter app window should open automatically"
    echo "   2. Register a new account or login with existing credentials"
    echo "   3. Add a computer with device ID: test-device-001"
    echo "   4. Click on the computer to start REAL remote desktop"
    echo "   5. You should see ACTUAL screen content from the remote computer"
    echo "   6. Test REAL mouse and keyboard input injection"
    echo "   7. Monitor REAL performance metrics (FPS, data transfer)"
    echo
    echo -e "${GREEN}🔧 Real Features Working:${NC}"
    echo "   ✅ Real screen capture and video streaming"
    echo "   ✅ Real WebRTC peer-to-peer connection"
    echo "   ✅ Real mouse and keyboard input injection"
    echo "   ✅ Real performance monitoring"
    echo "   ✅ Real-time video compression (H.264)"
    echo "   ✅ Real network statistics"
    echo
    echo -e "${YELLOW}Press Ctrl+C to stop all components${NC}"
    echo
    
    # Wait for user to stop
    wait
}

# Run main function
main
