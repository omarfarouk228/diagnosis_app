class DiagnosisResult {
  final List<String> possibleConditions;
  final String recommendedActions;
  final String urgencyLevel; // "Low", "Medium", "High", "Emergency"
  final String additionalNotes;
  final DateTime timestamp;

  DiagnosisResult({
    required this.possibleConditions,
    required this.recommendedActions,
    required this.urgencyLevel,
    required this.additionalNotes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Parse from AI response
  factory DiagnosisResult.fromAIResponse(String aiResponse) {
    // Simple parsing - in production, use structured output
    final conditions = <String>[];
    final lines = aiResponse.split('\n');

    String recommended = '';
    String urgency = 'Medium';
    String notes = '';

    // Parse AI response (this is simplified)
    for (var line in lines) {
      if (line.toLowerCase().contains('condition') ||
          line.toLowerCase().contains('possible')) {
        conditions.add(line.trim());
      }
      if (line.toLowerCase().contains('recommend')) {
        recommended = line.trim();
      }
      if (line.toLowerCase().contains('urgency') ||
          line.toLowerCase().contains('emergency')) {
        urgency = 'High';
      }
    }

    return DiagnosisResult(
      possibleConditions: conditions.isEmpty
          ? ['Unable to determine from symptoms provided']
          : conditions,
      recommendedActions: recommended.isEmpty
          ? 'Please consult a healthcare professional'
          : recommended,
      urgencyLevel: urgency,
      additionalNotes: notes.isEmpty ? aiResponse : notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'possibleConditions': possibleConditions,
      'recommendedActions': recommendedActions,
      'urgencyLevel': urgencyLevel,
      'additionalNotes': additionalNotes,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
