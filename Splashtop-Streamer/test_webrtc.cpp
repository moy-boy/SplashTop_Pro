#include "platform.h"
#include "webrtc_streamer.h"
#include <iostream>
#include <thread>
#include <chrono>

int main() {
    std::cout << "SplashTop WebRTC Streamer - Cross-Platform Test" << std::endl;
    std::cout << "===============================================" << std::endl;
    
    // Platform detection
#ifdef PLATFORM_WINDOWS
    std::cout << "Platform: Windows" << std::endl;
#elif defined(PLATFORM_MACOS)
    std::cout << "Platform: macOS" << std::endl;
#elif defined(PLATFORM_LINUX)
    std::cout << "Platform: Linux" << std::endl;
#else
    std::cout << "Platform: Unknown" << std::endl;
#endif
    
    std::cout << std::endl;
    
    // Create WebRTC streamer
    auto streamer = SplashTop::CreateWebRTCStreamer();
    if (!streamer) {
        std::cerr << "Failed to create WebRTC streamer" << std::endl;
        return 1;
    }
    
    std::cout << "WebRTC Streamer created successfully" << std::endl;
    
    // Initialize
    if (!streamer->Initialize()) {
        std::cerr << "Failed to initialize WebRTC streamer" << std::endl;
        return 1;
    }
    
    std::cout << "WebRTC Streamer initialized successfully" << std::endl;
    
    // Set callbacks
    streamer->SetConnectionStateCallback([](bool connected) {
        std::cout << "Connection state changed: " << (connected ? "Connected" : "Disconnected") << std::endl;
    });
    
    streamer->SetInputCallback([](const SplashTop::InputEvent& event) {
        std::cout << "Input event received: Type=" << event.type 
                  << ", x=" << event.x << ", y=" << event.y << std::endl;
    });
    
    // Set parameters
    streamer->SetBitrate(5000000);  // 5 Mbps
    streamer->SetFPS(30);           // 30 FPS
    streamer->SetQuality(80);       // 80% quality
    
    // Start streaming
    if (!streamer->StartStreaming("localhost", 8080)) {
        std::cerr << "Failed to start streaming" << std::endl;
        return 1;
    }
    
    std::cout << "Streaming started successfully" << std::endl;
    
    // Simulate sending some frames
    for (int i = 0; i < 10; i++) {
        SplashTop::VideoFrame frame;
        frame.width = 1920;
        frame.height = 1080;
        frame.data = nullptr;  // In real implementation, this would be actual frame data
        frame.stride = frame.width * 4;
        frame.timestamp = std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count();
        frame.format = 0;  // BGRA
        
        if (streamer->SendVideoFrame(frame)) {
            std::cout << "Frame " << (i + 1) << " sent successfully" << std::endl;
        } else {
            std::cerr << "Failed to send frame " << (i + 1) << std::endl;
        }
        
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        
        // Print stats every few frames
        if ((i + 1) % 3 == 0) {
            auto stats = streamer->GetStats();
            std::cout << "Stats: Frames=" << stats.framesSent 
                      << ", Bytes=" << stats.bytesSent
                      << ", Bitrate=" << (stats.averageBitrate / 1000000.0) << " Mbps"
                      << ", FPS=" << stats.averageFPS
                      << ", Connected=" << (stats.isConnected ? "Yes" : "No") << std::endl;
        }
    }
    
    // Stop streaming
    streamer->StopStreaming();
    std::cout << "Streaming stopped" << std::endl;
    
    // Final stats
    auto finalStats = streamer->GetStats();
    std::cout << std::endl << "Final Statistics:" << std::endl;
    std::cout << "  Total frames sent: " << finalStats.framesSent << std::endl;
    std::cout << "  Total bytes sent: " << finalStats.bytesSent << std::endl;
    std::cout << "  Average bitrate: " << (finalStats.averageBitrate / 1000000.0) << " Mbps" << std::endl;
    std::cout << "  Average FPS: " << finalStats.averageFPS << std::endl;
    
    std::cout << std::endl << "Cross-platform WebRTC streamer test completed successfully!" << std::endl;
    return 0;
}
