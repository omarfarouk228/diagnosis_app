import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/symptom.dart';
import '../models/diagnosis_result.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  GeminiService() {
    // Initialize the Gemini model
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    // Use gemini-1.5-flash for faster, cost-effective responses
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-preview-09-2025',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7, // Balanced creativity and accuracy
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );

    // Initialize chat session for conversational context
    _chatSession = _model.startChat(history: []);
  }

  /// Extracts symptoms from an audio file
  Future<List<Symptom>> extractSymptomsFromAudio(String audioPath) async {
    try {
      // Read audio file as bytes
      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();

      // Create audio content
      final audioPart = DataPart('audio/mp4', audioBytes);

      // Send to Gemini with prompt
      final prompt = '''
You are an expert medical assistant AI. A patient has recorded their symptoms.
Listen to the audio and extract the symptoms into a structured JSON format.

**Instructions:**
1.  Identify each distinct symptom mentioned.
2.  For each symptom, determine its name, severity (1-10), duration, and a brief description.
3.  Format the output as a JSON array of objects. Each object must contain:
    -   `"name"` (string)
    -   `"severity"` (integer, 1-10)
    -   `"duration"` (string, e.g., "3 days", "1 week")
    -   `"description"` (string, optional)

**Example JSON Output:**
```json
[
  {
    "name": "Headache",
    "severity": 7,
    "duration": "2 days",
    "description": "Sharp pain behind the eyes."
  },
  {
    "name": "Fever",
    "severity": 6,
    "duration": "1 day",
    "description": "Feeling hot and cold."
  }
]
```

Provide only the JSON array in your response.
''';

      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), audioPart]),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Failed to extract symptoms: Empty response from AI.');
      }

      // Clean the response to ensure it's valid JSON
      final jsonString = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final decoded = json.decode(jsonString) as List;
      return decoded
          .map((s) => Symptom.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to extract symptoms from audio: $e');
    }
  }

  /// Analyzes symptoms using chat session for follow-up questions
  Future<DiagnosisResult> analyzeSymptoms(List<Symptom> symptoms) async {
    try {
      final prompt = _buildDiagnosisPrompt(symptoms);

      final response = await _chatSession
          .sendMessage(Content.text(prompt))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timed out. Please check your internet connection.',
              );
            },
          );

      final aiResponse = response.text ?? 'No response generated';

      if (aiResponse.isEmpty) {
        throw Exception('Received empty response from AI');
      }

      return DiagnosisResult.fromAIResponse(aiResponse);
    } on GenerativeAIException catch (e) {
      // Handle API-specific errors
      if (e.message.contains('API key')) {
        throw Exception('Invalid API key. Please check your configuration.');
      } else if (e.message.contains('quota')) {
        throw Exception('API quota exceeded. Please try again later.');
      } else {
        throw Exception('AI service error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to analyze symptoms: $e');
    }
  }

  /// Asks a follow-up question about the diagnosis
  Future<String> askFollowUp(String question) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(question));
      return response.text ?? 'No response generated';
    } catch (e) {
      throw Exception('Failed to process follow-up: $e');
    }
  }

  /// Builds a structured prompt for diagnosis
  String _buildDiagnosisPrompt(List<Symptom> symptoms) {
    final symptomsList = symptoms
        .map((s) => '- ${s.toPromptString()}')
        .join('\n');

    return '''
You are a medical AI assistant providing preliminary health assessments. 
Analyze the following symptoms and provide a structured response.

**IMPORTANT DISCLAIMER:** This is NOT medical advice. Always consult a healthcare professional.

**Patient Symptoms:**
$symptomsList

**Please provide:**

1. **Possible Conditions:** List 2-3 possible conditions that match these symptoms (most likely first)

2. **Urgency Level:** Rate as Low, Medium, High, or Emergency
   - Low: Can wait for regular appointment
   - Medium: Should see doctor within a week
   - High: Should see doctor within 24-48 hours
   - Emergency: Seek immediate medical attention

3. **Recommended Actions:** What should the person do next?

4. **When to Seek Immediate Care:** List warning signs that require emergency attention

5. **Self-Care Suggestions:** Safe general recommendations (if urgency is Low/Medium)

**Format your response clearly with these sections.**
''';
  }

  /// Resets the chat session
  void resetChat() {
    _chatSession = _model.startChat(history: []);
  }

  /// Disposes resources
  void dispose() {
    // Clean up
  }
}
