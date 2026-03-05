import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiFreeAI {
  final String apiKey;

  ApiFreeAI(this.apiKey);

  /// Example: call completion/text endpoint
  Future<String?> createCompletion({
    required String model,
    required String prompt,
    int maxTokens = 100,
  }) async {
    final url = Uri.parse('https://api.apifree.ai/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4.5',
        'messages' : [
          {"role" : "user", "content" : prompt}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      return data['choices'][0]['message']['content'];
      // return response.body;
    } else {
      print('Error: ${response.statusCode} ${response.body}');
      return null;
    }
  }
}