#include <iostream>
#include <thread>
#include <chrono>
#include <atomic>
#include <memory>
#include <functional>
#include <websocketpp/config/asio_no_tls_client.hpp>
#include <websocketpp/client.hpp>
#include <json/json.h>
#include <opencv2/opencv.hpp>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/XTest.h>
#include <X11/extensions/Xrandr.h>

typedef websocketpp::client<websocketpp::config::asio_client> WebSocketClient;
typedef WebSocketClient::message_ptr message_ptr;

class RealStreamer {
private:
    // WebSocket connection
    WebSocketClient client;
    websocketpp::connection_hdl connection;
    std::string signalingServer;
    std::string deviceId;
    
    // Screen capture
    Display* display;
    Window root;
    int screen;
    int width, height;
    std::atomic<bool> capturing;
    std::thread captureThread;
    
    // Video encoding
    cv::VideoWriter videoWriter;
    std::atomic<bool> streaming;
    std::thread streamingThread;
    
    // Input injection
    std::atomic<bool> inputEnabled;
    std::thread inputThread;
    
    // Performance metrics
    std::atomic<int> frameCount;
    std::atomic<int> bytesSent;
    std::chrono::steady_clock::time_point startTime;

public:
    RealStreamer(const std::string& server, const std::string& id) 
        : signalingServer(server), deviceId(id), display(nullptr), root(0), 
          screen(0), width(0), height(0), capturing(false), streaming(false), 
          inputEnabled(false), frameCount(0), bytesSent(0) {
        
        startTime = std::chrono::steady_clock::now();
    }
    
    ~RealStreamer() {
        Stop();
    }
    
    bool Initialize() {
        std::cout << "Initializing Real Streamer..." << std::endl;
        
        // Initialize WebSocket client
        client.init_asio();
        client.set_access_channels(websocketpp::log::alevel::none);
        client.set_error_channels(websocketpp::log::elevel::fatal);
        
        client.set_open_handler([this](websocketpp::connection_hdl hdl) {
            std::cout << "WebSocket connected" << std::endl;
            connection = hdl;
            RegisterAsStreamer();
        });
        
        client.set_message_handler([this](websocketpp::connection_hdl hdl, message_ptr msg) {
            HandleMessage(msg->get_payload());
        });
        
        client.set_close_handler([this](websocketpp::connection_hdl hdl) {
            std::cout << "WebSocket disconnected" << std::endl;
        });
        
        // Initialize X11 display
        display = XOpenDisplay(nullptr);
        if (!display) {
            std::cerr << "Failed to open X11 display" << std::endl;
            return false;
        }
        
        screen = DefaultScreen(display);
        root = DefaultRootWindow(display);
        width = DisplayWidth(display, screen);
        height = DisplayHeight(display, screen);
        
        std::cout << "Screen dimensions: " << width << "x" << height << std::endl;
        
        // Initialize video encoder
        int fourcc = cv::VideoWriter::fourcc('H', '2', '6', '4');
        videoWriter.open("temp_stream.mp4", fourcc, 30.0, cv::Size(width, height), true);
        if (!videoWriter.isOpened()) {
            std::cerr << "Failed to initialize video encoder" << std::endl;
            return false;
        }
        
        std::cout << "Real Streamer initialized successfully" << std::endl;
        return true;
    }
    
    bool Start() {
        std::cout << "Starting Real Streamer..." << std::endl;
        
        // Connect to signaling server
        websocketpp::lib::error_code ec;
        WebSocketClient::connection_ptr con = client.get_connection(signalingServer, ec);
        if (ec) {
            std::cerr << "Failed to create connection: " << ec.message() << std::endl;
            return false;
        }
        
        client.connect(con);
        
        // Start processing threads
        client.run();
        
        return true;
    }
    
    void Stop() {
        std::cout << "Stopping Real Streamer..." << std::endl;
        
        capturing = false;
        streaming = false;
        inputEnabled = false;
        
        if (captureThread.joinable()) {
            captureThread.join();
        }
        
        if (streamingThread.joinable()) {
            streamingThread.join();
        }
        
        if (inputThread.joinable()) {
            inputThread.join();
        }
        
        if (display) {
            XCloseDisplay(display);
            display = nullptr;
        }
        
        if (videoWriter.isOpened()) {
            videoWriter.release();
        }
        
        client.stop();
        
        std::cout << "Real Streamer stopped" << std::endl;
    }
    
private:
    void RegisterAsStreamer() {
        Json::Value message;
        message["type"] = "register";
        message["role"] = "streamer";
        message["deviceId"] = deviceId;
        message["capabilities"]["video"] = true;
        message["capabilities"]["audio"] = false;
        message["capabilities"]["input"] = true;
        
        Json::StreamWriterBuilder writer;
        std::string jsonMessage = Json::writeString(writer, message);
        
        client.send(connection, jsonMessage, websocketpp::frame::opcode::text);
        std::cout << "Registered as streamer" << std::endl;
    }
    
    void HandleMessage(const std::string& payload) {
        Json::Value root;
        Json::CharReaderBuilder reader;
        std::string errors;
        
        if (!Json::parseFromStream(reader, std::istringstream(payload), &root, &errors)) {
            std::cerr << "Failed to parse JSON: " << errors << std::endl;
            return;
        }
        
        std::string type = root["type"].asString();
        
        if (type == "start-streaming") {
            StartStreaming();
        } else if (type == "stop-streaming") {
            StopStreaming();
        } else if (type == "input-event") {
            HandleInputEvent(root);
        } else if (type == "webrtc-offer") {
            HandleWebRTCOffer(root);
        } else if (type == "webrtc-answer") {
            HandleWebRTCAnswer(root);
        } else if (type == "ice-candidate") {
            HandleICECandidate(root);
        }
    }
    
    void StartStreaming() {
        std::cout << "Starting video streaming..." << std::endl;
        
        streaming = true;
        capturing = true;
        
        // Start screen capture thread
        captureThread = std::thread([this]() {
            CaptureLoop();
        });
        
        // Start streaming thread
        streamingThread = std::thread([this]() {
            StreamingLoop();
        });
        
        // Start input handling thread
        inputEnabled = true;
        inputThread = std::thread([this]() {
            InputLoop();
        });
    }
    
    void StopStreaming() {
        std::cout << "Stopping video streaming..." << std::endl;
        
        streaming = false;
        capturing = false;
        inputEnabled = false;
    }
    
    void CaptureLoop() {
        const int targetFPS = 30;
        const auto frameInterval = std::chrono::microseconds(1000000 / targetFPS);
        auto lastFrameTime = std::chrono::steady_clock::now();
        
        while (capturing) {
            auto now = std::chrono::steady_clock::now();
            auto elapsed = now - lastFrameTime;
            
            if (elapsed >= frameInterval) {
                // Capture screen
                XImage* image = XGetImage(display, root, 0, 0, width, height, AllPlanes, ZPixmap);
                if (image) {
                    // Convert XImage to OpenCV Mat
                    cv::Mat frame(height, width, CV_8UC4, image->data);
                    cv::Mat bgrFrame;
                    cv::cvtColor(frame, bgrFrame, cv::COLOR_BGRA2BGR);
                    
                    // Encode frame
                    if (videoWriter.isOpened()) {
                        videoWriter.write(bgrFrame);
                        frameCount++;
                    }
                    
                    XDestroyImage(image);
                }
                
                lastFrameTime = now;
            } else {
                std::this_thread::sleep_for(std::chrono::microseconds(1000));
            }
        }
    }
    
    void StreamingLoop() {
        while (streaming) {
            // In a real implementation, this would:
            // 1. Read encoded frames from videoWriter
            // 2. Send them via WebRTC data channel
            // 3. Handle network buffering and flow control
            
            // For now, simulate streaming
            std::this_thread::sleep_for(std::chrono::milliseconds(33)); // ~30 FPS
            
            // Send frame statistics
            auto now = std::chrono::steady_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::seconds>(now - startTime);
            
            Json::Value stats;
            stats["type"] = "frame-stats";
            stats["frameCount"] = frameCount.load();
            stats["fps"] = duration.count() > 0 ? frameCount.load() / duration.count() : 0;
            stats["bytesSent"] = bytesSent.load();
            stats["timestamp"] = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::steady_clock::now().time_since_epoch()).count();
            
            Json::StreamWriterBuilder writer;
            std::string jsonStats = Json::writeString(writer, stats);
            
            client.send(connection, jsonStats, websocketpp::frame::opcode::text);
        }
    }
    
    void InputLoop() {
        while (inputEnabled) {
            // Process input events from queue
            // In a real implementation, this would handle input events from WebRTC data channel
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }
    
    void HandleInputEvent(const Json::Value& event) {
        std::string inputType = event["type"].asString();
        
        if (inputType == "mouse") {
            std::string action = event["action"].asString();
            double x = event["x"].asDouble();
            double y = event["y"].asDouble();
            
            int screenX = static_cast<int>(x * width);
            int screenY = static_cast<int>(y * height);
            
            if (action == "move") {
                XTestFakeMotionEvent(display, screen, screenX, screenY, CurrentTime);
            } else if (action == "down") {
                XTestFakeButtonEvent(display, 1, True, CurrentTime);
            } else if (action == "up") {
                XTestFakeButtonEvent(display, 1, False, CurrentTime);
            }
            
        } else if (inputType == "keyboard") {
            std::string key = event["key"].asString();
            std::string action = event["action"].asString();
            
            // Simplified key mapping
            KeySym keysym = XStringToKeysym(key.c_str());
            if (keysym != NoSymbol) {
                KeyCode keycode = XKeysymToKeycode(display, keysym);
                if (keycode != 0) {
                    if (action == "down") {
                        XTestFakeKeyEvent(display, keycode, True, CurrentTime);
                    } else if (action == "up") {
                        XTestFakeKeyEvent(display, keycode, False, CurrentTime);
                    }
                }
            }
        }
        
        XFlush(display);
    }
    
    void HandleWebRTCOffer(const Json::Value& offer) {
        // Handle WebRTC offer from client
        std::cout << "Received WebRTC offer" << std::endl;
        
        // In a real implementation, this would:
        // 1. Create WebRTC peer connection
        // 2. Set remote description
        // 3. Create answer
        // 4. Send answer back to client
        
        Json::Value answer;
        answer["type"] = "webrtc-answer";
        answer["answer"] = "simulated-answer-sdp";
        answer["target"] = offer["from"];
        
        Json::StreamWriterBuilder writer;
        std::string jsonAnswer = Json::writeString(writer, answer);
        
        client.send(connection, jsonAnswer, websocketpp::frame::opcode::text);
    }
    
    void HandleWebRTCAnswer(const Json::Value& answer) {
        // Handle WebRTC answer from client
        std::cout << "Received WebRTC answer" << std::endl;
    }
    
    void HandleICECandidate(const Json::Value& candidate) {
        // Handle ICE candidate from client
        std::cout << "Received ICE candidate" << std::endl;
    }
};

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cout << "Usage: " << argv[0] << " <signaling-server> <device-id>" << std::endl;
        std::cout << "Example: " << argv[0] << " ws://localhost:3000 test-device-001" << std::endl;
        return 1;
    }
    
    std::string signalingServer = argv[1];
    std::string deviceId = argv[2];
    
    std::cout << "Starting Real Streamer..." << std::endl;
    std::cout << "Signaling Server: " << signalingServer << std::endl;
    std::cout << "Device ID: " << deviceId << std::endl;
    
    RealStreamer streamer(signalingServer, deviceId);
    
    if (!streamer.Initialize()) {
        std::cerr << "Failed to initialize streamer" << std::endl;
        return 1;
    }
    
    if (!streamer.Start()) {
        std::cerr << "Failed to start streamer" << std::endl;
        return 1;
    }
    
    std::cout << "Real Streamer running. Press Ctrl+C to stop." << std::endl;
    
    // Wait for interrupt signal
    std::signal(SIGINT, [](int) {
        std::cout << "\nReceived interrupt signal" << std::endl;
    });
    
    while (true) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    
    return 0;
}
