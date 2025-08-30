# SplashTop Backend Server

A NestJS-based backend server for SplashTop remote desktop application providing authentication, signaling, and relay services.

## Features

- **Authentication**: JWT-based authentication with user registration/login
- **WebRTC Signaling**: WebSocket-based signaling for peer-to-peer connections
- **Database**: PostgreSQL for user and streamer management
- **Real-time Communication**: Socket.IO for WebRTC signaling
- **Security**: Password hashing, JWT tokens, CORS protection

## Tech Stack

- **Framework**: NestJS (Node.js)
- **Database**: PostgreSQL with TypeORM
- **Authentication**: JWT + Passport
- **WebSockets**: Socket.IO
- **Validation**: class-validator
- **Security**: bcryptjs for password hashing

## Quick Start

### Prerequisites

- Node.js 18+
- PostgreSQL
- npm or yarn

### Installation

1. **Clone and navigate to server directory:**
   ```bash
   cd Splashtop-Server
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up environment:**
   ```bash
   cp env.example .env
   # Edit .env with your database credentials
   ```

4. **Set up PostgreSQL database:**
   ```sql
   CREATE DATABASE splashtop;
   CREATE USER splashtop_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE splashtop TO splashtop_user;
   ```

5. **Run the server:**
   ```bash
   # Development mode
   npm run start:dev
   
   # Production mode
   npm run build
   npm run start:prod
   ```

## API Endpoints

### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `GET /auth/profile` - Get user profile (protected)

### Users
- `GET /users` - Get all users (protected)
- `GET /users/profile` - Get current user profile (protected)

### Streamers
- `GET /streamers/my-pcs` - Get user's registered PCs (protected)
- `POST /streamers/register` - Register a new streamer (protected)
- `GET /streamers` - Get all streamers (protected)

## WebSocket Events

### Client Registration
```javascript
// Register as client
socket.emit('register', {
  type: 'client',
  userId: 'user-id'
});

// Register as streamer
socket.emit('register', {
  type: 'streamer',
  deviceId: 'unique-device-id',
  userId: 'user-id'
});
```

### WebRTC Signaling
```javascript
// Send offer
socket.emit('offer', {
  offer: rtcOffer,
  target: 'target-client-id'
});

// Send answer
socket.emit('answer', {
  answer: rtcAnswer,
  target: 'target-client-id'
});

// Send ICE candidate
socket.emit('ice-candidate', {
  candidate: iceCandidate,
  target: 'target-client-id'
});
```

### Connection Request
```javascript
// Request connection to streamer
socket.emit('connect-request', {
  streamerId: 'streamer-device-id'
});
```

## Database Schema

### Users Table
- `id` (UUID, Primary Key)
- `email` (String, Unique)
- `password` (String, Hashed)
- `firstName` (String)
- `lastName` (String)
- `role` (Enum: USER, ADMIN)
- `isEmailVerified` (Boolean)
- `deviceId` (String, Nullable)
- `createdAt` (Timestamp)
- `updatedAt` (Timestamp)

### Streamers Table
- `id` (UUID, Primary Key)
- `name` (String)
- `deviceId` (String, Unique)
- `platform` (Enum: WINDOWS, MACOS, LINUX)
- `status` (Enum: OFFLINE, ONLINE, STREAMING)
- `ipAddress` (String, Nullable)
- `lastSeen` (Timestamp, Nullable)
- `version` (String, Nullable)
- `capabilities` (JSON, Nullable)
- `userId` (UUID, Foreign Key)
- `createdAt` (Timestamp)
- `updatedAt` (Timestamp)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | PostgreSQL host | localhost |
| `DB_PORT` | PostgreSQL port | 5432 |
| `DB_USERNAME` | Database username | postgres |
| `DB_PASSWORD` | Database password | password |
| `DB_NAME` | Database name | splashtop |
| `JWT_SECRET` | JWT signing secret | your-secret-key |
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |

## Development

### Scripts
- `npm run start:dev` - Start in development mode with hot reload
- `npm run build` - Build for production
- `npm run start:prod` - Start production server
- `npm run test` - Run tests
- `npm run lint` - Run linter

### Project Structure
```
src/
├── auth/           # Authentication module
├── users/          # User management
├── streamers/      # Streamer management
├── webrtc/         # WebRTC signaling
├── common/         # Shared utilities
├── app.module.ts   # Main application module
└── main.ts         # Application entry point
```

## Security Features

- **Password Hashing**: bcryptjs with salt rounds
- **JWT Authentication**: Secure token-based authentication
- **CORS Protection**: Configurable CORS settings
- **Input Validation**: class-validator for request validation
- **SQL Injection Protection**: TypeORM parameterized queries

## Production Deployment

1. **Set environment variables** for production
2. **Use HTTPS** in production
3. **Set up proper CORS** origins
4. **Use strong JWT secret**
5. **Enable database SSL** if required
6. **Set up monitoring** and logging

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check PostgreSQL is running
   - Verify database credentials in `.env`
   - Ensure database exists

2. **JWT Token Issues**
   - Check JWT_SECRET is set
   - Verify token expiration

3. **WebSocket Connection Issues**
   - Check CORS settings
   - Verify client is sending correct events

## License

This project is part of the SplashTop remote desktop application.
