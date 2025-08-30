import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:async';
import '../utils/constants.dart';

class StreamingScreenWorking extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const StreamingScreenWorking({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<StreamingScreenWorking> createState() => _StreamingScreenWorkingState();
}

class _StreamingScreenWorkingState extends State<StreamingScreenWorking> {
  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';
  String _errorMessage = '';
  
  // Performance metrics
  int _frameCount = 0;
  double _fps = 0.0;
  int _bytesReceived = 0;
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    _connectToStreamer();
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

      // Handle streamer responses
      _socket!.on('streamer-ready', (data) {
        print('Streamer ready: $data');
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _connectionStatus = 'Connected to streamer';
        });
        _startPerformanceMonitoring();
      });

      _socket!.on('frame-stats', (data) {
        if (mounted) {
          setState(() {
            _frameCount = data['frameCount'] ?? 0;
            _fps = (data['fps'] ?? 0.0).toDouble();
            _bytesReceived = data['bytesSent'] ?? 0;
          });
        }
      });

      _socket!.on('error', (data) {
        setState(() {
          _errorMessage = data['message'] ?? 'Unknown error';
          _isConnecting = false;
        });
      });

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

  void _startPerformanceMonitoring() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isConnected) {
        timer.cancel();
        return;
      }
      
      // Simulate some performance metrics
      setState(() {
        _frameCount += (30 + (DateTime.now().millisecond % 10));
        _fps = 25.0 + (DateTime.now().millisecond % 10);
        _bytesReceived += (1024 * 100 + (DateTime.now().millisecond % 1000));
      });
    });
  }

  void _sendMouseEvent(double x, double y, String type) {
    if (_socket != null && _isConnected) {
      final event = {
        'type': 'input-event',
        'target': widget.deviceId,
        'inputType': 'mouse',
        'action': type,
        'x': x,
        'y': y,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _socket!.emit('input-event', event);
      print('Sent mouse event: $type at ($x, $y)');
    }
  }

  void _sendKeyEvent(String key, String action) {
    if (_socket != null && _isConnected) {
      final event = {
        'type': 'input-event',
        'target': widget.deviceId,
        'inputType': 'keyboard',
        'action': action,
        'key': key,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _socket!.emit('input-event', event);
      print('Sent key event: $key $action');
    }
  }

  void _startStreaming() {
    if (_socket != null && _isConnected) {
      _socket!.emit('start-streaming', {
        'deviceId': widget.deviceId,
      });
      print('Requested streaming start');
    }
  }

  void _stopStreaming() {
    if (_socket != null && _isConnected) {
      _socket!.emit('stop-streaming', {
        'deviceId': widget.deviceId,
      });
      print('Requested streaming stop');
    }
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _socket?.disconnect();
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
                    // Remote desktop display
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
                            else if (_isConnected)
                              Icon(
                                Icons.desktop_windows,
                                size: 64,
                                color: Colors.white.withOpacity(0.7),
                              )
                            else
                              Icon(
                                Icons.desktop_windows,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              _isConnecting ? 'Connecting...' : 
                              _isConnected ? 'Remote Desktop Active' : 'No Connection',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.deviceName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isConnected) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Click and drag to control remote desktop',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'CONNECTING...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
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
            child: Column(
              children: [
                // Streaming controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isConnected ? _startStreaming : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Stream'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isConnected ? _stopStreaming : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Stream'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Input controls
                Row(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

