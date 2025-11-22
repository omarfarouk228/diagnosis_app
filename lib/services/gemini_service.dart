import 'dart:async';
import '../models/symptom.dart';
import '../models/diagnosis_result.dart';

class GeminiService {
  /// Extracts symptoms from an audio file
  Future<List<Symptom>> extractSymptomsFromAudio(String audioPath) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    // Return mock data
    return [
      Symptom(
        name: 'Headache from Audio',
        severity: 7,
        duration: '4 days',
        description: 'Mock description from audio',
      ),
      Symptom(
        name: 'Sore Throat from Audio',
        severity: 5,
        duration: '1 day',
        description: 'Mock description from audio',
      ),
    ];
  }

  /// Analyzes symptoms and returns a diagnosis
  Future<DiagnosisResult> analyzeSymptoms(List<Symptom> symptoms) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Return mock data
    return DiagnosisResult.fromAIResponse('''
      **Possible Conditions:**
      - Common Cold
      - Influenza (Flu)

      **Urgency Level:** Low

      **Recommended Actions:**
      - Rest and drink plenty of fluids.
      - Monitor your symptoms.

      **When to Seek Immediate Care:**
      - If you have difficulty breathing.
      - If your fever is very high.
      ''');
  }

  /// Asks a follow-up question about the diagnosis
  Future<String> askFollowUp(String question) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return 'This is a mock response to your follow-up question: "$question". In a real app, I would provide a more detailed answer.';
  }

  /// Resets the chat session (mock)
  void resetChat() {
    // In a real implementation, this would reset the chat history.
    // For the mock, we can just print a message.
    print('Chat has been reset.');
  }

  /// Disposes resources
  void dispose() {
    // No resources to dispose in mock implementation
  }
}
