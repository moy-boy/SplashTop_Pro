import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class WebRTCServiceSimple {
  IO.Socket? _socket;
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  bool _isConnected = false;

  // Callbacks
  Function(Map<String, dynamic>)? onConnectionStateChanged;
  Function(Map<String, dynamic>)? onStreamData;
  Function(Map<String, dynamic>)? onInputEvent;

  bool get isConnected => _isConnected;

  // Initialize WebSocket connection
  Future<void> connect(String serverUrl) async {
    try {
      _socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket!.onConnect((_) {
        _isConnected = true;
        onConnectionStateChanged?.call({'connected': true});
        print('WebRTC: Connected to signaling server');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        onConnectionStateChanged?.call({'connected': false});
        print('WebRTC: Disconnected from signaling server');
      });

      _socket!.on('offer', (data) {
        print('WebRTC: Received offer');
        // Handle WebRTC offer
      });

      _socket!.on('answer', (data) {
        print('WebRTC: Received answer');
        // Handle WebRTC answer
      });

      _socket!.on('ice-candidate', (data) {
        print('WebRTC: Received ICE candidate');
        // Handle ICE candidate
      });

      _socket!.on('stream-data', (data) {
        print('WebRTC: Received stream data');
        onStreamData?.call(data);
      });

    } catch (e) {
      print('WebRTC: Connection failed: $e');
      _isConnected = false;
      onConnectionStateChanged?.call({'connected': false, 'error': e.toString()});
    }
  }

  // Register as client
  Future<void> registerAsClient(String userId) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('register', {
        'type': 'client',
        'userId': userId,
      });
      print('WebRTC: Registered as client');
    }
  }

  // Register as streamer
  Future<void> registerAsStreamer(String deviceId) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('register', {
        'type': 'streamer',
        'deviceId': deviceId,
      });
      print('WebRTC: Registered as streamer');
    }
  }

  // Request connection to streamer
  Future<void> requestConnection(String streamerId) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('connect-request', {
        'streamerId': streamerId,
      });
      print('WebRTC: Requested connection to streamer: $streamerId');
    }
  }

  // Send WebRTC offer
  Future<void> sendOffer(Map<String, dynamic> offer, String target) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('offer', {
        'offer': offer,
        'target': target,
      });
      print('WebRTC: Sent offer to $target');
    }
  }

  // Send WebRTC answer
  Future<void> sendAnswer(Map<String, dynamic> answer, String target) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('answer', {
        'answer': answer,
        'target': target,
      });
      print('WebRTC: Sent answer to $target');
    }
  }

  // Send ICE candidate
  Future<void> sendIceCandidate(Map<String, dynamic> candidate, String target) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('ice-candidate', {
        'candidate': candidate,
        'target': target,
      });
      print('WebRTC: Sent ICE candidate to $target');
    }
  }

  // Send input event
  Future<void> sendInputEvent(Map<String, dynamic> event) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('input-event', event);
      print('WebRTC: Sent input event: ${event['type']}');
    }
  }

  // Simulate video stream (for demo purposes)
  void startSimulatedStream() {
    Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (_isConnected) {
        final frameData = {
          'type': 'frame',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'frameNumber': timer.tick,
          'width': 1920,
          'height': 1080,
          'data': 'simulated_frame_data_${timer.tick}',
        };
        onStreamData?.call(frameData);
      } else {
        timer.cancel();
      }
    });
  }

  // Disconnect
  Future<void> disconnect() async {
    _isConnected = false;
    _socket?.disconnect();
    _socket?.dispose();
    _channel?.sink.close();
    _messageController?.close();
    print('WebRTC: Disconnected');
  }
}
