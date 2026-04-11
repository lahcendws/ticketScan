import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OCRService {
  // REMPLACEZ CECI PAR VOTRE VRAIE CLÉ API OPENAI
  static String _apiKey = dotenv.env['OPENAI_API_KEY']!;
  static String _apiUrl = dotenv.env['OPENAI_API_URL']!;

  static Future<TicketAnalysis> extractTextFromImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analyse ce ticket de caisse et renvoie uniquement un objet JSON avec les clés suivantes: "storeName" (le nom de l\'enseigne), "date" (format YYYY-MM-DD), "totalAmount" (nombre), "products" (liste de chaînes de caractères au format "Nom Article (Prix€)"). Ne renvoie rien d\'autre que le JSON.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            }
          ],
          'response_format': { 'type': 'json_object' },
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = jsonDecode(data['choices'][0]['message']['content']);

        return TicketAnalysis(
          storeName: content['storeName'] ?? 'Magasin',
          date: DateTime.tryParse(content['date'] ?? '') ?? DateTime.now(),
          totalAmount: (content['totalAmount'] ?? 0.0).toDouble(),
          products: List<String>.from(content['products'] ?? []),
          extractedText: [],
          warrantyYears: 2,
        );
      } else {
        throw Exception('Erreur API OpenAI: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'analyse Cloud: $e');
    }
  }

  // Cette méthode n'est plus utilisée car GPT fait tout le travail, mais on la garde pour la compatibilité
  static TicketAnalysis analyzeTicketText(String text) {
    return TicketAnalysis(storeName: '', date: DateTime.now(), totalAmount: 0, products: [], extractedText: []);
  }

  static void dispose() {}
}

class TicketAnalysis {
  final String storeName;
  final DateTime date;
  final double totalAmount;
  final List<String> products;
  final List<String> extractedText;
  final int warrantyYears;

  TicketAnalysis({
    required this.storeName,
    required this.date,
    required this.totalAmount,
    required this.products,
    required this.extractedText,
    this.warrantyYears = 2,
  });
}
