import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scribble/scribble.dart';
import 'websocket_service.dart';

class GamePage extends StatefulWidget {
  final WebSocketService wsService;
  final String braceletId;
  final String question;

  const GamePage({
    super.key,
    required this.wsService,
    required this.braceletId,
    required this.question,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late ScribbleNotifier _notifier;
  StreamSubscription<dynamic>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  Color _selectedColor = Colors.black;
  double _selectedWidth = 5.0;
  bool _isErasing = false;
  bool _canUndo = false;
  bool _canRedo = false;
  String? _lastStrokeJson;

  @override
  void initState() {
    super.initState();
    _notifier = ScribbleNotifier();
    _listenToWebSocket();
    _notifier.addListener(_onScribbleChanged);
    _updateUndoRedo();
  }

  void _onScribbleChanged() {
    if (!mounted) return;
    final state = _notifier.value;
    setState(() {
      _isErasing = state is Erasing;
      if (state is Drawing) {
        _selectedColor = Color(state.selectedColor);
      }
      _selectedWidth = state.selectedWidth;
    });
    _updateUndoRedo();
    _sendDrawData();
  }

  void _sendDrawData() {
    final sketchJson = jsonEncode(_notifier.currentSketch.toJson());
    if (sketchJson == _lastStrokeJson) return;
    _lastStrokeJson = sketchJson;

    final url =
        'http://${widget.wsService.serverAddress}:${widget.wsService.serverPort}/api/draw';
    http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'stroke': sketchJson}),
    );
  }

  void _updateUndoRedo() {
    if (!mounted) return;
    setState(() {
      _canUndo = _notifier.canUndo;
      _canRedo = _notifier.canRedo;
    });
  }

  void _listenToWebSocket() {
    _messageSubscription = widget.wsService.messageStream.listen((data) {
      if (data is List && data.length == 1 && data[0] == 2) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      }
    });

    _connectionSubscription = widget.wsService.connectionStream.listen((
      isConnected,
    ) {
      if (!mounted) return;
      if (isConnected) {
        _showConnectionSnackBar('连接已恢复', isError: false);
      } else {
        _showConnectionSnackBar('连接断开');
      }
    });
  }

  void _showConnectionSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifier.removeListener(_onScribbleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF3B82F6);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildToolbar(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.white,
                      child: Scribble(notifier: _notifier, drawPen: true),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildColorToolbar(),
        const SizedBox(width: 16),
        _buildStrokeToolbar(),
        const SizedBox(width: 16),
        _buildActionToolbar(),
      ],
    );
  }

  Widget _buildColorToolbar() {
    const colors = [
      Colors.black,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < colors.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              _notifier.setColor(colors[i]);
              setState(() {
                _selectedColor = colors[i];
                _isErasing = false;
              });
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedColor == colors[i] && !_isErasing
                      ? Colors.blue
                      : Colors.grey[400]!,
                  width: _selectedColor == colors[i] && !_isErasing ? 3 : 1,
                ),
                boxShadow: _selectedColor == colors[i] && !_isErasing
                    ? [
                        BoxShadow(
                          color: colors[i].withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            _notifier.setEraser();
            setState(() {
              _isErasing = true;
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isErasing ? Colors.grey[300] : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isErasing ? Colors.blue : Colors.grey[400]!,
                width: _isErasing ? 3 : 1,
              ),
            ),
            child: Icon(
              Icons.cleaning_services,
              size: 18,
              color: _isErasing ? Colors.blue : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrokeToolbar() {
    const widths = [2.0, 4.0, 6.0, 8.0, 12.0];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widths.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              _notifier.setStrokeWidth(widths[i]);
              setState(() {
                _selectedWidth = widths[i];
              });
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedWidth == widths[i]
                      ? Colors.blue
                      : Colors.grey[400]!,
                  width: _selectedWidth == widths[i] ? 3 : 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: widths[i] * 2,
                  height: widths[i] * 2,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionToolbar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.undo,
          onPressed: _canUndo ? () => _notifier.undo() : null,
          tooltip: '撤销',
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.redo,
          onPressed: _canRedo ? () => _notifier.redo() : null,
          tooltip: '重做',
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.delete_outline,
          onPressed: () => _notifier.clear(),
          tooltip: '清空',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: onPressed != null ? Colors.grey[700] : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
}
