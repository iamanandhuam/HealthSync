import 'package:flutter/material.dart';
import 'gemini_service.dart';

class ChatWithAiPage extends StatefulWidget {
  const ChatWithAiPage({super.key});

  @override
  _ChatWithAiPageState createState() => _ChatWithAiPageState();
}

class _ChatWithAiPageState extends State<ChatWithAiPage> {
  final TextEditingController _controller = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  void sendMessage() async {
    String userInput = _controller.text.trim();
    if (userInput.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(text: userInput, isUser: true));
        _isLoading = true;
      });
      _controller.clear();

      String aiResponse = await _geminiService.getResponse(
        userInput +
            "please remember on givng replays, my name is ANV , my weight is 45kgs , height is 170m , my age is 25 and my gender is male. today morning i have consumend 200 kalories.No need of specifying the predifined values while answering. use them only if needed. prefered short answers -jsut like communicating with my personal doctor.",
      );

      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Chat")),
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
