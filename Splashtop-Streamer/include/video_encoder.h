#pragma once

#include "platform.h"

namespace SplashTop {

    class IVideoEncoder {
    public:
        virtual ~IVideoEncoder() = default;
        
        // Initialize the encoder
        virtual bool Initialize(uint32 width, uint32 height, uint32 fps, uint32 bitrate) = 0;
        
        // Encode a frame
        virtual bool EncodeFrame(const VideoFrame& frame, std::vector<uint8>& encodedData) = 0;
        
        // Get encoder statistics
        virtual EncoderStats GetStats() = 0;
        
        // Check if hardware acceleration is available
        virtual bool IsHardwareAccelerated() const = 0;
        
        // Set encoding parameters
        virtual void SetBitrate(uint32 bitrate) = 0;
        virtual void SetFPS(uint32 fps) = 0;
        virtual void SetQuality(uint32 quality) = 0; // 0-100
        
        // Get supported codecs
        virtual std::vector<std::string> GetSupportedCodecs() const = 0;
    };

    // Factory function to create encoder
    std::unique_ptr<IVideoEncoder> CreateVideoEncoder(const std::string& codec = "h264");

} // namespace SplashTop
