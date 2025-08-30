import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:typed_data';
import '../utils/constants.dart';
import 'dart:async'; // Added for Timer

class StreamingScreenReal extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const StreamingScreenReal({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<StreamingScreenReal> createState() => _StreamingScreenRealState();
}

class _StreamingScreenRealState extends State<StreamingScreenReal> {
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer? _remoteRenderer;
  IO.Socket? _socket;
  RTCDataChannel? _dataChannel;
  
  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';
  String _errorMessage = '';
  
  // Performance metrics
  int _frameCount = 0;
  double _fps = 0.0;
  DateTime? _lastFrameTime;
  int _bytesReceived = 0;

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
    _connectToStreamer();
  }

  Future<void> _initializeRenderer() async {
    _remoteRenderer = RTCVideoRenderer();
    await _remoteRenderer!.initialize();
  }

  Future<void> _connectToStreamer() async {
    if (!mounted) return;

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting to streamer...';
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
        print('Disconnected from signaling server');
        setState(() {
          _isConnected = false;
          _connectionStatus = 'Disconnected';
        });
      });

      // WebRTC signaling events
      _socket!.on('offer', _handleOffer);
      _socket!.on('answer', _handleAnswer);
      _socket!.on('ice-candidate', _handleIceCandidate);
      _socket!.on('streamer-ready', _handleStreamerReady);

    } catch (e) {
      setState(() {
        _errorMessage = 'Connection failed: $e';
        _isConnecting = false;
      });
    }
  }

  void _registerAsClient() {
    _socket!.emit('register', {
      'type': 'client',
      'userId': 'demo-user',
      'deviceId': widget.deviceId,
    });
  }

  void _handleStreamerReady(dynamic data) {
    print('Streamer ready, creating peer connection');
    _createPeerConnection();
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': WebRTCConfig.iceServers,
      'sdpSemantics': 'unified-plan',
    };

    final constraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    _peerConnection = await createPeerConnection(configuration, constraints);

    // Set up event handlers
    _peerConnection!.onIceCandidate = (candidate) {
      _socket!.emit('ice-candidate', {
        'candidate': candidate.toMap(),
        'target': widget.deviceId,
      });
    };

    _peerConnection!.onConnectionState = (state) {
      if (mounted) {
        setState(() {
          switch (state) {
            case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
              _connectionStatus = 'Connected';
              _isConnected = true;
              _isConnecting = false;
              break;
            case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
              _connectionStatus = 'Disconnected';
              _isConnected = false;
              break;
            case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
              _connectionStatus = 'Connection failed';
              _isConnected = false;
              _isConnecting = false;
              break;
            default:
              _connectionStatus = 'Connecting...';
          }
        });
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteRenderer!.srcObject = event.streams[0];
        _startPerformanceMonitoring();
      }
    };

    // Create data channel for input events
    _dataChannel = await _peerConnection!.createDataChannel(
      'input',
      RTCDataChannelInit()..ordered = true,
    );

    _dataChannel!.onMessage = (message) {
      // Handle any messages from streamer
      print('Received message from streamer: ${message.text}');
    };

    // Create offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _socket!.emit('offer', {
      'offer': offer.toMap(),
      'target': widget.deviceId,
    });
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
      setState(() {
        _errorMessage = 'Failed to handle offer: $e';
      });
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
      setState(() {
        _errorMessage = 'Failed to handle answer: $e';
      });
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
      setState(() {
        _errorMessage = 'Failed to handle ICE candidate: $e';
      });
    }
  }

  void _startPerformanceMonitoring() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isConnected) {
        timer.cancel();
        return;
      }

      // Get WebRTC stats
      _peerConnection!.getStats().then((stats) {
        stats.forEach((report) {
          if (report.type == 'inbound-rtp') {
            // Extract stats from the report values
            final values = report.values;
            if (values.containsKey('mediaType') && values['mediaType'] == 'video') {
              setState(() {
                _frameCount = int.tryParse(values['framesReceived'] ?? '0') ?? 0;
                _fps = double.tryParse(values['framesPerSecond'] ?? '0.0') ?? 0.0;
                _bytesReceived = int.tryParse(values['bytesReceived'] ?? '0') ?? 0;
              });
            }
          }
        });
      });
    });
  }

  void _sendMouseEvent(double x, double y, String type) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      final event = {
        'type': 'mouse',
        'action': type,
        'x': x,
        'y': y,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _dataChannel!.send(RTCDataChannelMessage(jsonEncode(event)));
    }
  }

  void _sendKeyEvent(String key, String action) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      final event = {
        'type': 'keyboard',
        'action': action,
        'key': key,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _dataChannel!.send(RTCDataChannelMessage(jsonEncode(event)));
    }
  }

  void _sendTextInput(String text) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      final event = {
        'type': 'text',
        'text': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _dataChannel!.send(RTCDataChannelMessage(jsonEncode(event)));
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _peerConnection?.close();
    _remoteRenderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remote Desktop - ${widget.deviceName}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.wifi : Icons.wifi_off),
            onPressed: null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(16),
            color: _isConnected ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error,
                  color: _isConnected ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _connectionStatus,
                    style: TextStyle(
                      color: _isConnected ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isConnected) ...[
                  Text(
                    'FPS: ${_fps.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Frames: $_frameCount',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Data: ${(_bytesReceived / 1024 / 1024).toStringAsFixed(1)} MB',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),

          // Error message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          // Remote desktop area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Real remote desktop video
                    if (_isConnected && _remoteRenderer != null)
                      RTCVideoView(
                        _remoteRenderer!,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isConnecting)
                                const CircularProgressIndicator(color: Colors.white)
                              else
                                Icon(
                                  Icons.desktop_windows,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              const SizedBox(height: 16),
                              Text(
                                _isConnecting ? 'Connecting...' : 'No Video Stream',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Mouse overlay for interaction (only when connected)
                    if (_isConnected)
                      Positioned.fill(
                        child: GestureDetector(
                          onTapDown: (details) {
                            final box = context.findRenderObject() as RenderBox;
                            final localPosition = box.globalToLocal(details.globalPosition);
                            final x = localPosition.dx / box.size.width;
                            final y = localPosition.dy / box.size.height;
                            _sendMouseEvent(x, y, 'down');
                          },
                          onTapUp: (details) {
                            final box = context.findRenderObject() as RenderBox;
                            final localPosition = box.globalToLocal(details.globalPosition);
                            final x = localPosition.dx / box.size.width;
                            final y = localPosition.dy / box.size.height;
                            _sendMouseEvent(x, y, 'up');
                          },
                          onPanUpdate: (details) {
                            final box = context.findRenderObject() as RenderBox;
                            final localPosition = box.globalToLocal(details.globalPosition);
                            final x = localPosition.dx / box.size.width;
                            final y = localPosition.dy / box.size.height;
                            _sendMouseEvent(x, y, 'move');
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Control panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isConnected ? () => _sendKeyEvent('ctrl+alt+del', 'down') : null,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Ctrl+Alt+Del'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isConnected ? () => _sendKeyEvent('win', 'down') : null,
                  icon: const Icon(Icons.window),
                  label: const Text('Windows'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isConnected ? () => _sendKeyEvent('esc', 'down') : null,
                  icon: const Icon(Icons.keyboard_return),
                  label: const Text('Escape'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
