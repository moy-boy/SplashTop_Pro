# SplashTop Client - Test Mode

A simplified Flutter client for testing remote desktop streaming with the SplashTop Streamer.

## Features

- **Direct WebRTC Connection**: Connects directly to the streamer without authentication
- **Real-time Video Streaming**: Displays remote desktop video stream
- **Input Testing**: Test mouse, keyboard, and scroll events
- **Connection Status**: Real-time connection status and error reporting
- **Simple UI**: Clean, minimal interface for testing

## Quick Start

### Prerequisites

1. **Flutter SDK**: Make sure Flutter is installed and configured
2. **SplashTop Streamer**: The C++ streamer should be running on `localhost:8080`

### Running the Client

1. **Install Dependencies**:

   ```bash
   flutter pub get
   ```

2. **Run the App**:

   ```bash
   flutter run -d linux
   ```

3. **Connect to Streamer**:
   - Click the "Connect" button in the app
   - The app will attempt to connect to `ws://localhost:8080`
   - Once connected, you should see the remote desktop stream

### Testing Input Events

Once connected, you can test:

- **Mouse Events**: Click "Test Mouse" to send a mouse click
- **Keyboard Events**: Click "Test Keyboard" to send a key press
- **Scroll Events**: Click "Test Scroll" to send a scroll event

## Architecture

### Key Components

- **StreamingScreen**: Main UI for video display and controls
- **WebRTC Integration**: Direct peer-to-peer connection with streamer
- **WebSocket Signaling**: Real-time communication with streamer
- **Input Handling**: Mouse, keyboard, and scroll event transmission

### Connection Flow

1. **WebSocket Connection**: Connects to `ws://localhost:8080`
2. **WebRTC Setup**: Creates peer connection with ICE servers
3. **Signaling**: Exchanges SDP offers/answers and ICE candidates
4. **Video Stream**: Receives and displays remote desktop video
5. **Input Events**: Sends mouse/keyboard events to streamer

## Configuration

### WebRTC Settings

Edit `lib/utils/constants.dart` to modify:

- **ICE Servers**: STUN/TURN server configuration
- **Connection Timeout**: WebSocket connection timeout
- **Keep Alive**: Connection keep-alive interval

### Streamer URL

The client connects to `ws://localhost:8080` by default. To change this:

1. Update `AppConfig.streamerUrl` in `lib/utils/constants.dart`
2. Or modify the URL in `lib/screens/streaming_screen.dart`

## Troubleshooting

### Common Issues

1. **Connection Failed**:

   - Ensure the streamer is running on `localhost:8080`
   - Check firewall settings
   - Verify WebSocket server is active

2. **No Video Stream**:

   - Check streamer logs for video encoding issues
   - Verify WebRTC connection is established
   - Check browser console for WebRTC errors

3. **Input Not Working**:
   - Verify connection status is "Connected"
   - Check streamer input handling
   - Test with different input types

### Debug Mode

Run with debug output:

```bash
flutter run -d linux --debug
```

## Development

### Project Structure

```
lib/
├── main.dart              # App entry point
├── screens/
│   └── streaming_screen.dart  # Main streaming interface
└── utils/
    └── constants.dart     # Configuration constants
```

### Adding Features

1. **New Input Types**: Add to `_sendInputEvent()` method
2. **UI Improvements**: Modify `StreamingScreen` widget
3. **Connection Logic**: Update WebRTC and WebSocket handling

## Testing

Run the test suite:

```bash
flutter test
```

The test verifies that the app can be built and initialized without errors.

## Next Steps

This is a test client for development and debugging. For production:

1. **Add Authentication**: Implement user login and session management
2. **PC Management**: Add list of available remote computers
3. **Settings**: Add quality, audio, and connection settings
4. **Error Handling**: Improve error recovery and user feedback
5. **Security**: Add encryption and secure communication

## License

This project is for testing and development purposes.
