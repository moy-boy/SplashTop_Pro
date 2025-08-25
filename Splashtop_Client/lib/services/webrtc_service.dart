import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/constants.dart';

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
}

enum StreamType {
  video,
  audio,
  data,
}

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _remoteStream;
  WebSocketChannel? _signalingChannel;
  
  final StreamController<ConnectionState> _connectionStateController = StreamController<ConnectionState>.broadcast();
  final StreamController<MediaStream> _remoteStreamController = StreamController<MediaStream>.broadcast();
  final StreamController<Map<String, dynamic>> _dataChannelController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  ConnectionState _currentState = ConnectionState.disconnected;
  String? _sessionId;
  Timer? _keepAliveTimer;

  // Getters
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<MediaStream> get remoteStreamStream => _remoteStreamController.stream;
  Stream<Map<String, dynamic>> get dataChannelStream => _dataChannelController.stream;
  Stream<String> get errorStream => _errorController.stream;
  ConnectionState get currentState => _currentState;
  MediaStream? get remoteStream => _remoteStream;
  bool get isConnected => _currentState == ConnectionState.connected;

  // Initialize WebRTC connection
  Future<void> initializeConnection(String sessionId, String signalingUrl) async {
    try {
      _sessionId = sessionId;
      _updateConnectionState(ConnectionState.connecting);

      // Create peer connection
      _peerConnection = await createPeerConnection(WebRTCConfig.iceServers);

      // Set up event handlers
      _setupPeerConnectionHandlers();

      // Connect to signaling server
      await _connectToSignalingServer(signalingUrl);

      // Create data channel for input events
      await _createDataChannel();

    } catch (e) {
      _handleError('Failed to initialize connection: ${e.toString()}');
      _updateConnectionState(ConnectionState.failed);
    }
  }

  // Set up peer connection event handlers
  void _setupPeerConnectionHandlers() {
    if (_peerConnection == null) return;

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _sendSignalingMessage({
        'type': 'ice-candidate',
        'candidate': candidate.toMap(),
      });
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _updateConnectionState(ConnectionState.connected);
          _startKeepAlive();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _updateConnectionState(ConnectionState.disconnected);
          _stopKeepAlive();
          break;
        default:
          break;
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
      }
    };
  }

  // Connect to signaling server
  Future<void> _connectToSignalingServer(String signalingUrl) async {
    try {
      _signalingChannel = WebSocketChannel.connect(Uri.parse(signalingUrl));
      
      _signalingChannel!.stream.listen(
        (message) => _handleSignalingMessage(jsonDecode(message)),
        onError: (error) => _handleError('Signaling error: $error'),
        onDone: () => _handleError('Signaling connection closed'),
      );

      // Send join message
      _sendSignalingMessage({
        'type': 'join',
        'sessionId': _sessionId,
      });

    } catch (e) {
      _handleError('Failed to connect to signaling server: ${e.toString()}');
    }
  }

  // Create data channel for input events
  Future<void> _createDataChannel() async {
    if (_peerConnection == null) return;

    try {
      final dataChannelConfig = RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmits = 3;

      _dataChannel = await _peerConnection!.createDataChannel(
        'input',
        dataChannelConfig,
      );

      _dataChannel!.onMessage = (RTCDataChannelMessage message) {
        if (message.isBinary) {
          // Handle binary messages (e.g., file transfers)
          _handleBinaryMessage(message.binary);
        } else {
          // Handle text messages (e.g., JSON commands)
          final data = jsonDecode(message.text);
          _dataChannelController.add(data);
        }
      };

      _dataChannel!.onDataChannelState = (RTCDataChannelState state) {
        if (state == RTCDataChannelState.RTCDataChannelClosed) {
          _dataChannel = null;
        }
      };
    } catch (e) {
      _handleError('Failed to create data channel: ${e.toString()}');
    }
  }

  // Handle incoming signaling messages
  void _handleSignalingMessage(Map<String, dynamic> message) {
    final type = message['type'];
    
    switch (type) {
      case 'offer':
        _handleOffer(message);
        break;
      case 'answer':
        _handleAnswer(message);
        break;
      case 'ice-candidate':
        _handleIceCandidate(message);
        break;
      case 'error':
        _handleError(message['message'] ?? 'Unknown error');
        break;
      default:
        print('Unknown signaling message type: $type');
    }
  }

  // Handle incoming offer
  Future<void> _handleOffer(Map<String, dynamic> message) async {
    if (_peerConnection == null) return;

    try {
      final offer = RTCSessionDescription(
        message['sdp']['sdp'],
        message['sdp']['type'],
      );

      await _peerConnection!.setRemoteDescription(offer);

      // Create answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Send answer
      _sendSignalingMessage({
        'type': 'answer',
        'sdp': answer.toMap(),
      });

    } catch (e) {
      _handleError('Failed to handle offer: ${e.toString()}');
    }
  }

  // Handle incoming answer
  Future<void> _handleAnswer(Map<String, dynamic> message) async {
    if (_peerConnection == null) return;

    try {
      final answer = RTCSessionDescription(
        message['sdp']['sdp'],
        message['sdp']['type'],
      );

      await _peerConnection!.setRemoteDescription(answer);

    } catch (e) {
      _handleError('Failed to handle answer: ${e.toString()}');
    }
  }

  // Handle incoming ICE candidate
  Future<void> _handleIceCandidate(Map<String, dynamic> message) async {
    if (_peerConnection == null) return;

    try {
      final candidate = RTCIceCandidate(
        message['candidate']['candidate'],
        message['candidate']['sdpMid'],
        message['candidate']['sdpMLineIndex'],
      );

      await _peerConnection!.addCandidate(candidate);

    } catch (e) {
      _handleError('Failed to handle ICE candidate: ${e.toString()}');
    }
  }

  // Send signaling message
  void _sendSignalingMessage(Map<String, dynamic> message) {
    if (_signalingChannel != null) {
      _signalingChannel!.sink.add(jsonEncode(message));
    }
  }

  // Send input event via data channel
  void sendInputEvent(Map<String, dynamic> event) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      try {
        final message = jsonEncode(event);
        _dataChannel!.send(RTCDataChannelMessage(message));
      } catch (e) {
        _handleError('Failed to send input event: ${e.toString()}');
      }
    }
  }

  // Send mouse event
  void sendMouseEvent({
    required String type, // 'move', 'click', 'scroll'
    required double x,
    required double y,
    int? button, // 0: left, 1: middle, 2: right
    bool? pressed,
    double? deltaX,
    double? deltaY,
  }) {
    sendInputEvent({
      'type': 'mouse',
      'action': type,
      'x': x,
      'y': y,
      if (button != null) 'button': button,
      if (pressed != null) 'pressed': pressed,
      if (deltaX != null) 'deltaX': deltaX,
      if (deltaY != null) 'deltaY': deltaY,
    });
  }

  // Send keyboard event
  void sendKeyboardEvent({
    required String type, // 'keydown', 'keyup'
    required String key,
    bool? ctrl,
    bool? alt,
    bool? shift,
    bool? meta,
  }) {
    sendInputEvent({
      'type': 'keyboard',
      'action': type,
      'key': key,
      if (ctrl != null) 'ctrl': ctrl,
      if (alt != null) 'alt': alt,
      if (shift != null) 'shift': shift,
      if (meta != null) 'meta': meta,
    });
  }

  // Send touch event
  void sendTouchEvent({
    required String type, // 'start', 'move', 'end'
    required double x,
    required double y,
    int? touchId,
  }) {
    sendInputEvent({
      'type': 'touch',
      'action': type,
      'x': x,
      'y': y,
      if (touchId != null) 'touchId': touchId,
    });
  }

  // Handle binary messages
  void _handleBinaryMessage(Uint8List data) {
    // Handle binary data (e.g., clipboard data, file transfers)
    _dataChannelController.add({
      'type': 'binary',
      'data': data,
    });
  }

  // Update connection state
  void _updateConnectionState(ConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  // Handle errors
  void _handleError(String error) {
    print('WebRTC Error: $error');
    _errorController.add(error);
  }

  // Start keep-alive timer
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
        sendInputEvent({'type': 'keepalive'});
      }
    });
  }

  // Stop keep-alive timer
  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  // Disconnect and cleanup
  Future<void> disconnect() async {
    try {
      _updateConnectionState(ConnectionState.disconnected);
      _stopKeepAlive();

      // Close data channel
      await _dataChannel?.close();
      _dataChannel = null;

      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;

      // Close signaling connection
      await _signalingChannel?.sink.close();
      _signalingChannel = null;

      // Clear remote stream
      _remoteStream = null;

    } catch (e) {
      _handleError('Error during disconnect: ${e.toString()}');
    }
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _remoteStreamController.close();
    _dataChannelController.close();
    _errorController.close();
  }
}
