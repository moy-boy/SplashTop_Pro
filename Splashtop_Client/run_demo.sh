#!/bin/bash

echo "🚀 Starting SplashTop Client Demo (Simplified Version)"
echo "===================================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Setting up simplified Flutter client...${NC}"

# Backup original files
cp pubspec.yaml pubspec.yaml.backup
cp lib/main.dart lib/main.dart.backup

# Use simplified versions
cp pubspec_simple.yaml pubspec.yaml
cp lib/main_simple.dart lib/main.dart

echo -e "${BLUE}🔄 Installing dependencies...${NC}"
flutter clean
flutter pub get

echo -e "${BLUE}🔄 Regenerating models...${NC}"
flutter packages pub run build_runner build --delete-conflicting-outputs

echo -e "${GREEN}✅ Ready to run Flutter app!${NC}"
echo
echo -e "${YELLOW}🎮 Demo Instructions:${NC}"
echo "   1. The app will open with a login screen"
echo "   2. You can register a new account or login"
echo "   3. Navigate through the UI to see the design"
echo "   4. Note: WebRTC functionality is disabled in this demo"
echo
echo -e "${BLUE}🚀 Starting Flutter app...${NC}"

# Try to run on Linux first, fallback to web
if flutter run -d linux; then
    echo -e "${GREEN}✅ Flutter app running on Linux!${NC}"
else
    echo -e "${YELLOW}⚠️  Linux build failed, trying web...${NC}"
    if flutter run -d chrome; then
        echo -e "${GREEN}✅ Flutter app running on Chrome!${NC}"
    else
        echo -e "${RED}❌ Failed to run Flutter app${NC}"
        echo -e "${YELLOW}💡 Try running manually: flutter run -d chrome${NC}"
    fi
fi

echo
echo -e "${YELLOW}🔄 Restoring original files...${NC}"
cp pubspec.yaml.backup pubspec.yaml
cp lib/main.dart.backup lib/main.dart

echo -e "${GREEN}✅ Demo completed!${NC}"
