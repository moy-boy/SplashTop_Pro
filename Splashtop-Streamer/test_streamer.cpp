#include <iostream>
#include <thread>
#include <chrono>
#include <string>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <cstring>

class SimpleWebSocketServer {
private:
    int serverSocket;
    bool running;
    int port;

public:
    SimpleWebSocketServer(int port = 8080) : port(port), running(false), serverSocket(-1) {}

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
        std::cout << "WebSocket server started on port " << port << std::endl;
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

        // Send WebSocket handshake response
        const char* handshake = 
            "HTTP/1.1 101 Switching Protocols\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n"
            "\r\n";
        
        send(clientSocket, handshake, strlen(handshake), 0);

        // Send a simple message
        const char* message = "{\"type\":\"connected\",\"message\":\"Streamer ready\"}";
        send(clientSocket, message, strlen(message), 0);

        std::cout << "Sent connection message to client" << std::endl;

        // Keep connection alive for a while
        std::this_thread::sleep_for(std::chrono::seconds(10));
    }

    void Stop() {
        running = false;
        if (serverSocket >= 0) {
            close(serverSocket);
            serverSocket = -1;
        }
        std::cout << "Server stopped" << std::endl;
    }

    ~SimpleWebSocketServer() {
        Stop();
    }
};

int main() {
    std::cout << "SplashTop Test Streamer" << std::endl;
    std::cout << "======================" << std::endl;
    
    SimpleWebSocketServer server(8080);
    
    if (!server.Start()) {
        std::cerr << "Failed to start server" << std::endl;
        return 1;
    }

    std::cout << "Server is running. Press Ctrl+C to stop." << std::endl;
    
    // Run the server
    server.Run();
    
    return 0;
}
