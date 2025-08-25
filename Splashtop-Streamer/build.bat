@echo off
echo Building SplashTop Remote Desktop Streamer...
echo.

REM Check if CMake is available
cmake --version >nul 2>&1
if errorlevel 1 (
    echo Error: CMake is not installed or not in PATH
    echo Please install CMake from https://cmake.org/download/
    pause
    exit /b 1
)

REM Check if Visual Studio is available
where cl >nul 2>&1
if errorlevel 1 (
    echo Warning: Visual Studio compiler not found in PATH
    echo Please run this script from a Visual Studio Developer Command Prompt
    echo or set up the environment variables manually
    echo.
)

REM Create build directory
if not exist build mkdir build
cd build

REM Configure with CMake
echo Configuring project with CMake...
cmake .. -DCMAKE_BUILD_TYPE=Release
if errorlevel 1 (
    echo Error: CMake configuration failed
    pause
    exit /b 1
)

REM Build the project
echo.
echo Building project...
cmake --build . --config Release
if errorlevel 1 (
    echo Error: Build failed
    pause
    exit /b 1
)

echo.
echo Build completed successfully!
echo Executable location: build\Release\SplashTop.exe
echo.
echo To run the application:
echo   cd build\Release
echo   SplashTop.exe --help
echo.
pause
