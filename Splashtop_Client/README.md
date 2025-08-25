# SplashTop Client

A Flutter-based remote desktop client application that allows users to connect to and control remote computers through WebRTC technology. This is part of a SplashTop-like remote desktop solution.

## Features

### 🔐 Authentication

- Secure login with email/password
- JWT token-based authentication
- Automatic token refresh
- Secure storage of credentials

### 🖥️ PC Management

- View list of available remote computers
- Add, edit, and delete computer entries
- Filter computers by platform (Windows, macOS, Linux)
- Filter by status (Online, Offline, Busy, Sleeping)
- Search functionality
- Real-time status updates

### 🎥 Remote Desktop Streaming

- WebRTC-based video streaming
- Low-latency peer-to-peer connections
- Hardware-accelerated video rendering
- Fullscreen mode support
- Connection status monitoring

### 🖱️ Input Control

- Mouse movement and clicks
- Right-click support
- Keyboard input (via on-screen keyboard or external keyboard)
- Touch gesture support
- Relative coordinate mapping

### 🎨 Modern UI

- Material Design 3
- Responsive layout
- Dark/light theme support
- Intuitive navigation
- Error handling and loading states

## Tech Stack

### Frontend

- **Framework**: Flutter 3.35.1
- **Language**: Dart 3.9.0
- **State Management**: Provider pattern
- **UI**: Material Design 3 with Google Fonts

### WebRTC & Networking

- **WebRTC**: flutter_webrtc for peer-to-peer communication
- **HTTP Client**: http package for API communication
- **WebSocket**: web_socket_channel for real-time signaling
- **Security**: flutter_secure_storage for token management

### Dependencies

- `flutter_webrtc`: WebRTC implementation
- `provider`: State management
- `http`: HTTP client
- `web_socket_channel`: WebSocket communication
- `flutter_secure_storage`: Secure storage
- `shared_preferences`: Local storage
- `json_annotation`: JSON serialization
- `google_fonts`: Typography
- `permission_handler`: Permission management

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart            # User model
│   └── pc.dart              # PC model
├── services/                 # Business logic services
│   ├── auth_service.dart    # Authentication service
│   ├── api_service.dart     # API communication
│   └── webrtc_service.dart  # WebRTC streaming
├── providers/               # State management
│   ├── auth_provider.dart   # Authentication state
│   └── pc_list_provider.dart # PC list state
├── screens/                 # UI screens
│   ├── login_screen.dart    # Login screen
│   ├── home_screen.dart     # Main screen
│   └── streaming_screen.dart # Remote desktop screen
└── utils/                   # Utilities
    └── constants.dart       # App constants
```

## Getting Started

### Prerequisites

- Flutter SDK 3.35.1 or higher
- Dart 3.9.0 or higher
- Android Studio / VS Code with Flutter extensions
- Backend server running (see backend documentation)

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd splashtop_client
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure backend URL**
   Edit `lib/utils/constants.dart` and update the `ApiEndpoints.baseUrl` to point to your backend server:

   ```dart
   static const String baseUrl = 'http://your-backend-server:3000/api';
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

### Platform Support

The app supports multiple platforms:

- **Android**: Full support with hardware acceleration
- **iOS**: Full support with hardware acceleration
- **Web**: Basic support (limited WebRTC capabilities)
- **Windows**: Full support
- **macOS**: Full support
- **Linux**: Full support

## Usage

### Authentication

1. Launch the app
2. Enter your email and password
3. Tap "Sign In"
4. The app will automatically navigate to the home screen upon successful authentication

### Managing Computers

1. **View Computers**: The home screen displays all your registered computers
2. **Add Computer**: Tap the floating action button (+) to add a new computer
3. **Filter Computers**: Use the search bar and filters to find specific computers
4. **Edit/Delete**: Use the menu on each computer card to edit or delete

### Remote Desktop Connection

1. **Connect**: Tap the "Connect" option on an available computer
2. **Wait for Connection**: The app will establish a WebRTC connection
3. **Control**: Use touch gestures to control the remote desktop:
   - Tap to left-click
   - Long press to right-click
   - Drag to move mouse
   - Use fullscreen mode for better experience

### Controls

- **Mouse**: Tap and drag to control the remote mouse
- **Keyboard**: Use the on-screen keyboard or connect an external keyboard
- **Fullscreen**: Tap the fullscreen button for immersive experience
- **Settings**: Access streaming quality and other settings
- **Help**: View control instructions and shortcuts

## Configuration

### Backend Integration

The app expects a backend server with the following endpoints:

- `POST /api/auth/login` - User authentication
- `POST /api/auth/refresh` - Token refresh
- `POST /api/auth/logout` - User logout
- `GET /api/pcs` - Get user's computers
- `POST /api/pcs` - Add new computer
- `PUT /api/pcs/{id}` - Update computer
- `DELETE /api/pcs/{id}` - Delete computer
- `POST /api/pcs/{id}/connect` - Request connection
- `GET /api/signaling/{sessionId}` - Get signaling data
- `POST /api/signaling/{sessionId}` - Send signaling data

### WebRTC Configuration

WebRTC settings can be configured in `lib/utils/constants.dart`:

- ICE servers (STUN/TURN)
- Media constraints
- Connection timeouts

## Development

### Code Generation

The project uses JSON serialization. After modifying models, run:

```bash
flutter packages pub run build_runner build
```

### Testing

```bash
flutter test
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Security Features

- **End-to-end encryption**: WebRTC DTLS-SRTP
- **Secure token storage**: flutter_secure_storage
- **HTTPS communication**: All API calls use HTTPS
- **Input validation**: Form validation and sanitization
- **Session management**: Automatic token refresh and logout

## Performance Optimizations

- **Hardware acceleration**: WebRTC uses hardware encoders/decoders
- **Efficient state management**: Provider pattern with minimal rebuilds
- **Image caching**: Cached network images
- **Lazy loading**: Load data only when needed
- **Connection pooling**: Reuse HTTP connections

## Troubleshooting

### Common Issues

1. **Connection Failed**

   - Check backend server is running
   - Verify network connectivity
   - Check firewall settings

2. **WebRTC Issues**

   - Ensure STUN/TURN servers are configured
   - Check browser permissions for camera/microphone
   - Verify WebRTC is supported on the platform

3. **Authentication Errors**
   - Verify backend URL is correct
   - Check token expiration
   - Clear app data and re-login

### Debug Mode

The app includes demo credentials in debug mode:

- Email: `demo@example.com`
- Password: `password123`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:

- Create an issue in the repository
- Check the troubleshooting section
- Review the backend documentation

## Roadmap

- [ ] File transfer support
- [ ] Clipboard synchronization
- [ ] Multi-monitor support
- [ ] Audio streaming
- [ ] Mobile-specific optimizations
- [ ] Offline mode
- [ ] Push notifications
- [ ] Advanced security features
