#pragma once

#include "platform.h"
#include "screen_capture.h"
#include "video_encoder.h"
#include "input_injector.h"
#include "webrtc_streamer.h"
#include <memory>
#include <thread>
#include <atomic>

namespace SplashTop {

    class SplashTopApp {
    public:
        SplashTopApp();
        ~SplashTopApp();
        
        // Initialize the application
        bool Initialize();
        
        // Start the streaming service
        bool StartStreaming(const std::string& signalingServer = "localhost", uint16 port = 8080);
        
        // Stop the streaming service
        void StopStreaming();
        
        // Set streaming parameters
        void SetStreamingParameters(uint32 fps = 30, uint32 bitrate = 5000000, uint32 quality = 80);
        
        // Get application statistics
        struct AppStats {
            CaptureStats capture;
            EncoderStats encoder;
            StreamingStats streaming;
            InputStats input;
            bool isStreaming;
        };
        
        AppStats GetStats();
        
        // Check if application is running
        bool IsRunning() const { return m_isRunning; }
        
        // Shutdown the application
        void Shutdown();

    private:
        // Main processing loop
        void ProcessingLoop();
        
        // Handle input events from WebRTC
        void OnInputEvent(const InputEvent& event);
        
        // Handle connection state changes
        void OnConnectionStateChanged(bool connected);
        
        // Components
        std::unique_ptr<IScreenCapture> m_screenCapture;
        std::unique_ptr<IVideoEncoder> m_videoEncoder;
        std::unique_ptr<IInputInjector> m_inputInjector;
        std::unique_ptr<IWebRTCStreamer> m_webrtcStreamer;
        
        // Threading
        std::thread m_processingThread;
        std::atomic<bool> m_isRunning;
        std::atomic<bool> m_isStreaming;
        
        // Configuration
        uint32 m_fps;
        uint32 m_bitrate;
        uint32 m_quality;
        uint32 m_captureWidth;
        uint32 m_captureHeight;
        
        // Statistics
        std::chrono::steady_clock::time_point m_startTime;
        uint64 m_totalFramesProcessed;
    };

} // namespace SplashTop
