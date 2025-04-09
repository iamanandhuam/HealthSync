import 'package:flutter/material.dart';
import 'gemini_service.dart';
import 'db_controller.dart';

class ChatWithAiPage extends StatefulWidget {
  const ChatWithAiPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatWithAiPageState createState() => _ChatWithAiPageState();
}

class _ChatWithAiPageState extends State<ChatWithAiPage> {
  final TextEditingController _controller = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  // ignore: prefer_final_fields
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final db = await DBHelper.instance.database;
    final user = await db.query('user', limit: 1);
    return user.isNotEmpty ? user.first : null;
  }

  Future<Map<String, dynamic>> _getTodayHealthSummary() async {
    final db = await DBHelper.instance.database;
    final today = DateTime.now().toIso8601String().split("T")[0];
    final result = await db.query(
      'health_data',
      where: "recorded_at LIKE ?",
      whereArgs: ['$today%'],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    return result.isNotEmpty ? result.first : {};
  }

  Future<Map<String, double>> _getTodayFoodSummary() async {
    final db = await DBHelper.instance.database;
    final today = DateTime.now().toIso8601String().split("T")[0];
    final result = await db.query(
      'consumed_food',
      where: "added_at LIKE ?",
      whereArgs: ['$today%'],
    );

    double totalCalories = 0;
    double protein = 0;
    double fat = 0;

    for (var food in result) {
      int count = (food['count'] ?? 1) as int;
      totalCalories += ((food['calories'] ?? 0) as num).toDouble() * count;
      protein += ((food['protein'] ?? 0) as num).toDouble() * count;
      fat += ((food['fat'] ?? 0) as num).toDouble() * count;
    }

    return {
      'calories': totalCalories,
      'protein': protein,
      'fat': fat,
    };
  }

  void sendMessage() async {
    String userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: userInput, isUser: true));
      _isLoading = true;
    });

    _controller.clear();

    final user = await _getUserProfile();
    final health = await _getTodayHealthSummary();
    final food = await _getTodayFoodSummary();

    final prompt = """
        My name is ${user?['name'] ?? 'User'}.
        I'm a ${user?['age']} year old ${user?['gender']} with weight ${user?['weight']}kg and height ${user?['height']}cm.

        Here is my health summary for today:
        - Heart Rate: ${health['heart_rate'] ?? 'N/A'} BPM
        - Steps: ${health['steps'] ?? 'N/A'}
        - SpO2: ${health['oxygen_saturation'] ?? 'N/A'}%
        - Temperature: ${health['temperature'] ?? 'N/A'}°C
        - BP: ${health['systolic'] ?? '--'}/${health['diastolic'] ?? '--'}
        - Respiratory Rate: ${health['respiratory_rate'] ?? 'N/A'}

        Food summary:
        - Calories consumed: ${food['calories']?.toStringAsFixed(0)} kcal
        - Protein: ${food['protein']?.toStringAsFixed(1)} g
        - Fat: ${food['fat']?.toStringAsFixed(1)} g

        Now respond to my message as a personal doctor:
        "$userInput"

        Keep the reply short and meaningful.
        """;

    final aiResponse = await _geminiService.getResponse(prompt);

    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessage(text: aiResponse, isUser: false));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        "Chat With AI",
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.deepPurple,
          letterSpacing: 1,
        ),
      )),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.only(bottom: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(
                  message: _messages[_messages.length - 1 - index],
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              // Added Padding
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              //color: Colors.white,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  // ignore: deprecated_member_use
                  Colors.white.withOpacity(0.0),
                  // ignore: deprecated_member_use
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFd4e9f4),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 25,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
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

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  // ignore: use_super_parameters
  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.topRight : Alignment.topLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF00806a)
              : const Color(0xFF0088ef),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Text(message.text, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
