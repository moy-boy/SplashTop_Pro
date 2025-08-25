#include "splashtop_app.h"
#include <iostream>
#include <string>
#include <csignal>

namespace SplashTop {

    static SplashTopApp* g_app = nullptr;

    void SignalHandler(int signal) {
        if (g_app) {
            std::cout << "\nReceived signal " << signal << ", shutting down..." << std::endl;
            g_app->StopStreaming();
            g_app->Shutdown();
        }
        exit(0);
    }

    void PrintUsage(const char* programName) {
        std::cout << "SplashTop Remote Desktop Streamer" << std::endl;
        std::cout << "Usage: " << programName << " [options]" << std::endl;
        std::cout << "Options:" << std::endl;
        std::cout << "  -s, --server <host>     Signaling server host (default: localhost)" << std::endl;
        std::cout << "  -p, --port <port>       Signaling server port (default: 8080)" << std::endl;
        std::cout << "  -f, --fps <fps>         Target frame rate (default: 30)" << std::endl;
        std::cout << "  -b, --bitrate <bps>     Target bitrate in bits per second (default: 5000000)" << std::endl;
        std::cout << "  -q, --quality <0-100>   Video quality (default: 80)" << std::endl;
        std::cout << "  -h, --help              Show this help message" << std::endl;
        std::cout << std::endl;
        std::cout << "Example:" << std::endl;
        std::cout << "  " << programName << " -s 192.168.1.100 -p 9000 -f 60 -b 10000000" << std::endl;
    }

    void PrintStats(const SplashTopApp::AppStats& stats) {
        std::cout << "\r=== SplashTop Statistics ===" << std::endl;
        std::cout << "Status: " << (stats.isStreaming ? "Streaming" : "Idle") << std::endl;
        std::cout << "Capture: " << stats.capture.framesCaptured << " frames, " 
                  << stats.capture.averageFPS << " FPS" << std::endl;
        std::cout << "Encoder: " << stats.encoder.framesEncoded << " frames, " 
                  << stats.encoder.averageBitrate / 1000000.0 << " Mbps" << std::endl;
        std::cout << "Streaming: " << stats.streaming.framesSent << " frames sent, " 
                  << (stats.streaming.isConnected ? "Connected" : "Disconnected") << std::endl;
        std::cout << "Input: " << stats.input.mouseEvents << " mouse, " 
                  << stats.input.keyboardEvents << " keyboard events" << std::endl;
    }

} // namespace SplashTop

int main(int argc, char* argv[]) {
    using namespace SplashTop;
    
    // Parse command line arguments
    std::string server = "localhost";
    uint16 port = 8080;
    uint32 fps = 30;
    uint32 bitrate = 5000000;
    uint32 quality = 80;
    
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        
        if (arg == "-h" || arg == "--help") {
            PrintUsage(argv[0]);
            return 0;
        } else if (arg == "-s" || arg == "--server") {
            if (i + 1 < argc) {
                server = argv[++i];
            } else {
                std::cerr << "Error: Missing server host" << std::endl;
                return 1;
            }
        } else if (arg == "-p" || arg == "--port") {
            if (i + 1 < argc) {
                port = static_cast<uint16>(std::stoi(argv[++i]));
            } else {
                std::cerr << "Error: Missing port number" << std::endl;
                return 1;
            }
        } else if (arg == "-f" || arg == "--fps") {
            if (i + 1 < argc) {
                fps = std::stoi(argv[++i]);
            } else {
                std::cerr << "Error: Missing FPS value" << std::endl;
                return 1;
            }
        } else if (arg == "-b" || arg == "--bitrate") {
            if (i + 1 < argc) {
                bitrate = std::stoi(argv[++i]);
            } else {
                std::cerr << "Error: Missing bitrate value" << std::endl;
                return 1;
            }
        } else if (arg == "-q" || arg == "--quality") {
            if (i + 1 < argc) {
                quality = std::stoi(argv[++i]);
                if (quality > 100) quality = 100;
            } else {
                std::cerr << "Error: Missing quality value" << std::endl;
                return 1;
            }
        } else {
            std::cerr << "Error: Unknown argument " << arg << std::endl;
            PrintUsage(argv[0]);
            return 1;
        }
    }
    

    // Set up signal handlers
    signal(SIGINT, SignalHandler);
    signal(SIGTERM, SignalHandler);
    
    // Create and initialize application
    SplashTopApp app;
    g_app = &app;
    
    std::cout << "SplashTop Remote Desktop Streamer v1.0.0" << std::endl;
    std::cout << "========================================" << std::endl;
    
    if (!app.Initialize()) {
        std::cerr << "Failed to initialize SplashTop application" << std::endl;
        return 1;
    }
    
    // Set streaming parameters
    app.SetStreamingParameters(fps, bitrate, quality);
    
    std::cout << "Configuration:" << std::endl;
    std::cout << "  Server: " << server << ":" << port << std::endl;
    std::cout << "  FPS: " << fps << std::endl;
    std::cout << "  Bitrate: " << bitrate / 1000000.0 << " Mbps" << std::endl;
    std::cout << "  Quality: " << quality << "%" << std::endl;
    std::cout << std::endl;
    
    // Start streaming
    if (!app.StartStreaming(server, port)) {
        std::cerr << "Failed to start streaming" << std::endl;
        return 1;
    }
    
    std::cout << "Streaming started. Press Ctrl+C to stop." << std::endl;
    
    // Main loop - print statistics periodically
    auto lastStatsTime = std::chrono::steady_clock::now();
    const auto statsInterval = std::chrono::seconds(5);
    
    while (app.IsRunning()) {
        auto now = std::chrono::steady_clock::now();
        
        if (now - lastStatsTime >= statsInterval) {
            PrintStats(app.GetStats());
            lastStatsTime = now;
        }
        
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    std::cout << "SplashTop application terminated." << std::endl;
    return 0;
}