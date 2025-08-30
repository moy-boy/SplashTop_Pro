import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pc_list_provider.dart';
import '../services/webrtc_service_simple.dart';
import '../utils/constants.dart';

class StreamingScreenSimple extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const StreamingScreenSimple({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<StreamingScreenSimple> createState() => _StreamingScreenSimpleState();
}

class _StreamingScreenSimpleState extends State<StreamingScreenSimple> {
  final WebRTCServiceSimple _webrtcService = WebRTCServiceSimple();
  bool _isConnected = false;
  bool _isStreaming = false;
  String _status = 'Connecting...';
  int _frameCount = 0;
  double _fps = 0.0;
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    _initializeWebRTC();
  }

  Future<void> _initializeWebRTC() async {
    // Set up callbacks
    _webrtcService.onConnectionStateChanged = (data) {
      if (mounted) {
        setState(() {
          _isConnected = data['connected'] ?? false;
          _status = _isConnected ? 'Connected' : 'Disconnected';
        });
      }
    };

    _webrtcService.onStreamData = (data) {
      if (mounted) {
        setState(() {
          _frameCount++;
          final now = DateTime.now();
          if (_lastFrameTime != null) {
            final duration = now.difference(_lastFrameTime!).inMilliseconds;
            if (duration > 0) {
              _fps = 1000.0 / duration;
            }
          }
          _lastFrameTime = now;
          _isStreaming = true;
        });
      }
    };

    // Connect to signaling server
    await _webrtcService.connect(AppConfig.serverUrl);
    
    // Register as client
    await _webrtcService.registerAsClient('demo-user');
    
    // Request connection to streamer
    await _webrtcService.requestConnection(widget.deviceId);
  }

  void _sendMouseEvent(double x, double y, String type) {
    final event = {
      'type': 'mouse',
      'action': type,
      'x': x,
      'y': y,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _webrtcService.sendInputEvent(event);
  }

  void _sendKeyEvent(String key, String type) {
    final event = {
      'type': 'keyboard',
      'action': type,
      'key': key,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _webrtcService.sendInputEvent(event);
  }

  @override
  void dispose() {
    _webrtcService.disconnect();
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
                    _status,
                    style: TextStyle(
                      color: _isConnected ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isStreaming) ...[
                  Text(
                    'FPS: ${_fps.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Frames: $_frameCount',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
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
              child: Stack(
                children: [
                  // Simulated remote desktop
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
                          Icon(
                            Icons.desktop_windows,
                            size: 64,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Remote Desktop',
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
                          if (_isStreaming) ...[
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

                  // Mouse overlay for interaction
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
                  onPressed: () => _sendKeyEvent('ctrl+alt+del', 'down'),
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Ctrl+Alt+Del'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendKeyEvent('win', 'down'),
                  icon: const Icon(Icons.window),
                  label: const Text('Windows'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendKeyEvent('esc', 'down'),
                  icon: const Icon(Icons.escape),
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
