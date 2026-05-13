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

      Navigator.of(context).pushReplacementNamed(
        '/home',
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('连接服务器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.cloud_sync,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            const Text(
              'Drawer App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '服务器地址',
                hintText: '例如: localhost 或 192.168.1.1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.computer),
              ),
              keyboardType: TextInputType.url,
              enabled: !_isConnecting,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: '端口',
                hintText: '例如: 8080',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              enabled: !_isConnecting,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isConnecting ? null : _connect,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '连接',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
