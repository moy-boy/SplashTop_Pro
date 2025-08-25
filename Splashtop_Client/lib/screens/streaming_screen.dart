import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/pc.dart';
import '../services/webrtc_service.dart' as webrtc;
import '../utils/constants.dart';

class StreamingScreen extends StatefulWidget {
  final PC pc;
  final Map<String, dynamic> connectionData;

  const StreamingScreen({
    super.key,
    required this.pc,
    required this.connectionData,
  });

  @override
  State<StreamingScreen> createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen> {
  final webrtc.WebRTCService _webrtcService = webrtc.WebRTCService();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  
  bool _isInitialized = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeStreaming();
  }

  Future<void> _initializeStreaming() async {
    try {
      // Initialize video renderer
      await _remoteRenderer.initialize();
      
      // Set up WebRTC service listeners
              _webrtcService.remoteStreamStream.listen((stream) {
          _remoteRenderer.srcObject = stream;
        });

      _webrtcService.connectionStateStream.listen((state) {
        if (mounted) {
          setState(() {
            if (state == webrtc.ConnectionState.failed) {
              _errorMessage = 'Connection failed';
            }
          });
        }
      });

      _webrtcService.errorStream.listen((error) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
          });
        }
      });

      // Initialize WebRTC connection
      final sessionId = widget.connectionData['sessionId'];
      final signalingUrl = widget.connectionData['signalingUrl'];
      
      await _webrtcService.initializeConnection(sessionId, signalingUrl);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize streaming: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _webrtcService.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _disconnect() {
    _webrtcService.disconnect();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isFullscreen ? _buildFullscreenView() : _buildNormalView(),
    );
  }

  Widget _buildNormalView() {
    return Column(
      children: [
        // App Bar
        if (_showControls)
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _disconnect,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pc.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.pc.platform.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: _toggleFullscreen,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _disconnect,
                ),
              ],
            ),
          ),
        
        // Video Stream
        Expanded(
          child: _buildVideoStream(),
        ),
        
        // Control Bar
        if (_showControls)
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.mouse,
                  label: 'Mouse',
                  onPressed: () => _showMouseControls(),
                ),
                _buildControlButton(
                  icon: Icons.keyboard,
                  label: 'Keyboard',
                  onPressed: () => _showKeyboardControls(),
                ),
                _buildControlButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onPressed: () => _showSettings(),
                ),
                _buildControlButton(
                  icon: Icons.help,
                  label: 'Help',
                  onPressed: () => _showHelp(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFullscreenView() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // Video Stream (full screen)
          _buildVideoStream(),
          
          // Fullscreen Controls
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                      onPressed: _toggleFullscreen,
                    ),
                    Expanded(
                      child: Text(
                        widget.pc.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _disconnect,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoStream() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _disconnect,
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Connecting...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _isFullscreen ? _toggleControls : null,
      onPanUpdate: _handleMouseMove,
      onTapDown: _handleMouseClick,
      onSecondaryTapDown: _handleRightClick,
      child: RTCVideoView(
        _remoteRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _handleMouseMove(DragUpdateDetails details) {
    if (!_webrtcService.isConnected) return;
    
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;
    
    // Convert to relative coordinates (0-1)
    final relativeX = localPosition.dx / size.width;
    final relativeY = localPosition.dy / size.height;
    
    _webrtcService.sendMouseEvent(
      type: 'move',
      x: relativeX,
      y: relativeY,
    );
  }

  void _handleMouseClick(TapDownDetails details) {
    if (!_webrtcService.isConnected) return;
    
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;
    
    final relativeX = localPosition.dx / size.width;
    final relativeY = localPosition.dy / size.height;
    
    _webrtcService.sendMouseEvent(
      type: 'click',
      x: relativeX,
      y: relativeY,
      button: 0, // Left click
      pressed: true,
    );
    
    // Send release event after a short delay
    Future.delayed(const Duration(milliseconds: 50), () {
      _webrtcService.sendMouseEvent(
        type: 'click',
        x: relativeX,
        y: relativeY,
        button: 0,
        pressed: false,
      );
    });
  }

  void _handleRightClick(TapDownDetails details) {
    if (!_webrtcService.isConnected) return;
    
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;
    
    final relativeX = localPosition.dx / size.width;
    final relativeY = localPosition.dy / size.height;
    
    _webrtcService.sendMouseEvent(
      type: 'click',
      x: relativeX,
      y: relativeY,
      button: 2, // Right click
      pressed: true,
    );
    
    Future.delayed(const Duration(milliseconds: 50), () {
      _webrtcService.sendMouseEvent(
        type: 'click',
        x: relativeX,
        y: relativeY,
        button: 2,
        pressed: false,
      );
    });
  }

  void _showMouseControls() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mouse Controls'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Tap to left-click'),
            Text('• Long press to right-click'),
            Text('• Drag to move mouse'),
            Text('• Scroll with two fingers'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showKeyboardControls() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Controls'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Use on-screen keyboard'),
            Text('• Or connect external keyboard'),
            Text('• Common shortcuts:'),
            Text('  - Ctrl+Alt+Del: Task Manager'),
            Text('  - Alt+Tab: Switch windows'),
            Text('  - Win+L: Lock screen'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Streaming Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: Add quality settings, audio toggle, etc.
            Text('Settings coming soon...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remote Desktop Controls:'),
            SizedBox(height: 8),
            Text('• Tap to left-click'),
            Text('• Long press to right-click'),
            Text('• Drag to move mouse'),
            Text('• Use fullscreen for better experience'),
            SizedBox(height: 8),
            Text('Keyboard Shortcuts:'),
            Text('• Ctrl+Alt+Del: Task Manager'),
            Text('• Alt+Tab: Switch windows'),
            Text('• Win+L: Lock screen'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
