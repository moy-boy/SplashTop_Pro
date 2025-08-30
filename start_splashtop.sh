#!/bin/bash

echo "🚀 Starting SplashTop Remote Desktop System"
echo "=========================================="
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
    
    # Stop streamer
    if [ ! -z "$STREAMER_PID" ]; then
        echo "Stopping streamer (PID: $STREAMER_PID)"
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
        echo "Creating .env file from template..."
        cp env.example .env
        echo -e "${YELLOW}⚠️  Please edit .env file with your database credentials${NC}"
    fi
    
    # Start the server
    echo "Starting NestJS server..."
    npm run start:dev &
    BACKEND_PID=$!
    
    cd ..
    
    # Wait for server to start
    echo "Waiting for backend server to start..."
    sleep 5
    
    # Check if server is running
    if curl -s http://localhost:3000 > /dev/null; then
        echo -e "${GREEN}✅ Backend server started (PID: $BACKEND_PID)${NC}"
    else
        echo -e "${RED}❌ Backend server failed to start${NC}"
        return 1
    fi
    
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
    
    # Get dependencies
    echo "Getting Flutter dependencies..."
    flutter pub get
    
    # Generate JSON models
    echo "Generating JSON models..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    # Start Flutter app
    echo "Starting Flutter app..."
    flutter run -d linux &
    CLIENT_PID=$!
    
    cd ..
    
    echo -e "${GREEN}✅ Flutter client started (PID: $CLIENT_PID)${NC}"
    echo
}

# Start C++ streamer
start_streamer() {
    echo -e "${BLUE}🖥️  Starting C++ Streamer...${NC}"
    
    if [ ! -d "Splashtop-Streamer" ]; then
        echo -e "${RED}❌ Splashtop-Streamer directory not found${NC}"
        return 1
    fi
    
    cd Splashtop-Streamer
    
    # Check if streamer is built
    if [ ! -f "test_streamer" ]; then
        echo "Building streamer..."
        g++ test_streamer.cpp -o test_streamer
    fi
    
    # Start streamer
    echo "Starting streamer..."
    ./test_streamer &
    STREAMER_PID=$!
    
    cd ..
    
    echo -e "${GREEN}✅ Streamer started (PID: $STREAMER_PID)${NC}"
    echo
}

# Main execution
main() {
    check_prerequisites
    
    echo -e "${BLUE}🚀 Starting SplashTop components...${NC}"
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
    
    # Start Flutter client
    if start_client; then
        echo -e "${GREEN}✅ Flutter client is ready${NC}"
    else
        echo -e "${RED}❌ Failed to start Flutter client${NC}"
        exit 1
    fi
    
    # Start streamer
    if start_streamer; then
        echo -e "${GREEN}✅ Streamer is ready${NC}"
    else
        echo -e "${RED}❌ Failed to start streamer${NC}"
        exit 1
    fi
    
    echo
    echo -e "${GREEN}🎉 SplashTop system is now running!${NC}"
    echo
    echo -e "${BLUE}📊 Component Status:${NC}"
    echo "   Backend Server: http://localhost:3000"
    echo "   Flutter Client: Running on Linux desktop"
    echo "   C++ Streamer: Running on localhost:8080"
    echo
    echo -e "${YELLOW}🎮 Next Steps:${NC}"
    echo "   1. Open the Flutter app window"
    echo "   2. Register a new account or login"
    echo "   3. Add a computer (use device ID: test-device-001)"
    echo "   4. Connect to the streamer"
    echo "   5. Test remote desktop functionality"
    echo
    echo -e "${YELLOW}Press Ctrl+C to stop all components${NC}"
    echo
    
    # Wait for user to stop
    wait
}

# Run main function
main
