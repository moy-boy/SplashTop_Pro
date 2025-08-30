#include "input_injector.h"
#include "platform.h"
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <X11/extensions/XTest.h>
#include <iostream>

namespace SplashTop {

class LinuxInputInjector : public IInputInjector {
private:
    Display* display;
    Window root;
    int screen;
    uint32 screenWidth, screenHeight;

public:
    LinuxInputInjector() : display(nullptr), root(0), screen(0), screenWidth(0), screenHeight(0) {}

    ~LinuxInputInjector() {
        Cleanup();
    }

    bool Initialize() override {
        display = XOpenDisplay(nullptr);
        if (!display) {
            std::cerr << "Failed to open X11 display for input injection" << std::endl;
            return false;
        }

        screen = DefaultScreen(display);
        root = DefaultRootWindow(display);
        screenWidth = DisplayWidth(display, screen);
        screenHeight = DisplayHeight(display, screen);

        std::cout << "Input injector initialized for " << screenWidth << "x" << screenHeight << std::endl;
        return true;
    }

    bool InjectMouseMove(int32 x, int32 y) override {
        if (!display) return false;

        // Clamp coordinates to screen bounds
        x = std::max(0, std::min(x, static_cast<int32>(screenWidth - 1)));
        y = std::max(0, std::min(y, static_cast<int32>(screenHeight - 1)));

        XTestFakeMotionEvent(display, screen, x, y, CurrentTime);
        XFlush(display);
        return true;
    }

    bool InjectMouseButton(uint32 button, bool pressed) override {
        if (!display) return false;

        int buttonCode;
        switch (button) {
            case 1: buttonCode = Button1; break; // Left
            case 2: buttonCode = Button2; break; // Middle
            case 3: buttonCode = Button3; break; // Right
            default: return false;
        }

        if (pressed) {
            XTestFakeButtonEvent(display, buttonCode, True, CurrentTime);
        } else {
            XTestFakeButtonEvent(display, buttonCode, False, CurrentTime);
        }
        
        XFlush(display);
        return true;
    }

    bool InjectMouseWheel(int32 delta) override {
        if (!display) return false;

        // Use button 4 for scroll up, button 5 for scroll down
        int buttonCode = (delta > 0) ? Button4 : Button5;
        
        XTestFakeButtonEvent(display, buttonCode, True, CurrentTime);
        XTestFakeButtonEvent(display, buttonCode, False, CurrentTime);
        XFlush(display);
        
        return true;
    }

    bool InjectKey(uint32 keyCode, bool pressed) override {
        if (!display) return false;

        // Convert key code to X11 key code (simplified mapping)
        KeySym keysym = keyCode; // This is simplified - should have proper mapping
        KeyCode xKeyCode = XKeysymToKeycode(display, keysym);
        
        if (xKeyCode == NoSymbol) {
            // Try common keys
            switch (keyCode) {
                case 13: xKeyCode = XKeysymToKeycode(display, XK_Return); break; // Enter
                case 27: xKeyCode = XKeysymToKeycode(display, XK_Escape); break; // Escape
                case 8:  xKeyCode = XKeysymToKeycode(display, XK_BackSpace); break; // Backspace
                case 9:  xKeyCode = XKeysymToKeycode(display, XK_Tab); break; // Tab
                case 32: xKeyCode = XKeysymToKeycode(display, XK_space); break; // Space
                default: return false;
            }
        }

        if (xKeyCode == NoSymbol) return false;

        if (pressed) {
            XTestFakeKeyEvent(display, xKeyCode, True, CurrentTime);
        } else {
            XTestFakeKeyEvent(display, xKeyCode, False, CurrentTime);
        }
        
        XFlush(display);
        return true;
    }

    bool InjectText(const std::string& text) override {
        if (!display) return false;

        // Simple text injection - convert each character to key press
        for (char c : text) {
            KeySym keysym = static_cast<KeySym>(c);
            KeyCode xKeyCode = XKeysymToKeycode(display, keysym);
            
            if (xKeyCode != NoSymbol) {
                XTestFakeKeyEvent(display, xKeyCode, True, CurrentTime);
                XTestFakeKeyEvent(display, xKeyCode, False, CurrentTime);
            }
        }
        
        XFlush(display);
        return true;
    }

    void SetCoordinateMapping(uint32 sourceWidth, uint32 sourceHeight, 
                            uint32 targetWidth, uint32 targetHeight) override {
        // TODO: Implement coordinate mapping
        (void)sourceWidth; (void)sourceHeight; (void)targetWidth; (void)targetHeight;
    }

    InputStats GetStats() override {
        InputStats stats = {};
        stats.mouseEvents = 0; // TODO: implement counter
        stats.keyboardEvents = 0; // TODO: implement counter
        return stats;
    }

    bool IsAvailable() const override {
        return display != nullptr;
    }

private:
    void Cleanup() {
        if (display) {
            XCloseDisplay(display);
            display = nullptr;
        }
    }
};

// Factory function
std::unique_ptr<IInputInjector> CreateInputInjector() {
    return std::make_unique<LinuxInputInjector>();
}

} // namespace SplashTop
