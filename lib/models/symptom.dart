class Symptom {
  final String name;
  final int severity; // 1-10 scale
  final String duration; // e.g., "2 days", "1 week"
  final String? description;

  Symptom({
    required this.name,
    required this.severity,
    required this.duration,
    this.description,
  });

  // Convert to a formatted string for the AI prompt
  String toPromptString() {
    return '$name (Severity: $severity/10, Duration: $duration)${description != null ? ' - $description' : ''}';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'severity': severity,
      'duration': duration,
      'description': description,
    };
  }

  // Create from JSON
  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      name: json['name'] as String,
      severity: (json['severity'] as num).toInt(),
      duration: json['duration'] as String,
      description: json['description'] as String?,
    );
  }

  Symptom copyWith({
    String? name,
    int? severity,
    String? duration,
    String? description,
  }) {
    return Symptom(
      name: name ?? this.name,
      severity: severity ?? this.severity,
      duration: duration ?? this.duration,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => toPromptString();
}
