import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'websocket_service.dart';

class Question {
  final int useState;
  final String content;
  final List<Hint> hints;

  Question({
    required this.useState,
    required this.content,
    required this.hints,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      useState: json['useState'] as int,
      content: json['content'] as String,
      hints: (json['hints'] as List<dynamic>)
          .map((e) => Hint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Hint {
  final String value;

  Hint({required this.value});

  factory Hint.fromJson(Map<String, dynamic> json) {
    return Hint(value: json['value'] as String);
  }
}

class HomePage extends StatefulWidget {
  final WebSocketService wsService;

  const HomePage({super.key, required this.wsService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _braceletController = TextEditingController();
  StreamSubscription<dynamic>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  String get _serverAddress => widget.wsService.serverAddress ?? '';
  int get _serverPort => widget.wsService.serverPort ?? 0;

  List<Question> _questions = [];
  Question? _selectedQuestion;
  bool _isLoadingQuestions = false;
  bool _hasLoadedQuestions = false;
  String? _questionsError;

  @override
  void initState() {
    super.initState();
    _listenToWebSocket();
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

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
      _questionsError = null;
    });

    try {
      final url = 'http://$_serverAddress:$_serverPort/api/unused';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          _questions = jsonList.map((e) => Question.fromJson(e)).toList();
          _isLoadingQuestions = false;
          _hasLoadedQuestions = true;
        });
      } else {
        setState(() {
          _questionsError = '加载问题失败: ${response.statusCode}';
          _isLoadingQuestions = false;
          _hasLoadedQuestions = true;
        });
      }
    } catch (e) {
      setState(() {
        _questionsError = '加载问题失败: $e';
        _isLoadingQuestions = false;
        _hasLoadedQuestions = true;
      });
    }
  }

  Future<void> _confirmSelection() async {
    if (_selectedQuestion == null) return;

    final braceletId = _braceletController.text.trim();
    if (braceletId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入手环编号')));
      return;
    }

    try {
      final url =
          'http://$_serverAddress:$_serverPort/api/start?braceletId=$braceletId&question=${Uri.encodeComponent(_selectedQuestion!.content)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          '/game',
          arguments: {
            'braceletId': braceletId,
            'question': _selectedQuestion!.content,
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动失败: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动失败: $e'), backgroundColor: Colors.red),
      );
    }
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
    _braceletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF3B82F6);

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary.withOpacity(0.08), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 32,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz, size: 72, color: primary),
                        const SizedBox(height: 12),
                        const Text(
                          '选择题目',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 320,
                          child: TextField(
                            controller: _braceletController,
                            decoration: InputDecoration(
                              labelText: '手环编号',
                              hintText: '请输入手环编号',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.watch),
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!_hasLoadedQuestions) ...[
                          FilledButton.icon(
                            onPressed: _isLoadingQuestions
                                ? null
                                : _fetchQuestions,
                            icon: _isLoadingQuestions
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: const Text('加载题目'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ] else ...[
                          _buildQuestionsList(),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _selectedQuestion == null
                                ? null
                                : _confirmSelection,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Text('确认'),
                            ),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          if (_questionsError != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _questionsError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (_isLoadingQuestions) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      );
    }

    if (_questions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('暂无可用题目'),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final question = _questions[index];
          final isSelected = _selectedQuestion == question;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedQuestion = question;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[50] : null,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question.content,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
