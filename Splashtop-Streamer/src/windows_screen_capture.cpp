#include "platform.h"
#include "screen_capture.h"
#include <d3d11.h>
#include <dxgi.h>
#include <dxgi1_2.h>
#include <memory>
#include <vector>

#ifdef PLATFORM_WINDOWS

namespace SplashTop {

    class WindowsScreenCapture : public IScreenCapture {
    public:
        WindowsScreenCapture() : m_initialized(false), m_capturing(false), m_framesCaptured(0), m_totalBytes(0) {
            m_lastFrameTime = std::chrono::steady_clock::now();
        }
        
        ~WindowsScreenCapture() {
            StopCapture();
            Cleanup();
        }
        
        bool Initialize() override {
            if (m_initialized) return true;
            
            // Create D3D11 device
            D3D_FEATURE_LEVEL featureLevel;
            HRESULT hr = D3D11CreateDevice(
                nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0,
                nullptr, 0, D3D11_SDK_VERSION,
                &m_d3dDevice, &featureLevel, &m_d3dContext
            );
            
            if (FAILED(hr)) {
                std::cerr << "Failed to create D3D11 device: " << hr << std::endl;
                return false;
            }
            
            // Get DXGI adapter
            IDXGIDevice* dxgiDevice = nullptr;
            hr = m_d3dDevice->QueryInterface(__uuidof(IDXGIDevice), (void**)&dxgiDevice);
            if (FAILED(hr)) {
                std::cerr << "Failed to get DXGI device: " << hr << std::endl;
                return false;
            }
            
            IDXGIAdapter* dxgiAdapter = nullptr;
            hr = dxgiDevice->GetAdapter(&dxgiAdapter);
            dxgiDevice->Release();
            if (FAILED(hr)) {
                std::cerr << "Failed to get DXGI adapter: " << hr << std::endl;
                return false;
            }
            
            // Get DXGI output
            IDXGIOutput* dxgiOutput = nullptr;
            hr = dxgiAdapter->EnumOutputs(0, &dxgiOutput);
            dxgiAdapter->Release();
            if (FAILED(hr)) {
                std::cerr << "Failed to get DXGI output: " << hr << std::endl;
                return false;
            }
            
            // Get DXGI output 1.2 for desktop duplication
            IDXGIOutput1* dxgiOutput1 = nullptr;
            hr = dxgiOutput->QueryInterface(__uuidof(IDXGIOutput1), (void**)&dxgiOutput1);
            dxgiOutput->Release();
            if (FAILED(hr)) {
                std::cerr << "Failed to get DXGI output 1.2: " << hr << std::endl;
                return false;
            }
            
            // Create desktop duplication
            hr = dxgiOutput1->DuplicateOutput(m_d3dDevice, &m_desktopDuplication);
            dxgiOutput1->Release();
            if (FAILED(hr)) {
                std::cerr << "Failed to create desktop duplication: " << hr << std::endl;
                return false;
            }
            
            m_initialized = true;
            return true;
        }
        
        bool StartCapture(uint32 monitorIndex = 0) override {
            if (!m_initialized) {
                if (!Initialize()) return false;
            }
            
            m_capturing = true;
            m_framesCaptured = 0;
            m_totalBytes = 0;
            m_lastFrameTime = std::chrono::steady_clock::now();
            
            return true;
        }
        
        void StopCapture() override {
            m_capturing = false;
        }
        
        std::shared_ptr<VideoFrame> GetLatestFrame() override {
            if (!m_capturing || !m_initialized) return nullptr;
            
            IDXGIResource* desktopResource = nullptr;
            DXGI_OUTDUPL_FRAME_INFO frameInfo;
            
            HRESULT hr = m_desktopDuplication->AcquireNextFrame(100, &frameInfo, &desktopResource);
            if (FAILED(hr)) {
                return nullptr;
            }
            
            // Get the surface from the resource
            ID3D11Texture2D* desktopTexture = nullptr;
            hr = desktopResource->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&desktopTexture);
            desktopResource->Release();
            
            if (FAILED(hr)) {
                return nullptr;
            }
            
            // Get texture description
            D3D11_TEXTURE2D_DESC textureDesc;
            desktopTexture->GetDesc(&textureDesc);
            
            // Create staging texture for CPU access
            if (!m_stagingTexture || m_stagingTextureDesc.Width != textureDesc.Width || 
                m_stagingTextureDesc.Height != textureDesc.Height) {
                
                m_stagingTextureDesc = textureDesc;
                m_stagingTextureDesc.Usage = D3D11_USAGE_STAGING;
                m_stagingTextureDesc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
                m_stagingTextureDesc.BindFlags = 0;
                m_stagingTextureDesc.MiscFlags = 0;
                
                m_d3dDevice->CreateTexture2D(&m_stagingTextureDesc, nullptr, &m_stagingTexture);
            }
            
            // Copy to staging texture
            m_d3dContext->CopyResource(m_stagingTexture, desktopTexture);
            desktopTexture->Release();
            
            // Map the staging texture
            D3D11_MAPPED_SUBRESOURCE mappedResource;
            hr = m_d3dContext->Map(m_stagingTexture, 0, D3D11_MAP_READ, 0, &mappedResource);
            if (FAILED(hr)) {
                m_desktopDuplication->ReleaseFrame();
                return nullptr;
            }
            
            // Create video frame
            auto frame = std::make_shared<VideoFrame>();
            frame->width = textureDesc.Width;
            frame->height = textureDesc.Height;
            frame->stride = mappedResource.RowPitch;
            frame->format = 0; // BGRA
            frame->timestamp = std::chrono::duration_cast<std::chrono::microseconds>(
                std::chrono::steady_clock::now().time_since_epoch()).count();
            
            // Allocate and copy frame data
            size_t frameSize = frame->height * frame->stride;
            frame->data = new uint8[frameSize];
            memcpy(frame->data, mappedResource.pData, frameSize);
            
            m_d3dContext->Unmap(m_stagingTexture, 0);
            m_desktopDuplication->ReleaseFrame();
            
            // Update statistics
            m_framesCaptured++;
            m_totalBytes += frameSize;
            m_lastFrameTime = std::chrono::steady_clock::now();
            
            return frame;
        }
        
        std::vector<std::pair<uint32, uint32>> GetMonitorResolutions() override {
            std::vector<std::pair<uint32, uint32>> resolutions;
            
            // Get primary monitor resolution
            int width = GetSystemMetrics(SM_CXSCREEN);
            int height = GetSystemMetrics(SM_CYSCREEN);
            resolutions.push_back({static_cast<uint32>(width), static_cast<uint32>(height)});
            
            return resolutions;
        }
        
        void SetCaptureRegion(uint32 x, uint32 y, uint32 width, uint32 height) override {
            // For now, capture the entire screen
            // TODO: Implement region capture
        }
        
        CaptureStats GetStats() override {
            auto now = std::chrono::steady_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::seconds>(now - m_startTime).count();
            double fps = duration > 0 ? static_cast<double>(m_framesCaptured) / duration : 0.0;
            
            return {
                m_framesCaptured,
                m_totalBytes,
                fps,
                static_cast<uint64>(std::chrono::duration_cast<std::chrono::milliseconds>(m_lastFrameTime.time_since_epoch()).count())
            };
        }
        
        bool IsHardwareAccelerated() const override {
            return true; // DXGI Desktop Duplication is hardware accelerated
        }
        
    private:
        void Cleanup() {
            if (m_stagingTexture) {
                m_stagingTexture->Release();
                m_stagingTexture = nullptr;
            }
            if (m_desktopDuplication) {
                m_desktopDuplication->Release();
                m_desktopDuplication = nullptr;
            }
            if (m_d3dContext) {
                m_d3dContext->Release();
                m_d3dContext = nullptr;
            }
            if (m_d3dDevice) {
                m_d3dDevice->Release();
                m_d3dDevice = nullptr;
            }
            m_initialized = false;
        }
        
        // D3D11 objects
        ID3D11Device* m_d3dDevice = nullptr;
        ID3D11DeviceContext* m_d3dContext = nullptr;
        IDXGIOutputDuplication* m_desktopDuplication = nullptr;
        ID3D11Texture2D* m_stagingTexture = nullptr;
        D3D11_TEXTURE2D_DESC m_stagingTextureDesc = {};
        
        // State
        bool m_initialized;
        bool m_capturing;
        uint64 m_framesCaptured;
        uint64 m_totalBytes;
        std::chrono::steady_clock::time_point m_lastFrameTime;
        std::chrono::steady_clock::time_point m_startTime = std::chrono::steady_clock::now();
    };

    // Factory function implementation
    std::unique_ptr<IScreenCapture> CreateScreenCapture() {
        return std::make_unique<WindowsScreenCapture>();
    }

} // namespace SplashTop

#endif // PLATFORM_WINDOWS
