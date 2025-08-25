#pragma once

// Platform detection
#if defined(_WIN32) || defined(_WIN64)
    #define PLATFORM_WINDOWS
    #ifndef WIN32_LEAN_AND_MEAN
        #define WIN32_LEAN_AND_MEAN
    #endif
    #ifndef NOMINMAX
        #define NOMINMAX
    #endif
    #include <windows.h>
    #include <d3d11.h>
    #include <dxgi.h>
    #include <dxgi1_2.h>
#elif defined(__APPLE__)
    #define PLATFORM_MACOS
    #include <TargetConditionals.h>
    #if TARGET_OS_MAC
        #include <Cocoa/Cocoa.h>
        #include <CoreVideo/CoreVideo.h>
        #include <CoreGraphics/CoreGraphics.h>
        #include <ApplicationServices/ApplicationServices.h>
    #endif
#elif defined(__linux__)
    #define PLATFORM_LINUX
    #include <X11/Xlib.h>
    #include <X11/Xutil.h>
    #include <X11/extensions/Xrandr.h>
    #include <X11/extensions/Xfixes.h>
    #include <X11/extensions/Xinerama.h>
#endif

// Common includes
#include <cstdint>
#include <memory>
#include <string>
#include <vector>
#include <functional>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <chrono>
#include <iostream>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <exception>
#include <stdexcept>

// FFmpeg includes (optional)
#ifdef HAVE_FFMPEG
extern "C" {
    #include <libavcodec/avcodec.h>
    #include <libavformat/avformat.h>
    #include <libavutil/avutil.h>
    #include <libswscale/swscale.h>
    #include <libswresample/swresample.h>
}
#endif

// WebRTC includes (optional)
#ifdef HAVE_WEBRTC
#include <webrtc/api/peer_connection_interface.h>
#include <webrtc/api/media_stream_interface.h>
#include <webrtc/api/video_track_source.h>
#include <webrtc/media/base/video_frame.h>
#include <webrtc/rtc_base/thread.h>
#include <webrtc/rtc_base/logging.h>
#endif

// Platform-specific type definitions
namespace SplashTop {

#ifdef PLATFORM_WINDOWS
    using WindowHandle = HWND;
    using DisplayHandle = HDC;
    using MonitorHandle = HMONITOR;
#elif defined(PLATFORM_MACOS)
    using WindowHandle = NSWindow*;
    using DisplayHandle = CGDirectDisplayID;
    using MonitorHandle = CGDirectDisplayID;
#elif defined(PLATFORM_LINUX)
    using WindowHandle = Window;
    using DisplayHandle = Display*;
    using MonitorHandle = RROutput;
#endif

    // Common types
    using uint8 = std::uint8_t;
    using uint16 = std::uint16_t;
    using uint32 = std::uint32_t;
    using uint64 = std::uint64_t;
    using int8 = std::int8_t;
    using int16 = std::int16_t;
    using int32 = std::int32_t;
    using int64 = std::int64_t;

    // Video frame structure
    struct VideoFrame {
        uint8* data;
        uint32 width;
        uint32 height;
        uint32 stride;
        uint64 timestamp;
        uint32 format; // 0 = BGRA, 1 = RGBA, 2 = YUV420
    };

    // Input event structure
    struct InputEvent {
        enum Type {
            MOUSE_MOVE,
            MOUSE_DOWN,
            MOUSE_UP,
            MOUSE_WHEEL,
            KEY_DOWN,
            KEY_UP
        };

        Type type;
        int32 x, y;
        uint32 button;
        uint32 key;
        uint64 timestamp;
    };

    // Statistics structures
    struct CaptureStats {
        uint64 framesCaptured;
        uint64 totalBytes;
        double averageFPS;
        uint64 lastFrameTime;
    };

    struct EncoderStats {
        uint64 framesEncoded;
        uint64 totalBytes;
        double averageBitrate;
        double averageFPS;
        uint64 lastFrameTime;
    };

    struct StreamingStats {
        uint64 framesSent;
        uint64 bytesSent;
        double averageBitrate;
        double averageFPS;
        uint64 lastFrameTime;
        bool isConnected;
    };

    struct InputStats {
        uint64 mouseEvents;
        uint64 keyboardEvents;
        uint64 lastEventTime;
    };

} // namespace SplashTop
