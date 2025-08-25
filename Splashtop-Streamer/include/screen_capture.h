#pragma once

#include "platform.h"

namespace SplashTop {

    class IScreenCapture {
    public:
        virtual ~IScreenCapture() = default;
        
        // Initialize the screen capture system
        virtual bool Initialize() = 0;
        
        // Start capturing from a specific monitor
        virtual bool StartCapture(uint32 monitorIndex = 0) = 0;
        
        // Stop capturing
        virtual void StopCapture() = 0;
        
        // Get the latest frame
        virtual std::shared_ptr<VideoFrame> GetLatestFrame() = 0;
        
        // Get monitor information
        virtual std::vector<std::pair<uint32, uint32>> GetMonitorResolutions() = 0;
        
        // Set capture region (optional)
        virtual void SetCaptureRegion(uint32 x, uint32 y, uint32 width, uint32 height) = 0;
        
        // Get capture statistics
        virtual CaptureStats GetStats() = 0;
        
        // Check if hardware acceleration is available
        virtual bool IsHardwareAccelerated() const = 0;
    };

    // Factory function to create platform-specific screen capture
    std::unique_ptr<IScreenCapture> CreateScreenCapture();

} // namespace SplashTop
