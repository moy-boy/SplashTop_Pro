# SplashTop Development Guide

## Project Structure

```
SplashTop/
├── include/                    # Public headers
│   ├── platform.h             # Platform abstraction
│   ├── screen_capture.h       # Screen capture interface
│   ├── video_encoder.h        # Video encoding interface
│   ├── input_injector.h       # Input injection interface
│   ├── webrtc_streamer.h      # WebRTC streaming interface
│   └── splashtop_app.h        # Main application class
├── src/                       # Implementation files
│   ├── main.cpp              # Application entry point
│   ├── splashtop_app.cpp     # Main application logic
│   ├── windows_screen_capture.cpp    # Windows screen capture
│   ├── windows_input_injector.cpp    # Windows input injection
│   ├── ffmpeg_video_encoder.cpp      # FFmpeg-based encoder
│   ├── webrtc_streamer.cpp           # WebRTC implementation
│   └── simple_test.cpp       # Simple test application
├── CMakeLists.txt           # CMake build configuration
├── SplashTop.vcxproj        # Visual Studio project file
├── SplashTop.sln            # Visual Studio solution file
└── build_simple.bat         # Simple Windows build script
```

## Building

### Windows (Visual Studio)
1. Open `SplashTop.sln` in Visual Studio
2. Build the solution (Ctrl+Shift+B)

### Windows (Command Line)
```cmd
build_simple.bat
```

### Cross-platform (CMake)
```bash
mkdir build && cd build
cmake ..
cmake --build . --config Release
```

## Current Status

✅ **Completed:**
- Windows screen capture (DXGI Desktop Duplication)
- Windows input injection (SendInput API)
- Basic application framework
- Platform abstraction layer
- Build system setup

⏳ **In Progress:**
- FFmpeg integration
- WebRTC implementation

📋 **Planned:**
- macOS support
- Linux support
- Audio streaming
- Multi-monitor support

## Adding Platform Support

1. Create platform-specific implementation files
2. Implement the abstract interfaces
3. Update factory functions
4. Add platform detection in `platform.h`
5. Update build system

## Testing

Run the simple test to verify basic functionality:
```cmd
bin\SplashTop.exe
```

## Next Steps

1. Install FFmpeg and WebRTC dependencies
2. Complete video encoding implementation
3. Implement WebRTC streaming
4. Add macOS and Linux support
5. Create client application

## Resources

- [DirectX Graphics Infrastructure](https://docs.microsoft.com/en-us/windows/win32/direct3ddxgi/)
- [WebRTC Native APIs](https://webrtc.github.io/webrtc/)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
