#include "platform.h"
#include "input_injector.h"

#ifdef PLATFORM_WINDOWS

namespace SplashTop {

    class WindowsInputInjector : public IInputInjector {
    public:
        WindowsInputInjector() : m_initialized(false), m_mouseEvents(0), m_keyboardEvents(0) {
            m_lastEventTime = std::chrono::steady_clock::now();
        }
        
        ~WindowsInputInjector() = default;
        
        bool Initialize() override {
            if (m_initialized) return true;
            
            // Check if we have input injection privileges
            // This requires running as administrator or having specific permissions
            m_initialized = true;
            return true;
        }
        
        bool InjectMouseMove(int32 x, int32 y) override {
            if (!m_initialized) return false;
            
            // Map coordinates if needed
            int32 mappedX = x, mappedY = y;
            if (m_coordinateMappingEnabled) {
                mappedX = static_cast<int32>((x * m_targetWidth) / m_sourceWidth);
                mappedY = static_cast<int32>((y * m_targetHeight) / m_sourceHeight);
            }
            
            INPUT input = {};
            input.type = INPUT_MOUSE;
            input.mi.dx = mappedX * (65535 / GetSystemMetrics(SM_CXSCREEN));
            input.mi.dy = mappedY * (65535 / GetSystemMetrics(SM_CYSCREEN));
            input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE;
            
            UINT result = SendInput(1, &input, sizeof(INPUT));
            if (result > 0) {
                m_mouseEvents++;
                m_lastEventTime = std::chrono::steady_clock::now();
                return true;
            }
            
            return false;
        }
        
        bool InjectMouseButton(uint32 button, bool pressed) override {
            if (!m_initialized) return false;
            
            INPUT input = {};
            input.type = INPUT_MOUSE;
            
            switch (button) {
                case 0: // Left button
                    input.mi.dwFlags = pressed ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_LEFTUP;
                    break;
                case 1: // Right button
                    input.mi.dwFlags = pressed ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_RIGHTUP;
                    break;
                case 2: // Middle button
                    input.mi.dwFlags = pressed ? MOUSEEVENTF_MIDDLEDOWN : MOUSEEVENTF_MIDDLEUP;
                    break;
                default:
                    return false;
            }
            
            UINT result = SendInput(1, &input, sizeof(INPUT));
            if (result > 0) {
                m_mouseEvents++;
                m_lastEventTime = std::chrono::steady_clock::now();
                return true;
            }
            
            return false;
        }
        
        bool InjectMouseWheel(int32 delta) override {
            if (!m_initialized) return false;
            
            INPUT input = {};
            input.type = INPUT_MOUSE;
            input.mi.dwFlags = MOUSEEVENTF_WHEEL;
            input.mi.mouseData = delta;
            
            UINT result = SendInput(1, &input, sizeof(INPUT));
            if (result > 0) {
                m_mouseEvents++;
                m_lastEventTime = std::chrono::steady_clock::now();
                return true;
            }
            
            return false;
        }
        
        bool InjectKey(uint32 key, bool pressed) override {
            if (!m_initialized) return false;
            
            INPUT input = {};
            input.type = INPUT_KEYBOARD;
            input.ki.wVk = static_cast<WORD>(key);
            input.ki.dwFlags = pressed ? 0 : KEYEVENTF_KEYUP;
            
            UINT result = SendInput(1, &input, sizeof(INPUT));
            if (result > 0) {
                m_keyboardEvents++;
                m_lastEventTime = std::chrono::steady_clock::now();
                return true;
            }
            
            return false;
        }
        
        bool InjectText(const std::string& text) override {
            if (!m_initialized) return false;
            
            std::vector<INPUT> inputs;
            inputs.reserve(text.length() * 2); // Each character needs key down and up
            
            for (char c : text) {
                // Convert to virtual key code (simplified)
                WORD vk = VkKeyScanA(c);
                SHORT shiftState = (vk >> 8) & 0xFF;
                
                // Handle shift key
                if (shiftState & 1) {
                    INPUT shiftInput = {};
                    shiftInput.type = INPUT_KEYBOARD;
                    shiftInput.ki.wVk = VK_SHIFT;
                    inputs.push_back(shiftInput);
                }
                
                // Key down
                INPUT keyDown = {};
                keyDown.type = INPUT_KEYBOARD;
                keyDown.ki.wVk = vk & 0xFF;
                inputs.push_back(keyDown);
                
                // Key up
                INPUT keyUp = {};
                keyUp.type = INPUT_KEYBOARD;
                keyUp.ki.wVk = vk & 0xFF;
                keyUp.ki.dwFlags = KEYEVENTF_KEYUP;
                inputs.push_back(keyUp);
                
                // Release shift if needed
                if (shiftState & 1) {
                    INPUT shiftUp = {};
                    shiftUp.type = INPUT_KEYBOARD;
                    shiftUp.ki.wVk = VK_SHIFT;
                    shiftUp.ki.dwFlags = KEYEVENTF_KEYUP;
                    inputs.push_back(shiftUp);
                }
            }
            
            UINT result = SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
            if (result > 0) {
                m_keyboardEvents += inputs.size();
                m_lastEventTime = std::chrono::steady_clock::now();
                return true;
            }
            
            return false;
        }
        
        void SetCoordinateMapping(uint32 sourceWidth, uint32 sourceHeight, 
                                uint32 targetWidth, uint32 targetHeight) override {
            m_sourceWidth = sourceWidth;
            m_sourceHeight = sourceHeight;
            m_targetWidth = targetWidth;
            m_targetHeight = targetHeight;
            m_coordinateMappingEnabled = true;
        }
        
        InputStats GetStats() override {
            return {
                m_mouseEvents,
                m_keyboardEvents,
                static_cast<uint64>(std::chrono::duration_cast<std::chrono::milliseconds>(m_lastEventTime.time_since_epoch()).count())
            };
        }
        
        bool IsAvailable() const override {
            return m_initialized;
        }
        
    private:
        bool m_initialized;
        uint64 m_mouseEvents;
        uint64 m_keyboardEvents;
        std::chrono::steady_clock::time_point m_lastEventTime;
        
        // Coordinate mapping
        bool m_coordinateMappingEnabled = false;
        uint32 m_sourceWidth, m_sourceHeight;
        uint32 m_targetWidth, m_targetHeight;
    };

    // Factory function implementation
    std::unique_ptr<IInputInjector> CreateInputInjector() {
        return std::make_unique<WindowsInputInjector>();
    }

} // namespace SplashTop

#endif // PLATFORM_WINDOWS
