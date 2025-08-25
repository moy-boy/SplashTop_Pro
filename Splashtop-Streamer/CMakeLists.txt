cmake_minimum_required(VERSION 3.16)
project(SplashTop VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Platform-specific settings
if(WIN32)
    add_definitions(-DWIN32_LEAN_AND_MEAN)
    add_definitions(-DNOMINMAX)
    set(PLATFORM_WINDOWS TRUE)
elseif(APPLE)
    set(PLATFORM_MACOS TRUE)
elseif(UNIX)
    set(PLATFORM_LINUX TRUE)
endif()

# Find packages (optional for now)
find_package(PkgConfig QUIET)

# FFmpeg (optional for now)
if(PkgConfig_FOUND)
    pkg_check_modules(FFMPEG QUIET IMPORTED_TARGET
        libavcodec
        libavformat
        libavutil
        libswscale
        libswresample
    )
    if(FFMPEG_FOUND)
        add_definitions(-DHAVE_FFMPEG)
    endif()
endif()

# WebRTC (optional for now)
if(PkgConfig_FOUND)
    pkg_check_modules(WEBRTC QUIET IMPORTED_TARGET webrtc)
    if(WEBRTC_FOUND)
        add_definitions(-DHAVE_WEBRTC)
    endif()
endif()

# Platform-specific libraries
if(PLATFORM_WINDOWS)
    # Windows-specific libraries
    set(WINDOWS_LIBS
        d3d11
        dxgi
        d3dcompiler
        user32
        gdi32
        kernel32
        ole32
        oleaut32
        uuid
        advapi32
        shell32
    )
elseif(PLATFORM_MACOS)
    # macOS-specific frameworks
    find_library(COCOA_LIBRARY Cocoa)
    find_library(COREVIDEO_LIBRARY CoreVideo)
    find_library(COREFOUNDATION_LIBRARY CoreFoundation)
    find_library(QUARTZ_LIBRARY Quartz)
    find_library(VIDEOTOOLBOX_LIBRARY VideoToolbox)
    find_library(AUDIOTOOLBOX_LIBRARY AudioToolbox)
    find_library(COREGRAPHICS_LIBRARY CoreGraphics)
    find_library(APPLICATIONSERVICES_LIBRARY ApplicationServices)
    
    set(MACOS_FRAMEWORKS
        ${COCOA_LIBRARY}
        ${COREVIDEO_LIBRARY}
        ${COREFOUNDATION_LIBRARY}
        ${QUARTZ_LIBRARY}
        ${VIDEOTOOLBOX_LIBRARY}
        ${AUDIOTOOLBOX_LIBRARY}
        ${COREGRAPHICS_LIBRARY}
        ${APPLICATIONSERVICES_LIBRARY}
    )
elseif(PLATFORM_LINUX)
    # Linux-specific libraries
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(X11 REQUIRED x11)
    pkg_check_modules(XRANDR REQUIRED xrandr)
    pkg_check_modules(XFIXES REQUIRED xfixes)
    pkg_check_modules(XINERAMA REQUIRED xinerama)
    
    set(LINUX_LIBS
        ${X11_LIBRARIES}
        ${XRANDR_LIBRARIES}
        ${XFIXES_LIBRARIES}
        ${XINERAMA_LIBRARIES}
        pthread
        dl
    )
endif()

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party
)

# Source files
file(GLOB_RECURSE SOURCES 
    "src/*.cpp"
    "src/*.c"
)

# Header files
file(GLOB_RECURSE HEADERS 
    "include/*.h"
    "include/*.hpp"
)

# Create executable
add_executable(SplashTop ${SOURCES} ${HEADERS})

# Link libraries
if(FFMPEG_FOUND)
    target_link_libraries(SplashTop PkgConfig::FFMPEG)
endif()

if(WEBRTC_FOUND)
    target_link_libraries(SplashTop PkgConfig::WEBRTC)
endif()

# Platform-specific linking
if(PLATFORM_WINDOWS)
    target_link_libraries(SplashTop ${WINDOWS_LIBS})
elseif(PLATFORM_MACOS)
    target_link_libraries(SplashTop ${MACOS_FRAMEWORKS})
elseif(PLATFORM_LINUX)
    target_link_libraries(SplashTop ${LINUX_LIBS})
endif()

# Compiler flags
target_compile_options(SplashTop PRIVATE
    $<$<CXX_COMPILER_ID:GNU>:-Wall -Wextra -O3>
    $<$<CXX_COMPILER_ID:Clang>:-Wall -Wextra -O3>
    $<$<CXX_COMPILER_ID:MSVC>:/W3 /O2>
)

# Installation
install(TARGETS SplashTop
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)
