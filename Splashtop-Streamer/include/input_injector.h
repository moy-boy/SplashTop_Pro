#pragma once

#include "platform.h"

namespace SplashTop {

    class IInputInjector {
    public:
        virtual ~IInputInjector() = default;
        
        // Initialize the input injection system
        virtual bool Initialize() = 0;
        
        // Inject mouse events
        virtual bool InjectMouseMove(int32 x, int32 y) = 0;
        virtual bool InjectMouseButton(uint32 button, bool pressed) = 0;
        virtual bool InjectMouseWheel(int32 delta) = 0;
        
        // Inject keyboard events
        virtual bool InjectKey(uint32 key, bool pressed) = 0;
        virtual bool InjectText(const std::string& text) = 0;
        
        // Set coordinate mapping (for multi-monitor setups)
        virtual void SetCoordinateMapping(uint32 sourceWidth, uint32 sourceHeight, 
                                        uint32 targetWidth, uint32 targetHeight) = 0;
        
        // Get input injection statistics
        virtual InputStats GetStats() = 0;
        
        // Check if input injection is available
        virtual bool IsAvailable() const = 0;
    };

    // Factory function to create platform-specific input injector
    std::unique_ptr<IInputInjector> CreateInputInjector();

} // namespace SplashTop
