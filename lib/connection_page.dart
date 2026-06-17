import 'package:flutter/material.dart';
import 'websocket_service.dart';

class ConnectionPage extends StatefulWidget {
  final WebSocketService wsService;

  const ConnectionPage({super.key, required this.wsService});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final _addressController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '5198');
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final address = _addressController.text.trim();
    final port = _portController.text.trim();

    if (address.isEmpty || port.isEmpty) {
      setState(() {
        _errorMessage = '请输入地址和端口';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final wsUrl = 'ws://$address:$port/ws/draw';

    try {
      await widget.wsService.connect(wsUrl, address, int.parse(port));

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _errorMessage = '连接失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF3B82F6);

    return Scaffold(
      appBar: AppBar(title: const Text('连接服务器'), backgroundColor: primary),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.cloud_sync, size: 72, color: primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Drawer App',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: '服务器地址',
                        hintText: '例如: localhost 或 192.168.1.1',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.computer),
                      ),
                      keyboardType: TextInputType.url,
                      enabled: !_isConnecting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _portController,
                      decoration: InputDecoration(
                        labelText: '端口',
                        hintText: '例如: 8080',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isConnecting,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _isConnecting ? null : _connect,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _isConnecting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('连接', style: TextStyle(fontSize: 16)),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
