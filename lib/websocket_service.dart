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
  Timer? _reconnectTimer;
  bool _isConnected = true;
  bool _isReconnecting = false;

  String? _url;
  String? serverAddress;
  int? serverPort;

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get reconnectingStream => _reconnectingController.stream;
  WebSocketChannel? get channel => _channel;

  final _reconnectingController = StreamController<bool>.broadcast();

  Future<void> connect(String url, String address, int port) async {
    _url = url;
    serverAddress = address;
    serverPort = port;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _startHeartbeat();
      _listenToChannel();
    } catch (e) {
      _scheduleReconnect();
    }
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
          _scheduleReconnect();
        }
      }

      await Future.delayed(const Duration(seconds: 2));
      if (!_isConnected && !_isReconnecting) {
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
        _scheduleReconnect();
      },
      onDone: () {
        _isConnected = false;
        _connectionController.add(false);
        _scheduleReconnect();
      },
    );
  }

  void _scheduleReconnect() {
    if (_isReconnecting || _url == null) return;

    _isReconnecting = true;
    _reconnectingController.add(true);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_url == null) {
        _stopReconnect();
        return;
      }

      try {
        _channel = WebSocketChannel.connect(Uri.parse(_url!));
        _startHeartbeat();
        _listenToChannel();

        await _channel!.ready;

        _isConnected = true;
        _isReconnecting = false;
        _connectionController.add(true);
        _reconnectingController.add(false);
        _reconnectTimer?.cancel();
      } catch (e) {
        // 继续重连
      }
    });
  }

  void _stopReconnect() {
    _isReconnecting = false;
    _reconnectTimer?.cancel();
    _reconnectingController.add(false);
  }

  void send(dynamic message) {
    _channel?.sink.add(message);
  }

  void disconnect() {
    _url = null;
    _stopReconnect();
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = true;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
    _reconnectingController.close();
  }
}
