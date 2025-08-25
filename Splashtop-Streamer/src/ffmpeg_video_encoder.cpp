#include "platform.h"
#include "video_encoder.h"

namespace SplashTop {

    class FFmpegVideoEncoder : public IVideoEncoder {
    public:
        FFmpegVideoEncoder(const std::string& codec) : m_codec(codec), m_initialized(false) {}
        ~FFmpegVideoEncoder() = default;
        
        bool Initialize(uint32 width, uint32 height, uint32 fps, uint32 bitrate) override {
            m_width = width;
            m_height = height;
            m_fps = fps;
            m_bitrate = bitrate;
            m_initialized = true;
            return true;
        }
        
        bool EncodeFrame(const VideoFrame& frame, std::vector<uint8>& encodedData) override {
            if (!m_initialized) return false;
            
            // Simple placeholder - just copy frame data
            size_t frameSize = frame.width * frame.height * 4; // BGRA
            encodedData.resize(frameSize);
            memcpy(encodedData.data(), frame.data, frameSize);
            
            m_framesEncoded++;
            m_totalBytes += frameSize;
            return true;
        }
        
        EncoderStats GetStats() override {
            return {m_framesEncoded, m_totalBytes, 0.0, 0.0, 0};
        }
        
        bool IsHardwareAccelerated() const override { return false; }
        void SetBitrate(uint32 bitrate) override { m_bitrate = bitrate; }
        void SetFPS(uint32 fps) override { m_fps = fps; }
        void SetQuality(uint32 quality) override { m_quality = quality; }
        
        std::vector<std::string> GetSupportedCodecs() const override {
            return {"h264", "h265", "vp9"};
        }
        
    private:
        std::string m_codec;
        uint32 m_width, m_height, m_fps, m_bitrate, m_quality;
        bool m_initialized;
        uint64 m_framesEncoded = 0;
        uint64 m_totalBytes = 0;
    };

    std::unique_ptr<IVideoEncoder> CreateVideoEncoder(const std::string& codec) {
        return std::make_unique<FFmpegVideoEncoder>(codec);
    }

} // namespace SplashTop
