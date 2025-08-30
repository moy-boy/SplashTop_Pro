#!/bin/bash

echo "🚀 Starting SplashTop MVP - Complete Remote Desktop System"
echo "=========================================================="
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
    sleep 10
    
    # Check if server is running
    if curl -s http://localhost:3000/health > /dev/null; then
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

# Start simple streamer
start_streamer() {
    echo -e "${BLUE}🖥️  Starting Simple Streamer...${NC}"
    
    if [ ! -d "Splashtop-Streamer" ]; then
        echo -e "${RED}❌ Splashtop-Streamer directory not found${NC}"
        return 1
    fi
    
    cd Splashtop-Streamer
    
    # Check if streamer is built
    if [ ! -f "simple_streamer" ]; then
        echo "Building simple streamer..."
        g++ -o simple_streamer src/simple_streamer.cpp -std=c++17 -pthread
    fi
    
    # Start streamer
    echo "Starting simple streamer..."
    ./simple_streamer -p 8080 -d test-device-001 &
    STREAMER_PID=$!
    
    cd ..
    
    echo -e "${GREEN}✅ Simple streamer started (PID: $STREAMER_PID)${NC}"
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
    
    # Test streamer
    echo "Testing streamer..."
    if netstat -tlnp 2>/dev/null | grep -q ":8080"; then
        echo -e "${GREEN}✅ Streamer is listening on port 8080${NC}"
    else
        echo -e "${RED}❌ Streamer is not listening${NC}"
    fi
    
    echo
}

# Main execution
main() {
    check_prerequisites
    
    echo -e "${BLUE}🚀 Starting SplashTop MVP components...${NC}"
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
    
    # Start simple streamer
    if start_streamer; then
        echo -e "${GREEN}✅ Simple streamer is ready${NC}"
    else
        echo -e "${RED}❌ Failed to start streamer${NC}"
        exit 1
    fi
    
    # Wait a moment for streamer to start
    sleep 2
    
    # Test the system
    test_system
    
    # Start Flutter client (optional - can be started manually)
    echo -e "${YELLOW}📱 Flutter client can be started manually with:${NC}"
    echo "cd Splashtop_Client && flutter run -d linux"
    echo
    
    echo -e "${GREEN}🎉 SplashTop MVP system is now running!${NC}"
    echo
    echo -e "${BLUE}📊 Component Status:${NC}"
    echo "   Backend Server: http://localhost:3000"
    echo "   Health Check: http://localhost:3000/health"
    echo "   Simple Streamer: localhost:8080"
    echo "   Flutter Client: Ready to start manually"
    echo
    echo -e "${YELLOW}🎮 Demo Instructions:${NC}"
    echo "   1. Backend server is running and ready for connections"
    echo "   2. Simple streamer is listening on port 8080"
    echo "   3. You can test the streamer with: telnet localhost 8080"
    echo "   4. Start Flutter client manually when ready"
    echo "   5. Register/login in the Flutter app"
    echo "   6. Add computer with device ID: test-device-001"
    echo "   7. Test remote desktop functionality"
    echo
    echo -e "${YELLOW}Press Ctrl+C to stop all components${NC}"
    echo
    
    # Wait for user to stop
    wait
}

# Run main function
main
