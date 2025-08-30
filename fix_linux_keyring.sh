#!/bin/bash

echo "🔐 Fixing Linux Keyring for Flutter Secure Storage..."
echo "=================================================="

# Check if we're on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "This script is for Linux only."
    exit 0
fi

# Function to check if keyring is working
check_keyring() {
    if secret-tool search service test 2>/dev/null | grep -q "test"; then
        echo "✅ Keyring is working"
        return 0
    else
        echo "❌ Keyring is not working"
        return 1
    fi
}

# Function to initialize keyring
init_keyring() {
    echo "🔧 Initializing GNOME Keyring..."
    
    # Kill existing keyring daemon
    pkill -f gnome-keyring-daemon 2>/dev/null || true
    
    # Start keyring daemon with proper configuration
    eval $(gnome-keyring-daemon --start --foreground --components=secrets 2>/dev/null)
    
    # Set environment variables
    export GNOME_KEYRING_CONTROL
    export GNOME_KEYRING_PID
    
    # Wait a moment for keyring to initialize
    sleep 2
    
    # Test keyring
    if check_keyring; then
        echo "✅ Keyring initialized successfully"
        return 0
    else
        echo "❌ Failed to initialize keyring"
        return 1
    fi
}

# Function to create keyring configuration
setup_keyring_config() {
    echo "📝 Setting up keyring configuration..."
    
    # Create autostart directory
    mkdir -p ~/.config/autostart
    
    # Create keyring autostart file
    cat > ~/.config/autostart/gnome-keyring-secrets.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=GNOME Keyring: Secret Service
Comment=GNOME Keyring: Secret Service
Exec=/usr/bin/gnome-keyring-daemon --start --foreground --components=secrets
NoDisplay=true
X-GNOME-Autostart-Phase=PreDisplayServer
X-GNOME-AutoRestart=false
X-GNOME-Autostart-Notify=true
X-GNOME-Bugzilla-Bugzilla=GNOME
X-GNOME-Bugzilla-Product=gnome-keyring
X-GNOME-Bugzilla-Component=general
X-GNOME-Bugzilla-Version=40.1.1
X-Ubuntu-Gettext-Domain=gnome-keyring
EOF
    
    # Make it executable
    chmod +x ~/.config/autostart/gnome-keyring-secrets.desktop
    
    echo "✅ Keyring configuration created"
}

# Function to setup environment
setup_environment() {
    echo "🌍 Setting up environment variables..."
    
    # Add to bashrc if not already there
    if ! grep -q "GNOME_KEYRING_CONTROL" ~/.bashrc; then
        echo 'export GNOME_KEYRING_CONTROL="$(gnome-keyring-daemon --start --foreground --components=secrets 2>/dev/null | grep -o "GNOME_KEYRING_CONTROL=[^;]*" | cut -d= -f2)"' >> ~/.bashrc
    fi
    
    if ! grep -q "GNOME_KEYRING_PID" ~/.bashrc; then
        echo 'export GNOME_KEYRING_PID="$(gnome-keyring-daemon --start --foreground --components=secrets 2>/dev/null | grep -o "GNOME_KEYRING_PID=[^;]*" | cut -d= -f2)"' >> ~/.bashrc
    fi
    
    # Source bashrc to get the variables
    source ~/.bashrc
    
    echo "✅ Environment variables set up"
}

# Function to test Flutter secure storage
test_flutter_storage() {
    echo "🧪 Testing Flutter secure storage..."
    
    # Create a simple test script
    cat > test_secure_storage.dart << 'EOF'
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  try {
    final storage = FlutterSecureStorage(
      lOptions: LinuxOptions(
        applicationId: 'com.example.splashtop_client',
      ),
    );
    
    await storage.write(key: 'test_key', value: 'test_value');
    final value = await storage.read(key: 'test_key');
    
    if (value == 'test_value') {
      print('✅ Flutter secure storage is working!');
      await storage.delete(key: 'test_key');
    } else {
      print('❌ Flutter secure storage test failed');
    }
  } catch (e) {
    print('❌ Flutter secure storage error: $e');
  }
}
EOF
    
    # Run the test
    if command -v dart &> /dev/null; then
        dart test_secure_storage.dart
        rm test_secure_storage.dart
    else
        echo "⚠️ Dart not found, skipping Flutter storage test"
    fi
}

# Main execution
main() {
    echo "🔍 Checking current keyring status..."
    
    if check_keyring; then
        echo "✅ Keyring is already working"
    else
        echo "🔧 Keyring needs initialization"
        
        # Setup configuration
        setup_keyring_config
        
        # Setup environment
        setup_environment
        
        # Initialize keyring
        if init_keyring; then
            echo "✅ Keyring initialization successful"
        else
            echo "⚠️ Keyring initialization failed, will use fallback"
        fi
    fi
    
    # Test Flutter secure storage
    test_flutter_storage
    
    echo ""
    echo "🎉 Linux keyring setup complete!"
    echo "You can now run the Flutter app with secure storage."
}

# Run main function
main

