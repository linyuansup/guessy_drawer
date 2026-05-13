import 'package:flutter/material.dart';
import 'connection_page.dart';
import 'home_page.dart';
import 'game_page.dart';
import 'websocket_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _wsService = WebSocketService();

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawer App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => ConnectionPage(wsService: _wsService),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (_) => HomePage(wsService: _wsService),
            );
          case '/game':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => GamePage(
                wsService: _wsService,
                braceletId: args['braceletId'] as String,
                question: args['question'] as String,
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => ConnectionPage(wsService: _wsService),
            );
        }
      },
    );
  }
}
