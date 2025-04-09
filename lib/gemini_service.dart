import 'dart:convert'; // Import the dart:convert library
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = "AIzaSyBNPfd98wdhDylk12LzLkD6YXHzUC7vC_s";
  static const String endpoint =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey";

  Future<String> getResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"] ??
            "No response";
      } else {
        //return "Error: ${response.statusCode} - ${response.body}";
        return "ERROR ! Unable to reach server.";
      }
    } catch (e) {
      //return "Error: $e";
      return "ERROR ! Unable to reach server.";
    }
  }
}
