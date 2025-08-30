#include "screen_capture.h"
#include "platform.h"
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/Xrandr.h>
#include <X11/extensions/Xfixes.h>
#include <X11/extensions/Xinerama.h>
#include <cstring>
#include <iostream>

namespace SplashTop {

class LinuxScreenCapture : public IScreenCapture {
private:
    Display* display;
    Window root;
    XRRScreenResources* resources;
    XRROutputInfo* outputInfo;
    int screen;
    int width, height;
    std::vector<uint8> frameBuffer;
    std::atomic<bool> running;
    std::thread captureThread;
    std::mutex frameMutex;


public:
    LinuxScreenCapture() : display(nullptr), root(0), resources(nullptr), 
                          outputInfo(nullptr), screen(0), width(0), height(0), running(false) {}

    ~LinuxScreenCapture() {
        StopCapture();
        Cleanup();
    }

    bool Initialize() override {
        display = XOpenDisplay(nullptr);
        if (!display) {
            std::cerr << "Failed to open X11 display" << std::endl;
            return false;
        }

        screen = DefaultScreen(display);
        root = DefaultRootWindow(display);

        // Get screen dimensions
        width = DisplayWidth(display, screen);
        height = DisplayHeight(display, screen);

        std::cout << "Screen dimensions: " << width << "x" << height << std::endl;

        // Allocate frame buffer (BGRA format)
        frameBuffer.resize(width * height * 4);

        return true;
    }

    bool StartCapture(uint32 monitorIndex = 0) override {
        if (!display) {
            std::cerr << "Display not initialized" << std::endl;
            return false;
        }

        running = true;
        captureThread = std::thread(&LinuxScreenCapture::CaptureLoop, this);
        
        std::cout << "Screen capture started" << std::endl;
        return true;
    }

    void StopCapture() override {
        running = false;
        if (captureThread.joinable()) {
            captureThread.join();
        }
        std::cout << "Screen capture stopped" << std::endl;
    }

    std::shared_ptr<VideoFrame> GetLatestFrame() override {
        std::lock_guard<std::mutex> lock(frameMutex);
        auto frame = std::make_shared<VideoFrame>();
        frame->data = frameBuffer.data();
        frame->width = width;
        frame->height = height;
        frame->stride = width * 4;
        frame->timestamp = std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count();
        frame->format = 0; // BGRA
        return frame;
    }

    std::vector<std::pair<uint32, uint32>> GetMonitorResolutions() override {
        std::vector<std::pair<uint32, uint32>> resolutions;
        resolutions.push_back({width, height});
        return resolutions;
    }

    void SetCaptureRegion(uint32 x, uint32 y, uint32 w, uint32 h) override {
        // For now, capture full screen
        (void)x; (void)y; (void)w; (void)h;
    }

    CaptureStats GetStats() override {
        CaptureStats stats = {};
        stats.framesCaptured = 0; // TODO: implement counter
        stats.averageFPS = 30.0;
        return stats;
    }

    bool IsHardwareAccelerated() const override {
        return false; // Software capture for now
    }

private:
    void CaptureLoop() {
        while (running) {
            auto start = std::chrono::steady_clock::now();

            // Capture screen
            XImage* image = XGetImage(display, root, 0, 0, width, height, AllPlanes, ZPixmap);
            if (image) {
                // Convert XImage to our format
                ConvertImage(image);
                XDestroyImage(image);

                // Create video frame
                VideoFrame frame;
                frame.data = frameBuffer.data();
                frame.width = width;
                frame.height = height;
                frame.stride = width * 4;
                frame.timestamp = std::chrono::duration_cast<std::chrono::microseconds>(
                    std::chrono::steady_clock::now().time_since_epoch()).count();
                frame.format = 0; // BGRA

                // Store frame in buffer (callback removed for new interface)
            }

            // Limit to ~30 FPS
            auto end = std::chrono::steady_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
            if (duration.count() < 33) { // ~30 FPS
                std::this_thread::sleep_for(std::chrono::milliseconds(33 - duration.count()));
            }
        }
    }

    void ConvertImage(XImage* image) {
        std::lock_guard<std::mutex> lock(frameMutex);
        
        // Convert XImage data to BGRA format
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                unsigned long pixel = XGetPixel(image, x, y);
                
                // Extract RGB values (assuming 24-bit color)
                uint8 r = (pixel >> 16) & 0xFF;
                uint8 g = (pixel >> 8) & 0xFF;
                uint8 b = pixel & 0xFF;
                uint8 a = 0xFF; // Full alpha
                
                // Store in BGRA format
                int index = (y * width + x) * 4;
                frameBuffer[index] = b;     // Blue
                frameBuffer[index + 1] = g; // Green
                frameBuffer[index + 2] = r; // Red
                frameBuffer[index + 3] = a; // Alpha
            }
        }
    }

    void Cleanup() {
        if (outputInfo) {
            XRRFreeOutputInfo(outputInfo);
            outputInfo = nullptr;
        }
        if (resources) {
            XRRFreeScreenResources(resources);
            resources = nullptr;
        }
        if (display) {
            XCloseDisplay(display);
            display = nullptr;
        }
    }
};

// Factory function
std::unique_ptr<IScreenCapture> CreateScreenCapture() {
    return std::make_unique<LinuxScreenCapture>();
}

} // namespace SplashTop
