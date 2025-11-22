import 'dart:async';
import '../models/symptom.dart';
import '../models/diagnosis_result.dart';

class GeminiService {
  /// Analyzes symptoms and returns a diagnosis (basic mock)
  Future<DiagnosisResult> analyzeSymptomsbasic(List<Symptom> symptoms) async {
    await Future.delayed(const Duration(seconds: 2));
    return DiagnosisResult.fromAIResponse('''
      **Possible Conditions:**
      - Mock Condition 1
      - Mock Condition 2

      **Urgency Level:** Medium

      **Recommended Actions:**
      - This is a mock recommendation.
      ''');
  }

  /// Transcribes audio to text using Gemini (mock)
  Future<String> transcribeAudio(String audioPath) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'This is a mock transcription of the audio file.';
  }

  /// Analyzes symptoms from audio transcription (mock)
  Future<DiagnosisResult> analyzeSymptomsFromAudio(String audioPath) async {
    await Future.delayed(const Duration(seconds: 3));
    final transcription = await transcribeAudio(audioPath);
    return DiagnosisResult.fromAIResponse('''
      **Transcription:**
      $transcription

      **Possible Conditions:**
      - Mock Audio Condition 1
      - Mock Audio Condition 2

      **Urgency Level:** High

      **Recommended Actions:**
      - This is a mock recommendation based on audio.
      ''');
  }

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

  /// Transcribes audio with retry logic (mock)
  Future<String> transcribeAudioWithRetry(
    String audioPath, {
    int maxRetries = 3,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'This is a mock transcription with retry logic.';
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
