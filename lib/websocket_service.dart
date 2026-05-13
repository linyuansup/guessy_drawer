import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final _messageController = StreamController<dynamic>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  Timer? _heartbeatTimer;
  bool _isConnected = true;

  String? serverAddress;
  int? serverPort;

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  WebSocketChannel? get channel => _channel;

  Future<void> connect(String url, String address, int port) async {
    serverAddress = address;
    serverPort = port;
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _startHeartbeat();
    _listenToChannel();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        _channel?.sink.add('ping');
      } catch (e) {
        if (_isConnected) {
          _isConnected = false;
          _connectionController.add(false);
        }
      }

      await Future.delayed(const Duration(seconds: 2));
      if (!_isConnected) {
        _isConnected = true;
        _connectionController.add(true);
      }
    });
  }

  void _listenToChannel() {
    _channel?.stream.listen(
      (data) {
        if (data is List && data.length == 1 && data[0] == 2) {
          _messageController.add(data);
        }
      },
      onError: (error) {
        _isConnected = false;
        _connectionController.add(false);
      },
      onDone: () {
        _isConnected = false;
        _connectionController.add(false);
      },
    );
  }

  void send(dynamic message) {
    _channel?.sink.add(message);
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = true;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
