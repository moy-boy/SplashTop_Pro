#include <iostream>
#include <thread>
#include <chrono>
#include <string>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <cstring>
#include <signal.h>

class SimpleStreamer {
private:
    int serverSocket;
    bool running;
    int port;
    std::string deviceId;

public:
    SimpleStreamer(int port = 8080, const std::string& id = "test-device-001") 
        : port(port), deviceId(id), running(false), serverSocket(-1) {}

    bool Start() {
        // Create socket
        serverSocket = socket(AF_INET, SOCK_STREAM, 0);
        if (serverSocket < 0) {
            std::cerr << "Failed to create socket" << std::endl;
            return false;
        }

        // Set socket options
        int opt = 1;
        if (setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
            std::cerr << "Failed to set socket options" << std::endl;
            close(serverSocket);
            return false;
        }

        // Bind socket
        struct sockaddr_in address;
        address.sin_family = AF_INET;
        address.sin_addr.s_addr = INADDR_ANY;
        address.sin_port = htons(port);

        if (bind(serverSocket, (struct sockaddr*)&address, sizeof(address)) < 0) {
            std::cerr << "Failed to bind socket" << std::endl;
            close(serverSocket);
            return false;
        }

        // Listen for connections
        if (listen(serverSocket, 3) < 0) {
            std::cerr << "Failed to listen" << std::endl;
            close(serverSocket);
            return false;
        }

        running = true;
        std::cout << "Simple Streamer started on port " << port << std::endl;
        std::cout << "Device ID: " << deviceId << std::endl;
        std::cout << "Waiting for connections..." << std::endl;

        return true;
    }

    void Run() {
        while (running) {
            struct sockaddr_in clientAddr;
            socklen_t clientAddrLen = sizeof(clientAddr);
            
            int clientSocket = accept(serverSocket, (struct sockaddr*)&clientAddr, &clientAddrLen);
            if (clientSocket < 0) {
                if (running) {
                    std::cerr << "Failed to accept connection" << std::endl;
                }
                continue;
            }

            std::cout << "Client connected from " << inet_ntoa(clientAddr.sin_addr) << std::endl;
            
            // Handle client connection
            HandleClient(clientSocket);
            
            close(clientSocket);
        }
    }

    void HandleClient(int clientSocket) {
        char buffer[1024];
        int bytesRead;

        // Send connection message
        std::string message = "{\"type\":\"connected\",\"deviceId\":\"" + deviceId + "\",\"message\":\"Streamer ready\"}";
        send(clientSocket, message.c_str(), message.length(), 0);

        std::cout << "Sent connection message to client" << std::endl;

        // Simulate streaming for 30 seconds
        auto startTime = std::chrono::steady_clock::now();
        int frameCount = 0;

        while (running && std::chrono::steady_clock::now() - startTime < std::chrono::seconds(30)) {
            // Simulate frame data
            std::string frameData = "{\"type\":\"frame\",\"frameNumber\":" + std::to_string(frameCount++) + ",\"timestamp\":" + std::to_string(std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now().time_since_epoch()).count()) + "}";
            
            send(clientSocket, frameData.c_str(), frameData.length(), 0);
            
            std::this_thread::sleep_for(std::chrono::milliseconds(33)); // ~30 FPS
        }

        // Send disconnect message
        const char* disconnectMsg = "{\"type\":\"disconnected\",\"message\":\"Stream ended\"}";
        send(clientSocket, disconnectMsg, strlen(disconnectMsg), 0);

        std::cout << "Stream ended. Sent " << frameCount << " frames." << std::endl;
    }

    void Stop() {
        running = false;
        if (serverSocket >= 0) {
            close(serverSocket);
            serverSocket = -1;
        }
        std::cout << "Streamer stopped" << std::endl;
    }

    ~SimpleStreamer() {
        Stop();
    }
};

static SimpleStreamer* g_streamer = nullptr;

void SignalHandler(int signal) {
    if (g_streamer) {
        std::cout << "\nReceived signal " << signal << ", shutting down..." << std::endl;
        g_streamer->Stop();
    }
    exit(0);
}

int main(int argc, char* argv[]) {
    std::cout << "SplashTop Simple Streamer v1.0.0" << std::endl;
    std::cout << "================================" << std::endl;
    
    int port = 8080;
    std::string deviceId = "test-device-001";
    
    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "-p" || arg == "--port") {
            if (i + 1 < argc) {
                port = std::stoi(argv[++i]);
            }
        } else if (arg == "-d" || arg == "--device-id") {
            if (i + 1 < argc) {
                deviceId = argv[++i];
            }
        } else if (arg == "-h" || arg == "--help") {
            std::cout << "Usage: " << argv[0] << " [options]" << std::endl;
            std::cout << "Options:" << std::endl;
            std::cout << "  -p, --port <port>       Port to listen on (default: 8080)" << std::endl;
            std::cout << "  -d, --device-id <id>    Device ID (default: test-device-001)" << std::endl;
            std::cout << "  -h, --help              Show this help message" << std::endl;
            return 0;
        }
    }
    
    // Set up signal handlers
    signal(SIGINT, SignalHandler);
    signal(SIGTERM, SignalHandler);
    
    SimpleStreamer streamer(port, deviceId);
    g_streamer = &streamer;
    
    if (!streamer.Start()) {
        std::cerr << "Failed to start streamer" << std::endl;
        return 1;
    }
    
    std::cout << "Streamer is running. Press Ctrl+C to stop." << std::endl;
    
    // Run the streamer
    streamer.Run();
    
    return 0;
}
