#pragma once

#include "platform.h"
#include <functional>

namespace SplashTop {

    class IWebRTCStreamer {
    public:
        virtual ~IWebRTCStreamer() = default;
        
        // Initialize WebRTC
        virtual bool Initialize() = 0;
        
        // Start streaming
        virtual bool StartStreaming(const std::string& signalingServer, uint16 port) = 0;
        
        // Stop streaming
        virtual void StopStreaming() = 0;
        
        // Send video frame
        virtual bool SendVideoFrame(const VideoFrame& frame) = 0;
        
        // Set callbacks for input events
        virtual void SetInputCallback(std::function<void(const InputEvent&)> callback) = 0;
        
        // Set connection state callback
        virtual void SetConnectionStateCallback(std::function<void(bool connected)> callback) = 0;
        
        // Get streaming statistics
        virtual StreamingStats GetStats() = 0;
        
        // Set streaming parameters
        virtual void SetBitrate(uint32 bitrate) = 0;
        virtual void SetFPS(uint32 fps) = 0;
        virtual void SetQuality(uint32 quality) = 0;
    };

    // Factory function to create WebRTC streamer
    std::unique_ptr<IWebRTCStreamer> CreateWebRTCStreamer();

} // namespace SplashTop
