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
    set(PLATFORM_WINDOWS TRUE)
elseif(APPLE)
    set(PLATFORM_MACOS TRUE)
elseif(UNIX)
    set(PLATFORM_LINUX TRUE)
endif()

# Linux-specific libraries
if(PLATFORM_LINUX)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(X11 REQUIRED x11)
    pkg_check_modules(XRANDR REQUIRED xrandr)
    pkg_check_modules(XFIXES REQUIRED xfixes)
    pkg_check_modules(XINERAMA REQUIRED xinerama)
    pkg_check_modules(XTEST REQUIRED xtst)
    
    set(LINUX_LIBS
        ${X11_LIBRARIES}
        ${XRANDR_LIBRARIES}
        ${XFIXES_LIBRARIES}
        ${XINERAMA_LIBRARIES}
        ${XTEST_LIBRARIES}
        pthread
        dl
    )
endif()

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Linux-compatible source files only
set(LINUX_SOURCES
    src/main.cpp
    src/splashtop_app.cpp
    src/webrtc_streamer.cpp
    src/webrtc_streamer_simple.cpp
    src/screen_capture_linux.cpp
    src/input_injector_linux.cpp
    src/ffmpeg_video_encoder.cpp
)

# Create executable
add_executable(SplashTop ${LINUX_SOURCES})

# Link libraries
if(PLATFORM_LINUX)
    target_link_libraries(SplashTop ${LINUX_LIBS})
endif()

# Compiler flags
target_compile_options(SplashTop PRIVATE
    $<$<CXX_COMPILER_ID:GNU>:-Wall -Wextra -O3>
    $<$<CXX_COMPILER_ID:Clang>:-Wall -Wextra -O3>
)

# Installation
install(TARGETS SplashTop
    RUNTIME DESTINATION bin
)
