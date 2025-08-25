#include "splashtop_app.h"
#include <iostream>
#include <chrono>

namespace SplashTop {

    SplashTopApp::SplashTopApp() : m_isRunning(false), m_isStreaming(false), 
        m_fps(30), m_bitrate(5000000), m_quality(80), m_captureWidth(1920), m_captureHeight(1080),
        m_totalFramesProcessed(0) {
        m_startTime = std::chrono::steady_clock::now();
    }
    
    SplashTopApp::~SplashTopApp() {
        Shutdown();
    }
    
    bool SplashTopApp::Initialize() {
        std::cout << "Initializing SplashTop Remote Desktop Streamer..." << std::endl;
        
        // Create components
        m_screenCapture = CreateScreenCapture();
        m_videoEncoder = CreateVideoEncoder("h264");
        m_inputInjector = CreateInputInjector();
        m_webrtcStreamer = CreateWebRTCStreamer();
        
        if (!m_screenCapture || !m_videoEncoder || !m_inputInjector || !m_webrtcStreamer) {
            std::cerr << "Failed to create components" << std::endl;
            return false;
        }
        
        // Initialize components
        if (!m_screenCapture->Initialize()) {
            std::cerr << "Failed to initialize screen capture" << std::endl;
            return false;
        }
        
        // Get monitor resolutions
        auto resolutions = m_screenCapture->GetMonitorResolutions();
        if (!resolutions.empty()) {
            m_captureWidth = resolutions[0].first;
            m_captureHeight = resolutions[0].second;
        }
        
        if (!m_videoEncoder->Initialize(m_captureWidth, m_captureHeight, m_fps, m_bitrate)) {
            std::cerr << "Failed to initialize video encoder" << std::endl;
            return false;
        }
        
        if (!m_inputInjector->Initialize()) {
            std::cerr << "Failed to initialize input injector" << std::endl;
            return false;
        }
        
        if (!m_webrtcStreamer->Initialize()) {
            std::cerr << "Failed to initialize WebRTC streamer" << std::endl;
            return false;
        }
        
        // Set up callbacks
        m_webrtcStreamer->SetInputCallback([this](const InputEvent& event) {
            OnInputEvent(event);
        });
        
        m_webrtcStreamer->SetConnectionStateCallback([this](bool connected) {
            OnConnectionStateChanged(connected);
        });
        
        // Set coordinate mapping
        m_inputInjector->SetCoordinateMapping(m_captureWidth, m_captureHeight, 
                                            m_captureWidth, m_captureHeight);
        
        m_isRunning = true;
        std::cout << "SplashTop initialized successfully" << std::endl;
        std::cout << "Screen resolution: " << m_captureWidth << "x" << m_captureHeight << std::endl;
        std::cout << "Hardware acceleration: " << (m_screenCapture->IsHardwareAccelerated() ? "Yes" : "No") << std::endl;
        
        return true;
    }
    
    bool SplashTopApp::StartStreaming(const std::string& signalingServer, uint16 port) {
        if (!m_isRunning) {
            std::cerr << "Application not initialized" << std::endl;
            return false;
        }
        
        std::cout << "Starting streaming to " << signalingServer << ":" << port << std::endl;
        
        // Start screen capture
        if (!m_screenCapture->StartCapture()) {
            std::cerr << "Failed to start screen capture" << std::endl;
            return false;
        }
        
        // Start WebRTC streaming
        if (!m_webrtcStreamer->StartStreaming(signalingServer, port)) {
            std::cerr << "Failed to start WebRTC streaming" << std::endl;
            m_screenCapture->StopCapture();
            return false;
        }
        
        m_isStreaming = true;
        
        // Start processing thread
        m_processingThread = std::thread(&SplashTopApp::ProcessingLoop, this);
        
        std::cout << "Streaming started successfully" << std::endl;
        return true;
    }
    
    void SplashTopApp::StopStreaming() {
        if (!m_isStreaming) return;
        
        std::cout << "Stopping streaming..." << std::endl;
        
        m_isStreaming = false;
        
        if (m_processingThread.joinable()) {
            m_processingThread.join();
        }
        
        m_screenCapture->StopCapture();
        m_webrtcStreamer->StopStreaming();
        
        std::cout << "Streaming stopped" << std::endl;
    }
    
    void SplashTopApp::SetStreamingParameters(uint32 fps, uint32 bitrate, uint32 quality) {
        m_fps = fps;
        m_bitrate = bitrate;
        m_quality = quality;
        
        if (m_videoEncoder) {
            m_videoEncoder->SetFPS(fps);
            m_videoEncoder->SetBitrate(bitrate);
            m_videoEncoder->SetQuality(quality);
        }
        
        if (m_webrtcStreamer) {
            m_webrtcStreamer->SetFPS(fps);
            m_webrtcStreamer->SetBitrate(bitrate);
            m_webrtcStreamer->SetQuality(quality);
        }
    }
    
    SplashTopApp::AppStats SplashTopApp::GetStats() {
        AppStats stats;
        stats.capture = m_screenCapture ? m_screenCapture->GetStats() : CaptureStats{};
        stats.encoder = m_videoEncoder ? m_videoEncoder->GetStats() : EncoderStats{};
        stats.streaming = m_webrtcStreamer ? m_webrtcStreamer->GetStats() : StreamingStats{};
        stats.input = m_inputInjector ? m_inputInjector->GetStats() : InputStats{};
        stats.isStreaming = m_isStreaming;
        return stats;
    }
    
    void SplashTopApp::Shutdown() {
        StopStreaming();
        m_isRunning = false;
        
        m_screenCapture.reset();
        m_videoEncoder.reset();
        m_inputInjector.reset();
        m_webrtcStreamer.reset();
        
        std::cout << "SplashTop shutdown complete" << std::endl;
    }
    
    void SplashTopApp::ProcessingLoop() {
        const auto frameInterval = std::chrono::microseconds(1000000 / m_fps);
        auto lastFrameTime = std::chrono::steady_clock::now();
        
        while (m_isStreaming) {
            auto now = std::chrono::steady_clock::now();
            auto elapsed = now - lastFrameTime;
            
            if (elapsed >= frameInterval) {
                // Capture frame
                auto frame = m_screenCapture->GetLatestFrame();
                if (frame) {
                    // Encode frame
                    std::vector<uint8> encodedData;
                    if (m_videoEncoder->EncodeFrame(*frame, encodedData)) {
                        // Send frame
                        m_webrtcStreamer->SendVideoFrame(*frame);
                        m_totalFramesProcessed++;
                    }
                    
                    // Clean up frame data
                    delete[] frame->data;
                }
                
                lastFrameTime = now;
            } else {
                // Sleep for a short time to avoid busy waiting
                std::this_thread::sleep_for(std::chrono::microseconds(1000));
            }
        }
    }
    
    void SplashTopApp::OnInputEvent(const InputEvent& event) {
        if (!m_inputInjector) return;
        
        switch (event.type) {
            case InputEvent::MOUSE_MOVE:
                m_inputInjector->InjectMouseMove(event.x, event.y);
                break;
            case InputEvent::MOUSE_DOWN:
                m_inputInjector->InjectMouseButton(event.button, true);
                break;
            case InputEvent::MOUSE_UP:
                m_inputInjector->InjectMouseButton(event.button, false);
                break;
            case InputEvent::MOUSE_WHEEL:
                m_inputInjector->InjectMouseWheel(event.y);
                break;
            case InputEvent::KEY_DOWN:
                m_inputInjector->InjectKey(event.key, true);
                break;
            case InputEvent::KEY_UP:
                m_inputInjector->InjectKey(event.key, false);
                break;
        }
    }
    
    void SplashTopApp::OnConnectionStateChanged(bool connected) {
        std::cout << "Connection state changed: " << (connected ? "Connected" : "Disconnected") << std::endl;
    }

} // namespace SplashTop
