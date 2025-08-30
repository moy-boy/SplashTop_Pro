import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:typed_data';
import '../models/pc.dart';
import '../utils/constants.dart';

class StreamingScreen extends StatefulWidget {
  final PC? pc;

  const StreamingScreen({super.key, this.pc});

  @override
  State<StreamingScreen> createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen> {
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer? _remoteRenderer;
  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
    if (widget.pc != null) {
      _connectToPC();
    }
  }

  Future<void> _initializeRenderer() async {
    _remoteRenderer = RTCVideoRenderer();
    await _remoteRenderer!.initialize();
  }

  Future<void> _connectToPC() async {
    if (!mounted) return;
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
      _errorMessage = '';
    });

    try {
      // Connect to signaling server
      _socket = IO.io(AppConfig.serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket!.onConnect((_) {
        print('Connected to signaling server');
        _registerAsClient();
      });

      _socket!.onDisconnect((_) {
        if (mounted) {
          setState(() {
            _connectionStatus = 'Disconnected';
            _isConnected = false;
            _isConnecting = false;
          });
        }
      });

      _socket!.on('offer', (data) {
        _handleOffer(data);
      });

      _socket!.on('answer', (data) {
        _handleAnswer(data);
      });

      _socket!.on('ice-candidate', (data) {
        _handleIceCandidate(data);
      });

      _socket!.on('connected', (data) {
        if (mounted) {
          setState(() {
            _connectionStatus = 'Connected to streamer';
            _isConnected = true;
            _isConnecting = false;
          });
        }
      });

      _socket!.on('error', (data) {
        if (mounted) {
          setState(() {
            _errorMessage = data['message'] ?? 'Unknown error';
            _connectionStatus = 'Error';
            _isConnecting = false;
          });
        }
      });

      // Create peer connection
      await _createPeerConnection();

      // Request connection to streamer
      _socket!.emit('connect-request', {
        'streamerId': widget.pc!.deviceId,
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error: $e';
          _connectionStatus = 'Connection failed';
          _isConnecting = false;
        });
      }
    }
  }

  void _registerAsClient() {
    _socket!.emit('register', {
      'type': 'client',
      'userId': 'user-id', // TODO: Get from auth provider
    });
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': WebRTCConfig.iceServers,
    };

    _peerConnection = await createPeerConnection(configuration, {});

    // Set up event handlers
    _peerConnection!.onIceCandidate = (candidate) {
      _socket!.emit('ice-candidate', {
        'candidate': candidate.toMap(),
        'target': widget.pc!.deviceId,
      });
    };

    _peerConnection!.onConnectionState = (state) {
      if (mounted) {
        setState(() {
          switch (state) {
            case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
              _connectionStatus = 'Connected';
              _isConnected = true;
              break;
            case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
              _connectionStatus = 'Disconnected';
              _isConnected = false;
              break;
            case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
              _connectionStatus = 'Connection failed';
              _isConnected = false;
              break;
            default:
              _connectionStatus = 'Connecting...';
          }
          _isConnecting = false;
        });
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteRenderer!.srcObject = event.streams[0];
      }
    };
  }

  Future<void> _handleOffer(dynamic data) async {
    try {
      final offer = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      await _peerConnection!.setRemoteDescription(offer);

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _socket!.emit('answer', {
        'answer': answer.toMap(),
        'target': data['from'],
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to handle offer: $e';
        });
      }
    }
  }

  Future<void> _handleAnswer(dynamic data) async {
    try {
      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _peerConnection!.setRemoteDescription(answer);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to handle answer: $e';
        });
      }
    }
  }

  Future<void> _handleIceCandidate(dynamic data) async {
    try {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to handle ICE candidate: $e';
        });
      }
    }
  }

  void _sendInputEvent(String type, Map<String, dynamic> data) {
    if (_isConnected && _peerConnection != null) {
      // Send input event via WebRTC data channel
      // This is a simplified version - you'll need to implement data channel
      print('Sending input event: $type - $data');
    }
  }

  void _disconnect() {
    _socket?.disconnect();
    _peerConnection?.close();
    if (mounted) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Disconnected';
        _errorMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pc?.name ?? 'Remote Desktop'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.stop : Icons.play_arrow),
            onPressed: _isConnected ? _disconnect : _connectToPC,
            tooltip: _isConnected ? 'Disconnect' : 'Connect',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(16),
            color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.warning,
                  color: _isConnected ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _connectionStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isConnected ? Colors.green : Colors.orange,
                        ),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Video display
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isConnected && _remoteRenderer != null
                    ? RTCVideoView(
                        _remoteRenderer!,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      )
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_off,
                                size: 64,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No video stream',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Connect to streamer to view remote desktop',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Control buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isConnected ? () => _sendInputEvent('mouse', {'x': 100, 'y': 100, 'button': 'left'}) : null,
                  icon: const Icon(Icons.mouse),
                  label: const Text('Test Mouse'),
                ),
                ElevatedButton.icon(
                  onPressed: _isConnected ? () => _sendInputEvent('keyboard', {'key': 'A', 'modifiers': []}) : null,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Test Keyboard'),
                ),
                ElevatedButton.icon(
                  onPressed: _isConnected ? () => _sendInputEvent('scroll', {'deltaX': 0, 'deltaY': 100}) : null,
                  icon: const Icon(Icons.mouse_outlined),
                  label: const Text('Test Scroll'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _peerConnection?.close();
    _remoteRenderer?.dispose();
    super.dispose();
  }
}
