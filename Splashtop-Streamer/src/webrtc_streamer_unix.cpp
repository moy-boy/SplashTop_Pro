#if defined(PLATFORM_LINUX) || defined(PLATFORM_MACOS)

#include "platform.h"
#include "webrtc_streamer.h"
#include <iostream>
#include <thread>
#include <chrono>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

namespace SplashTop {

    class UnixWebRTCStreamer : public IWebRTCStreamer {
    public:
        UnixWebRTCStreamer() : m_initialized(false), m_streaming(false), m_connected(false) {
            m_startTime = std::chrono::steady_clock::now();
        }
        
        ~UnixWebRTCStreamer() {
            StopStreaming();
        }
        
        bool Initialize() override {
            if (m_initialized) return true;
            
            try {
                std::cout << "Unix WebRTC Streamer: Initializing..." << std::endl;
                
                // Unix-specific WebRTC initialization
                // In a real implementation, you would:
                // - Initialize platform-specific media APIs
                // - Set up POSIX networking
                // - Configure hardware acceleration (VA-API on Linux, VideoToolbox on macOS)
                
                // Simulate initialization delay
                std::this_thread::sleep_for(std::chrono::milliseconds(150));
                
                m_initialized = true;
                std::cout << "Unix WebRTC Streamer: Initialized successfully" << std::endl;
                return true;
                
            } catch (const std::exception& e) {
                std::cerr << "Unix WebRTC Streamer: Initialization failed: " << e.what() << std::endl;
                return false;
            }
        }
        
        bool StartStreaming(const std::string& signalingServer, uint16 port) override {
            if (!m_initialized) {
                std::cerr << "Unix WebRTC Streamer: Not initialized" << std::endl;
                return false;
            }
            
            if (m_streaming) {
                std::cout << "Unix WebRTC Streamer: Already streaming" << std::endl;
                return true;
            }
            
            try {
                std::cout << "Unix WebRTC Streamer: Starting stream to " << signalingServer << ":" << port << std::endl;
                
                m_signalingServer = signalingServer;
                m_port = port;
                m_streaming = true;
                
                // Unix-specific connection setup
                // In a real implementation, you would:
                // - Use POSIX sockets for networking
                // - Set up platform-specific media pipeline
                // - Configure hardware acceleration
                
                // Simulate connection establishment
                std::this_thread::sleep_for(std::chrono::milliseconds(250));
                
                m_connected = true;
                m_connectionStartTime = std::chrono::steady_clock::now();
                
                if (m_connectionCallback) {
                    m_connectionCallback(true);
                }
                
                std::cout << "Unix WebRTC Streamer: Stream started successfully" << std::endl;
                return true;
                
            } catch (const std::exception& e) {
                std::cerr << "Unix WebRTC Streamer: Failed to start streaming: " << e.what() << std::endl;
                m_streaming = false;
                m_connected = false;
                return false;
            }
        }
        
        void StopStreaming() override {
            if (!m_streaming) return;
            
            std::cout << "Unix WebRTC Streamer: Stopping stream..." << std::endl;
            
            m_streaming = false;
            m_connected = false;
            
            if (m_connectionCallback) {
                m_connectionCallback(false);
            }
            
            std::cout << "Unix WebRTC Streamer: Stream stopped" << std::endl;
        }
        
        bool SendVideoFrame(const VideoFrame& frame) override {
            if (!m_streaming || !m_connected) {
                return false;
            }
            
            try {
                // Unix-specific video frame processing
                // In a real implementation, you would:
                // - Use platform-specific hardware acceleration
                // - Process through platform media APIs
                // - Send via POSIX sockets with optimizations
                
                m_framesSent++;
                m_bytesSent += frame.width * frame.height * 4; // BGRA format
                m_lastFrameTime = std::chrono::steady_clock::now();
                
                // Simulate Unix-specific processing time
                std::this_thread::sleep_for(std::chrono::microseconds(75));
                
                return true;
                
            } catch (const std::exception& e) {
                std::cerr << "Unix WebRTC Streamer: Failed to send frame: " << e.what() << std::endl;
                return false;
            }
        }
        
        void SetInputCallback(std::function<void(const InputEvent&)> callback) override {
            m_inputCallback = callback;
        }
        
        void SetConnectionStateCallback(std::function<void(bool connected)> callback) override {
            m_connectionCallback = callback;
        }
        
        StreamingStats GetStats() override {
            auto now = std::chrono::steady_clock::now();
            
            // Calculate bitrate and FPS
            double bitrate = 0.0;
            double fps = 0.0;
            
            if (m_connected && m_connectionStartTime.time_since_epoch().count() > 0) {
                auto duration = std::chrono::duration_cast<std::chrono::seconds>(now - m_connectionStartTime).count();
                if (duration > 0) {
                    bitrate = (m_bytesSent * 8.0) / duration; // bits per second
                    fps = static_cast<double>(m_framesSent) / duration;
                }
            }
            
            uint64 lastFrameTimeMs = 0;
            if (m_lastFrameTime.time_since_epoch().count() > 0) {
                lastFrameTimeMs = static_cast<uint64>(std::chrono::duration_cast<std::chrono::milliseconds>(
                    m_lastFrameTime.time_since_epoch()).count());
            }
            
            return {
                m_framesSent,
                m_bytesSent,
                bitrate,
                fps,
                lastFrameTimeMs,
                m_connected
            };
        }
        
        void SetBitrate(uint32 bitrate) override { 
            m_bitrate = bitrate;
            std::cout << "Unix WebRTC Streamer: Bitrate set to " << bitrate << " bps" << std::endl;
        }
        
        void SetFPS(uint32 fps) override { 
            m_fps = fps;
            std::cout << "Unix WebRTC Streamer: FPS set to " << fps << std::endl;
        }
        
        void SetQuality(uint32 quality) override { 
            m_quality = quality;
            std::cout << "Unix WebRTC Streamer: Quality set to " << quality << "%" << std::endl;
        }
        
    private:
        bool m_initialized;
        bool m_streaming;
        bool m_connected;
        std::string m_signalingServer;
        uint16 m_port;
        uint32 m_bitrate = 5000000;  // 5 Mbps default
        uint32 m_fps = 30;           // 30 FPS default
        uint32 m_quality = 80;       // 80% quality default
        
        // Statistics
        uint64 m_framesSent = 0;
        uint64 m_bytesSent = 0;
        std::chrono::steady_clock::time_point m_startTime;
        std::chrono::steady_clock::time_point m_connectionStartTime;
        std::chrono::steady_clock::time_point m_lastFrameTime;
        
        // Callbacks
        std::function<void(const InputEvent&)> m_inputCallback;
        std::function<void(bool connected)> m_connectionCallback;
    };

    // Unix-specific factory function
    std::unique_ptr<IWebRTCStreamer> CreateWebRTCStreamerUnix() {
        return std::make_unique<UnixWebRTCStreamer>();
    }

} // namespace SplashTop

#endif // PLATFORM_LINUX || PLATFORM_MACOS
