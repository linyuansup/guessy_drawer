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
    final primary = const Color(0xFF3B82F6);

    return MaterialApp(
      title: 'Drawer App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
