# SplashTop Remote Desktop Streamer

A high-performance, cross-platform remote desktop streaming application built in C++ with low-latency capabilities.

## Features

- **Cross-Platform Support**: Windows, macOS, and Linux
- **Hardware Acceleration**: Utilizes platform-specific hardware encoders
- **Low Latency**: Optimized for real-time remote desktop streaming
- **WebRTC Integration**: Modern web-based streaming protocol
- **Input Injection**: Remote mouse and keyboard control
- **Configurable Quality**: Adjustable FPS, bitrate, and quality settings

## Architecture

### Core Components

1. **Screen Capture**
   - Windows: DXGI Desktop Duplication API
   - macOS: Metal/Quartz Display Services
   - Linux: X11/Wayland APIs

2. **Video Encoding**
   - Hardware encoders (NVENC, QuickSync, VideoToolbox)
   - Software fallback with FFmpeg
   - Support for H.264, H.265, and VP9 codecs

3. **Input Injection**
   - Windows: SendInput API
   - macOS: CGEvent API
   - Linux: uinput/XTest extension

4. **WebRTC Transport**
   - Low-latency streaming
   - NAT traversal
   - Adaptive bitrate

## Prerequisites

### Windows
- Visual Studio 2019 or later with C++17 support
- Windows 10/11 with DirectX 11 support
- FFmpeg development libraries
- WebRTC development libraries

### macOS
- Xcode 12 or later
- macOS 10.15 or later
- FFmpeg development libraries
- WebRTC development libraries

### Linux
- GCC 7+ or Clang 6+
- CMake 3.16+
- FFmpeg development libraries
- WebRTC development libraries
- X11 development libraries

## Building

### 1. Install Dependencies

#### Windows (using vcpkg)
```bash
# Install vcpkg if not already installed
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.bat

# Install dependencies
./vcpkg install ffmpeg:x64-windows
./vcpkg install webrtc:x64-windows
./vcpkg integrate install
```

#### macOS (using Homebrew)
```bash
brew install ffmpeg
brew install webrtc
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install build-essential cmake pkg-config
sudo apt install libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libswresample-dev
sudo apt install libx11-dev libxrandr-dev libxfixes-dev libxinerama-dev
```

### 2. Build the Project

```bash
# Clone the repository
git clone <repository-url>
cd SplashTop

# Create build directory
mkdir build
cd build

# Configure with CMake
cmake ..

# Build
cmake --build . --config Release

# Install (optional)
cmake --install .
```

## Usage

### Basic Usage

```bash
# Start streaming with default settings
./SplashTop

# Start streaming to a specific server
./SplashTop -s 192.168.1.100 -p 9000

# High-quality streaming
./SplashTop -f 60 -b 10000000 -q 95
```

### Command Line Options

- `-s, --server <host>`: Signaling server host (default: localhost)
- `-p, --port <port>`: Signaling server port (default: 8080)
- `-f, --fps <fps>`: Target frame rate (default: 30)
- `-b, --bitrate <bps>`: Target bitrate in bits per second (default: 5000000)
- `-q, --quality <0-100>`: Video quality (default: 80)
- `-h, --help`: Show help message

### Examples

```bash
# Low-latency gaming setup
./SplashTop -f 120 -b 20000000 -q 90

# Bandwidth-constrained setup
./SplashTop -f 30 -b 2000000 -q 70

# High-quality presentation setup
./SplashTop -f 60 -b 15000000 -q 95
```

## Configuration

### Performance Tuning

1. **For Gaming**: Use high FPS (60-120) and high bitrate (10-20 Mbps)
2. **For Productivity**: Use moderate FPS (30-60) and balanced bitrate (5-10 Mbps)
3. **For Bandwidth-Constrained**: Use lower FPS (15-30) and lower bitrate (1-5 Mbps)

### Hardware Acceleration

The application automatically detects and uses hardware acceleration when available:
- NVIDIA GPUs: NVENC encoder
- Intel CPUs: QuickSync encoder
- AMD GPUs: VCE encoder (planned)
- macOS: VideoToolbox encoder

## Development

### Project Structure

```
SplashTop/
├── include/           # Header files
│   ├── platform.h     # Platform abstraction
│   ├── screen_capture.h
│   ├── video_encoder.h
│   ├── input_injector.h
│   ├── webrtc_streamer.h
│   └── splashtop_app.h
├── src/              # Source files
│   ├── main.cpp      # Application entry point
│   ├── splashtop_app.cpp
│   ├── windows_screen_capture.cpp
│   ├── windows_input_injector.cpp
│   ├── ffmpeg_video_encoder.cpp
│   └── webrtc_streamer.cpp
├── third_party/      # Third-party dependencies
├── build/           # Build output
├── CMakeLists.txt   # CMake configuration
└── README.md        # This file
```

### Adding Platform Support

To add support for a new platform:

1. Create platform-specific implementation files
2. Implement the abstract interfaces
3. Update the factory functions
4. Add platform detection in `platform.h`
5. Update CMakeLists.txt with platform-specific libraries

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Ensure all dependencies are installed
   - Check CMake version compatibility
   - Verify compiler supports C++17

2. **Performance Issues**
   - Enable hardware acceleration
   - Adjust bitrate and quality settings
   - Check network bandwidth

3. **Input Injection Not Working**
   - Run as administrator (Windows)
   - Grant accessibility permissions (macOS)
   - Install uinput module (Linux)

### Debug Mode

Build with debug information:
```bash
cmake -DCMAKE_BUILD_TYPE=Debug ..
cmake --build .
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- FFmpeg for video encoding
- WebRTC for streaming protocol
- Microsoft for DXGI Desktop Duplication API
- Apple for Metal/Quartz APIs
- X.Org Foundation for X11 APIs

## Roadmap

- [ ] macOS screen capture implementation
- [ ] Linux screen capture implementation
- [ ] Full WebRTC implementation
- [ ] Audio streaming support
- [ ] Multi-monitor support
- [ ] Client application
- [ ] Web-based viewer
- [ ] Mobile client support
