# Building an AI-Powered Diagnosis App in Flutter

## A Hands-On Workshop with Gemini AI

---

## Important: Start from the `starter` branch!

To follow this codelab, please ensure you are on the `starter` branch of the project. This branch provides the initial setup, including:

-   **Models, Screens, and Widgets**: These UI and data structure components are already in place.
-   **`audio_service.dart`**: This service is fully implemented and ready to use.
-   **`gemini_service.dart`**: This service contains placeholder (mockup) functions that return dummy data. You will progressively integrate the actual Gemini AI logic into this file throughout the codelab.

To switch to the `starter` branch, run the following command in your terminal:

```bash
git checkout starter
```

---

## Overview

### What You'll Build

In this codelab, you'll create a fully functional AI-powered medical diagnosis assistant using Flutter and Google's Gemini AI. The app will allow users to input their symptoms and receive AI-generated preliminary health assessments.

**Duration:** 30-45 minutes

**Level:** Intermediate

### What You'll Learn

- How to integrate the Gemini AI API in Flutter
- Using the `google_generative_ai` package
- Building conversational AI interfaces
- Handling asynchronous AI responses
- Error handling and user feedback
- Best practices for AI-powered apps

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart 3.0 or higher
- A code editor (VS Code or Android Studio)
- Basic knowledge of Flutter widgets and async programming
- A Google AI Studio account (free)

### What You'll Need

- A Gemini API key (get it free at https://aistudio.google.com/app/apikey)
- An Android/iOS device or emulator
- Internet connection

---

## Step 1: Environment Setup

### 1.1 Create a New Flutter Project

Open your terminal and create a new Flutter project:

```bash
flutter create ai_diagnosis_app
cd ai_diagnosis_app
```

### 1.2 Add Required Dependencies

Open `pubspec.yaml` and add the following dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Gemini AI integration
  google_generative_ai: ^0.4.6

  # Environment variables for API key
  flutter_dotenv: ^5.1.0

  # UI enhancements
  flutter_markdown: ^0.7.3

  # State management (optional but recommended)
  provider: ^6.1.2

  # Audio recording and playback
  record: ^5.1.2

  # Audio player
  just_audio: ^0.9.40

  # Permission handling
  permission_handler: ^11.3.1

  # Path provider for file storage
  path_provider: ^2.1.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

Run:

```bash
flutter pub get
```

### 1.3 Set Up Environment Variables

Create a `.env` file in the root of your project:

```bash
touch .env
```

Add your Gemini API key to `.env`:

```env
GEMINI_API_KEY=your_api_key_here
```

**⚠️ Important:** Add `.env` to your `.gitignore`:

```gitignore
# .gitignore
.env
*.env
```

Update `pubspec.yaml` to include the `.env` file:

```yaml
flutter:
  assets:
    - .env
```

### 1.4 Configure Platform Permissions

#### Android Setup

Open `android/app/src/main/AndroidManifest.xml` and add these permissions:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

    <application
        android:label="ai_diagnosis_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- Your app configuration -->
    </application>
</manifest>
```

#### iOS Setup

Open `ios/Runner/Info.plist` and add these keys:

```xml
<dict>
    <!-- Add these keys -->
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access to record your symptoms via voice</string>
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>
    <!-- Rest of your configuration -->
</dict>
```

### 1.4 Verify Installation

Run your app to ensure everything is set up correctly:

```bash
flutter run
```

You should see the default Flutter counter app.

---

## Step 2: Project Structure

### 2.1 Create Folder Structure

Create the following folder structure:

```
lib/
├── main.dart
├── models/
│   ├── symptom.dart
│   └── diagnosis_result.dart
├── services/
│   ├── gemini_service.dart
│   └── audio_service.dart
├── screens/
│   ├── home_screen.dart
│   └── diagnosis_screen.dart
└── widgets/
    ├── symptom_input_widget.dart
    ├── audio_recorder_widget.dart
    └── diagnosis_display_widget.dart
```

Create these directories:

```bash
mkdir -p lib/models lib/services lib/screens lib/widgets
```

### 2.2 Understanding the Architecture

Our app follows a clean architecture pattern:

- **Models**: Data structures (Symptom, DiagnosisResult)
- **Services**: AI communication layer (GeminiService) and Audio handling (AudioService)
- **Screens**: Full-page views (Home, Diagnosis)
- **Widgets**: Reusable UI components (including AudioRecorderWidget)

---

## Step 3: Create Data Models

### 3.1 Symptom Model

Create `lib/models/symptom.dart`:

```dart
// lib/models/symptom.dart

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
      severity: json['severity'] as int,
      duration: json['duration'] as String,
      description: json['description'] as String?,
    );
  }

  @override
  String toString() => toPromptString();
}
```

### 3.2 Diagnosis Result Model

Create `lib/models/diagnosis_result.dart`:

```dart
// lib/models/diagnosis_result.dart

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
```

---

## Step 4: Implement Gemini AI Service

### 4.1 Create the Service Class

Create `lib/services/gemini_service.dart`:

```dart
// lib/services/gemini_service.dart

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
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7, // Balanced creativity and accuracy
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(
          HarmCategory.harassment,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.hateSpeech,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.medium,
        ),
      ],
    );

    // Initialize chat session for conversational context
    _chatSession = _model.startChat(history: []);
  }

  /// Analyzes symptoms and returns a diagnosis
  Future<DiagnosisResult> analyzeSymptomsbasic(List<Symptom> symptoms) async {
    try {
      // Build the prompt
      final prompt = _buildDiagnosisPrompt(symptoms);

      // Send to Gemini AI
      final response = await _model.generateContent([Content.text(prompt)]);

      // Extract text from response
      final aiResponse = response.text ?? 'No response generated';

      // Parse and return result
      return DiagnosisResult.fromAIResponse(aiResponse);
    } catch (e) {
      throw Exception('Failed to analyze symptoms: $e');
    }
  }

  /// Transcribes audio to text using Gemini
  Future<String> transcribeAudio(String audioPath) async {
    try {
      // Read audio file as bytes
      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();

      // Create audio content
      final audioPart = DataPart('audio/mp4', audioBytes);

      // Send to Gemini with prompt
      final prompt = '''
Please transcribe the following audio recording.
The audio contains a description of medical symptoms.
Provide only the transcription, without any additional commentary.
''';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          audioPart,
        ])
      ]);

      return response.text ?? 'Unable to transcribe audio';
    } catch (e) {
      throw Exception('Failed to transcribe audio: $e');
    }
  }

  /// Analyzes symptoms from audio transcription
  Future<DiagnosisResult> analyzeSymptomsFromAudio(String audioPath) async {
    try {
      // First, transcribe the audio
      final transcription = await transcribeAudio(audioPath);

      // Then analyze the transcription
      final prompt = '''
You are a medical AI assistant. The following is a transcription of a patient
describing their symptoms:

"$transcription"

Please analyze these symptoms and provide a structured assessment.

**IMPORTANT DISCLAIMER:** This is NOT medical advice. Always consult a healthcare professional.

**Please provide:**

1. **Extracted Symptoms:** List the specific symptoms mentioned

2. **Possible Conditions:** List 2-3 possible conditions that match these symptoms

3. **Urgency Level:** Rate as Low, Medium, High, or Emergency

4. **Recommended Actions:** What should the person do next?

5. **When to Seek Immediate Care:** Warning signs requiring emergency attention

**Format your response clearly with these sections.**
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final aiResponse = response.text ?? 'No response generated';

      return DiagnosisResult.fromAIResponse(aiResponse);
    } catch (e) {
      throw Exception('Failed to analyze audio symptoms: $e');
    }
  }

  /// Analyzes symptoms using chat session for follow-up questions
  Future<DiagnosisResult> analyzeSymptoms(List<Symptom> symptoms) async {
    try {
      final prompt = _buildDiagnosisPrompt(symptoms);

      final response = await _chatSession.sendMessage(
        Content.text(prompt),
      );

      final aiResponse = response.text ?? 'No response generated';
      return DiagnosisResult.fromAIResponse(aiResponse);
    } catch (e) {
      throw Exception('Failed to analyze symptoms: $e');
    }
  }

  /// Asks a follow-up question about the diagnosis
  Future<String> askFollowUp(String question) async {
    try {
      final response = await _chatSession.sendMessage(
        Content.text(question),
      );
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
    // Clean up if needed
  }
}
```

### 4.2 Understanding the Service

Key components:

- **GenerativeModel**: Initializes Gemini with specific configurations
- **ChatSession**: Maintains conversational context for follow-ups
- **Safety Settings**: Ensures appropriate content generation
- **Structured Prompts**: Guides AI to produce consistent, useful outputs
- **Audio Transcription**: Converts voice recordings to text using Gemini's multimodal capabilities

---

## Step 4.3: Create Audio Recording Service

### Create the Audio Service

Create `lib/services/audio_service.dart`:

```dart
// lib/services/audio_service.dart

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Requests microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Checks if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Starts recording audio
  Future<void> startRecording() async {
    try {
      // Check permission
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          throw Exception('Microphone permission denied');
        }
      }

      // Check if already recording
      if (_isRecording) {
        throw Exception('Already recording');
      }

      // Generate file path
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  /// Stops recording and returns the file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        throw Exception('Not currently recording');
      }

      final path = await _recorder.stop();
      _isRecording = false;

      return path;
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    }
  }

  /// Cancels the current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;

        // Delete the recording file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to cancel recording: $e');
    }
  }

  /// Gets the current recording duration
  Future<Duration> getRecordingDuration() async {
    if (!_isRecording) return Duration.zero;

    try {
      final amplitude = await _recorder.getAmplitude();
      // This is a placeholder - you might need to track duration manually
      return Duration.zero;
    } catch (e) {
      return Duration.zero;
    }
  }

  /// Checks if the device has a microphone
  Future<bool> hasMicrophone() async {
    return await _recorder.hasPermission();
  }

  /// Deletes a recording file
  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete recording: $e');
    }
  }

  /// Gets the size of a recording file in bytes
  Future<int> getRecordingSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Disposes the recorder
  void dispose() {
    _recorder.dispose();
  }
}
```

### Understanding Audio Service Features

- **Permission Handling**: Requests and checks microphone permissions
- **Recording Control**: Start, stop, and cancel recordings
- **File Management**: Saves recordings with timestamps, can delete files
- **Error Handling**: Comprehensive error messages
- **Format**: Records in M4A format (compatible with Gemini AI)

---

## Step 5: Build the User Interface

### 5.1 Update Main Entry Point

Update `lib/main.dart`:

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/gemini_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<GeminiService>(
      create: (_) => GeminiService(),
      dispose: (_, service) => service.dispose(),
      child: MaterialApp(
        title: 'AI Diagnosis Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
```

### 5.2 Create Home Screen

Create `lib/screens/home_screen.dart`:

```dart
// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/symptom.dart';
import '../services/gemini_service.dart';
import 'diagnosis_screen.dart';
import '../widgets/symptom_input_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Symptom> _symptoms = [];
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagnosis Assistant'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.health_and_safety,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Describe Your Symptoms',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your symptoms to get an AI-powered preliminary assessment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),

            // Symptoms list
            Expanded(
              child: _symptoms.isEmpty
                  ? _buildEmptyState()
                  : _buildSymptomsList(),
            ),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSymptom,
        icon: const Icon(Icons.add),
        label: const Text('Add Symptom'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_information_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No symptoms added yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first symptom',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _symptoms.length,
      itemBuilder: (context, index) {
        final symptom = _symptoms[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getSeverityColor(symptom.severity),
              child: Text(
                '${symptom.severity}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              symptom.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Duration: ${symptom.duration}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeSymptom(index),
              color: Colors.red,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is not medical advice. Always consult a healthcare professional.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[800],
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Analyze button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _symptoms.isEmpty || _isAnalyzing
                  ? null
                  : _analyzeSymptoms,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology),
              label: Text(
                _isAnalyzing ? 'Analyzing...' : 'Analyze Symptoms',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(int severity) {
    if (severity <= 3) return Colors.green;
    if (severity <= 6) return Colors.orange;
    return Colors.red;
  }

  void _addSymptom() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SymptomInputWidget(
        onSymptomAdded: (symptom) {
          setState(() {
            _symptoms.add(symptom);
          });
        },
      ),
    );
  }

  void _removeSymptom(int index) {
    setState(() {
      _symptoms.removeAt(index);
    });
  }

  Future<void> _analyzeSymptoms() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final result = await geminiService.analyzeSymptoms(_symptoms);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiagnosisScreen(
              result: result,
              symptoms: _symptoms,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }
}
```

---

## Step 6: Create Symptom Input Widget

Create `lib/widgets/symptom_input_widget.dart`:

```dart
// lib/widgets/symptom_input_widget.dart

import 'package:flutter/material.dart';
import '../models/symptom.dart';

class SymptomInputWidget extends StatefulWidget {
  final Function(Symptom) onSymptomAdded;

  const SymptomInputWidget({
    super.key,
    required this.onSymptomAdded,
  });

  @override
  State<SymptomInputWidget> createState() => _SymptomInputWidgetState();
}

class _SymptomInputWidgetState extends State<SymptomInputWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _severity = 5;
  String _duration = '1 day';

  final List<String> _commonDurations = [
    '1 hour',
    'Few hours',
    '1 day',
    '2-3 days',
    '1 week',
    '2 weeks',
    '1 month',
    'More than a month',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              'Add Symptom',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Symptom name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Symptom Name',
                hintText: 'e.g., Headache, Fever, Cough',
                prefixIcon: const Icon(Icons.medical_services),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a symptom name';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Severity slider
            Text(
              'Severity: $_severity/10',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _severity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_severity',
              onChanged: (value) {
                setState(() {
                  _severity = value.round();
                });
              },
            ),
            const SizedBox(height: 16),

            // Duration dropdown
            DropdownButtonFormField<String>(
              value: _duration,
              decoration: InputDecoration(
                labelText: 'Duration',
                prefixIcon: const Icon(Icons.access_time),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _commonDurations.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(duration),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _duration = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Optional description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Additional Details (Optional)',
                hintText: 'Any other relevant information',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Add button
            ElevatedButton(
              onPressed: _submitSymptom,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Symptom',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submitSymptom() {
    if (_formKey.currentState!.validate()) {
      final symptom = Symptom(
        name: _nameController.text.trim(),
        severity: _severity,
        duration: _duration,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      widget.onSymptomAdded(symptom);
      Navigator.pop(context);
    }
  }
}
```

---

## Step 7: Create Audio Recorder Widget

Create `lib/widgets/audio_recorder_widget.dart`:

```dart
// lib/widgets/audio_recorder_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/gemini_service.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(String transcription) onTranscriptionComplete;

  const AudioRecorderWidget({
    super.key,
    required this.onTranscriptionComplete,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final AudioService _audioService = AudioService();
  bool _isRecording = false;
  bool _isProcessing = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            _isRecording ? 'Recording...' : 'Voice Input',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          Text(
            _isRecording
                ? 'Describe your symptoms'
                : 'Tap the microphone to start',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),

          // Recording animation
          if (_isRecording) _buildRecordingAnimation(),

          // Duration display
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _formatDuration(_recordingDuration),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
              ),
            ),

          const SizedBox(height: 24),

          // Control buttons
          if (_isProcessing)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing audio...'),
              ],
            )
          else
            _buildControlButtons(),

          const SizedBox(height: 16),

          // Info text
          if (!_isRecording && !_isProcessing)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Speak clearly and describe your symptoms in detail',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing circles
        ...List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1500 + (index * 200)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Container(
                width: 120 + (value * 80 * index),
                height: 120 + (value * 80 * index),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1 * (1 - value)),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3 * (1 - value)),
                    width: 2,
                  ),
                ),
              );
            },
            onEnd: () {
              if (_isRecording && mounted) {
                setState(() {}); // Restart animation
              }
            },
          );
        }),

        // Microphone icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 50,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Cancel button (only when recording)
        if (_isRecording)
          ElevatedButton.icon(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

        // Main action button
        ElevatedButton.icon(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          label: Text(_isRecording ? 'Stop' : 'Start Recording'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? Colors.red : Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startRecording() async {
    try {
      await _audioService.startRecording();
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = Duration(seconds: timer.tick);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();

      final audioPath = await _audioService.stopRecording();

      if (audioPath == null) {
        throw Exception('Failed to save recording');
      }

      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      // Transcribe audio using Gemini
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final transcription = await geminiService.transcribeAudio(audioPath);

      // Delete the audio file after transcription
      await _audioService.deleteRecording(audioPath);

      if (mounted) {
        widget.onTranscriptionComplete(transcription);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _timer?.cancel();
      await _audioService.cancelRecording();

      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
```

---

## Step 8: Update Home Screen for Audio Input

### Update Home Screen to Support Audio

Update the `lib/screens/home_screen.dart` file to add audio recording capability:

```dart
// Add to the imports section
import '../widgets/audio_recorder_widget.dart';

// Update the FloatingActionButton section to include audio option
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('AI Diagnosis Assistant'),
      centerTitle: true,
      elevation: 0,
      actions: [
        // Audio input button
        IconButton(
          onPressed: _showAudioRecorder,
          icon: const Icon(Icons.mic),
          tooltip: 'Voice Input',
        ),
      ],
    ),
    // ... rest of the build method
    floatingActionButton: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Voice input FAB
        FloatingActionButton(
          onPressed: _showAudioRecorder,
          heroTag: 'voice',
          child: const Icon(Icons.mic),
          tooltip: 'Record symptoms',
        ),
        const SizedBox(height: 16),
        // Add symptom FAB
        FloatingActionButton.extended(
          onPressed: _addSymptom,
          heroTag: 'add',
          icon: const Icon(Icons.add),
          label: const Text('Add Symptom'),
        ),
      ],
    ),
  );
}

// Add this method to show the audio recorder
void _showAudioRecorder() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => AudioRecorderWidget(
      onTranscriptionComplete: (transcription) {
        // Show transcription and allow user to confirm
        _showTranscriptionDialog(transcription);
      },
    ),
  );
}

// Add this method to show transcription confirmation
void _showTranscriptionDialog(String transcription) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Voice Transcription'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your symptoms have been transcribed:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                transcription,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to analyze these symptoms?',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _analyzeVoiceSymptoms(transcription);
          },
          child: const Text('Analyze'),
        ),
      ],
    ),
  );
}

// Add this method to analyze voice-transcribed symptoms
Future<void> _analyzeVoiceSymptoms(String transcription) async {
  setState(() {
    _isAnalyzing = true;
  });

  try {
    final geminiService = Provider.of<GeminiService>(context, listen: false);

    // Create a temporary audio path or use the transcription directly
    // For now, we'll analyze the transcription as text
    final prompt = '''
You are a medical AI assistant. A patient has described their symptoms via voice:

"$transcription"

Please extract the symptoms and provide a structured assessment.

**IMPORTANT DISCLAIMER:** This is NOT medical advice. Always consult a healthcare professional.

**Please provide:**

1. **Extracted Symptoms:** List the specific symptoms mentioned with estimated severity (1-10)

2. **Possible Conditions:** List 2-3 possible conditions that match these symptoms

3. **Urgency Level:** Rate as Low, Medium, High, or Emergency

4. **Recommended Actions:** What should the person do next?

5. **When to Seek Immediate Care:** Warning signs requiring emergency attention

**Format your response clearly with these sections.**
''';

    final response = await geminiService.askFollowUp(prompt);
    final result = DiagnosisResult.fromAIResponse(response);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiagnosisScreen(
            result: result,
            symptoms: [], // Voice symptoms don't have structured Symptom objects
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }
}
```

---

---

## Step 9: Create Diagnosis Screen

Create `lib/screens/diagnosis_screen.dart`:

```dart
// lib/screens/diagnosis_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/diagnosis_result.dart';
import '../models/symptom.dart';
import '../services/gemini_service.dart';

class DiagnosisScreen extends StatefulWidget {
  final DiagnosisResult result;
  final List<Symptom> symptoms;

  const DiagnosisScreen({
    super.key,
    required this.result,
    required this.symptoms,
  });

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _questionController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add initial AI response as a message
    _messages.add(ChatMessage(
      text: widget.result.additionalNotes,
      isUser: false,
      timestamp: widget.result.timestamp,
    ));
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Results'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Results summary
          _buildResultsSummary(),

          // Chat messages
          Expanded(
            child: _buildChatSection(),
          ),

          // Question input
          _buildQuestionInput(),
        ],
      ),
    );
  }

  Widget _buildResultsSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getUrgencyColor(widget.result.urgencyLevel).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _getUrgencyColor(widget.result.urgencyLevel),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgency badge
          Row(
            children: [
              Icon(
                _getUrgencyIcon(widget.result.urgencyLevel),
                color: _getUrgencyColor(widget.result.urgencyLevel),
              ),
              const SizedBox(width: 8),
              Text(
                'Urgency: ${widget.result.urgencyLevel}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getUrgencyColor(widget.result.urgencyLevel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Symptoms summary
          Text(
            'Analyzed Symptoms:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.symptoms.map((symptom) {
              return Chip(
                label: Text(symptom.name),
                avatar: CircleAvatar(
                  backgroundColor: _getSeverityColor(symptom.severity),
                  child: Text(
                    '${symptom.severity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      color: Colors.grey[100],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        reverse: true,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[_messages.length - 1 - index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            message.isUser
                ? Text(
                    message.text,
                    style: const TextStyle(color: Colors.white),
                  )
                : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14),
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: message.isUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask a follow-up question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isLoading,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _sendQuestion,
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _questionController.clear();

    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final response = await geminiService.askFollowUp(question);

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'emergency':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getUrgencyIcon(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'emergency':
        return Icons.emergency;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getSeverityColor(int severity) {
    if (severity <= 3) return Colors.green;
    if (severity <= 6) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
```

---

## Step 10: Testing Your App

### 10.1 Run the Application

```bash
flutter run
```

### 10.2 Test Cases to Try

**Test Case 1: Simple Symptoms (Text Input)**

- Add: "Headache" (Severity: 7, Duration: 2 days)
- Add: "Fever" (Severity: 6, Duration: 2 days)
- Expected: Common cold or flu

**Test Case 2: Emergency Symptoms (Text Input)**

- Add: "Chest pain" (Severity: 9, Duration: 1 hour)
- Add: "Difficulty breathing" (Severity: 8, Duration: 30 minutes)
- Expected: High/Emergency urgency

**Test Case 3: Voice Input**

- Tap microphone button
- Record: "I've been having a severe headache for the past two days, along with a fever and body aches"
- Verify transcription accuracy
- Expected: Flu-like symptoms analysis

**Test Case 4: Follow-up Questions**

- After diagnosis, ask: "What over-the-counter medication can I take?"
- Ask: "When should I see a doctor?"

### 10.3 Verify Key Features

✅ Symptoms can be added and removed  
✅ Severity slider works correctly  
✅ Audio recording works with proper permissions  
✅ Audio is transcribed accurately  
✅ AI analysis provides structured response  
✅ Follow-up questions maintain context  
✅ Error handling works (try with no internet)  
✅ UI is responsive and intuitive  
✅ Recording timer displays correctly  
✅ Audio files are cleaned up after use

---

## Step 11: Error Handling & Edge Cases

### 11.1 Add Network Error Handling

Update `GeminiService` to handle common errors:

```dart
// Add to lib/services/gemini_service.dart

Future<DiagnosisResult> analyzeSymptoms(List<Symptom> symptoms) async {
  try {
    final prompt = _buildDiagnosisPrompt(symptoms);

    final response = await _chatSession.sendMessage(
      Content.text(prompt),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Request timed out. Please check your internet connection.');
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
```

### 11.2 Add Input Validation

Update `SymptomInputWidget` to validate inputs more thoroughly:

```dart
// Update validator in symptom_input_widget.dart

validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter a symptom name';
  }
  if (value.trim().length < 2) {
    return 'Symptom name too short';
  }
  if (value.trim().length > 100) {
    return 'Symptom name too long';
  }
  return null;
},
```

### 11.3 Add Audio-Specific Error Handling

Add comprehensive error handling for audio operations:

```dart
// Add to audio_service.dart

/// Validates audio file before processing
Future<bool> validateAudioFile(String path) async {
  try {
    final file = File(path);

    // Check if file exists
    if (!await file.exists()) {
      throw Exception('Audio file not found');
    }

    // Check file size (max 10MB for Gemini)
    final size = await file.length();
    if (size == 0) {
      throw Exception('Audio file is empty');
    }
    if (size > 10 * 1024 * 1024) {
      throw Exception('Audio file too large (max 10MB)');
    }

    return true;
  } catch (e) {
    return false;
  }
}
```

Add retry logic for transcription:

```dart
// Add to gemini_service.dart

/// Transcribes audio with retry logic
Future<String> transcribeAudioWithRetry(
  String audioPath, {
  int maxRetries = 3,
}) async {
  int attempts = 0;
  Exception? lastError;

  while (attempts < maxRetries) {
    try {
      return await transcribeAudio(audioPath);
    } catch (e) {
      lastError = e as Exception;
      attempts++;

      if (attempts < maxRetries) {
        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  throw lastError ?? Exception('Failed after $maxRetries attempts');
}
```

---

## Step 12: Using Flutter AI Toolkit (Optional Enhancement)

### 12.1 Add AI Toolkit Chat Interface

The `flutter_ai_toolkit` package provides pre-built chat components. Let's integrate it:

```dart
// Alternative implementation using flutter_ai_toolkit
// Create lib/screens/ai_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Assistant'),
      ),
      body: LlmChatView(
        provider: GeminiProvider(
          model: GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: dotenv.env['GEMINI_API_KEY']!,
          ),
        ),
        welcomeMessage: 'Hello! I\'m your AI health assistant. '
            'Describe your symptoms and I\'ll provide a preliminary assessment. '
            'Remember, this is not medical advice.',
      ),
    );
  }
}
```

### 12.2 Add Navigation to AI Chat

Update `HomeScreen` to include a button to access the AI chat:

```dart
// Add to home_screen.dart appBar actions

actions: [
  IconButton(
    icon: const Icon(Icons.chat),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AIChatScreen(),
        ),
      );
    },
    tooltip: 'Open AI Chat',
  ),
],
```

---

## Step 13: Deployment Considerations

### 13.1 Security Best Practices

**❌ Never commit your API key to Git:**

```bash
# Ensure .env is in .gitignore
echo ".env" >> .gitignore
git add .gitignore
git commit -m "Add .env to gitignore"
```

**✅ For production, use a backend proxy:**

```dart
// Production architecture (recommended)
//
// Flutter App → Your Backend API → Gemini API
//
// This keeps your API key secure on the server
```

### 13.2 Add Loading States

Improve user experience with better loading indicators:

```dart
// Example: Add skeleton loading in diagnosis_screen.dart

Widget _buildLoadingState() {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 3,
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    },
  );
}
```

### 13.3 Add Analytics (Optional)

Track app usage for improvements:

```yaml
# Add to pubspec.yaml
dependencies:
  firebase_analytics: ^11.3.3
```

### 13.4 Audio File Management

Implement automatic cleanup of old recordings:

```dart
// Add to audio_service.dart

/// Cleans up old recording files
Future<void> cleanupOldRecordings({Duration maxAge = const Duration(hours: 24)}) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    final now = DateTime.now();

    for (final file in files) {
      if (file.path.contains('recording_') && file is File) {
        final stat = await file.stat();
        final age = now.difference(stat.modified);

        if (age > maxAge) {
          await file.delete();
        }
      }
    }
  } catch (e) {
    // Log error but don't throw
    print('Failed to cleanup recordings: $e');
  }
}
```

---

## Step 14: Congratulations! 🎉

### What You've Built

You've successfully created an AI-powered diagnosis app with:

✅ **Symptom Input System** - Structured data collection  
✅ **Voice Recording** - Audio symptom capture with permissions  
✅ **Audio Transcription** - Gemini AI audio-to-text conversion  
✅ **Gemini AI Integration** - Real-time AI analysis  
✅ **Conversational Interface** - Follow-up questions  
✅ **Clean Architecture** - Maintainable code structure  
✅ **Error Handling** - Robust error management  
✅ **Modern UI** - Material 3 design with animations

### Key Learnings

1. **AI Integration** - How to use Gemini AI in Flutter with text and audio
2. **Audio Recording** - Implementing voice input with permission handling
3. **Multimodal AI** - Using Gemini's audio transcription capabilities
4. **Async Programming** - Handling AI responses and audio processing
5. **State Management** - Using Provider
6. **Clean Code** - Separating concerns (models, services, UI)
7. **User Experience** - Loading states, animations, error messages

---

## Next Steps

### Enhancements to Try

**🚀 Level 1: UI Improvements**

- Add animations for symptom cards
- Implement dark mode
- Add splash screen
- Create onboarding tutorial
- Add waveform visualization during recording
- Implement haptic feedback for recording start/stop

**🔥 Level 2: Features**

- Save diagnosis history locally (Hive/Isar)
- Export diagnosis as PDF
- Playback recorded audio before transcription
- Multi-language support for voice input
- Background noise cancellation
- Voice activity detection (VAD)

**💡 Level 3: Advanced**

- Image analysis for skin conditions
- Integration with health tracking devices
- Medication reminder system
- Telemedicine appointment booking
- Real-time streaming audio transcription
- Offline voice-to-text (using on-device ML)

**🏆 Level 4: Production**

- Backend API for API key security
- User authentication (Firebase Auth)
- Cloud storage for user history and recordings
- Push notifications for follow-ups
- HIPAA-compliant audio storage
- Audio compression before upload

---

## Resources

### Documentation

- [Gemini AI Docs](https://ai.google.dev/docs)
- [Gemini Audio Capabilities](https://ai.google.dev/gemini-api/docs/audio)
- [google_generative_ai Package](https://pub.dev/packages/google_generative_ai)
- [flutter_ai_toolkit](https://pub.dev/packages/flutter_ai_toolkit)
- [record Package](https://pub.dev/packages/record)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [permission_handler Package](https://pub.dev/packages/permission_handler)
- [Flutter Documentation](https://docs.flutter.dev)

### Community

- [Flutter Discord](https://discord.gg/flutter)
- [r/FlutterDev](https://reddit.com/r/flutterdev)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

### Learning More

- [AI Prompt Engineering Guide](https://www.promptingguide.ai/)
- [Audio Processing in Flutter](https://docs.flutter.dev/cookbook/plugins/play-video)
- [Healthcare App Compliance](https://www.fda.gov/medical-devices/digital-health-center-excellence)
- [Flutter Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Voice User Interface Design](https://www.nngroup.com/articles/voice-first/)

---

## Troubleshooting

### Common Issues

**Issue: "API key not found"**

- Solution: Verify `.env` file exists and contains `GEMINI_API_KEY`
- Run `flutter clean` and `flutter pub get`

**Issue: "API quota exceeded"**

- Solution: Check your usage at [Google AI Studio](https://aistudio.google.com)
- Consider upgrading to paid tier

**Issue: "Network error"**

- Solution: Check internet connection
- Verify API key is valid
- Check firewall/proxy settings

**Issue: App crashes on Android**

- Solution: Enable internet permission in `AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

**Issue: "Microphone permission denied"**

- Solution: Ensure permissions are added to AndroidManifest.xml and Info.plist
- Request permissions at runtime before recording
- Check device settings to ensure app has microphone access

**Issue: "Audio recording fails"**

- Solution: Verify microphone is working in other apps
- Check if another app is using the microphone
- Restart the device
- Ensure storage permissions are granted

**Issue: "Audio transcription returns empty result"**

- Solution: Check audio file size (must be under 10MB)
- Verify audio format is supported (M4A recommended)
- Ensure audio is clear and not too quiet
- Check network connection for API call

**Issue: "Recording quality is poor"**

- Solution: Increase bitRate in RecordConfig (e.g., 256000)
- Use a higher sampleRate (e.g., 48000)
- Ensure microphone is not obstructed
- Test in a quieter environment

---

## Feedback & Support

**Found a bug?** Open an issue on GitHub  
**Have questions?** Join our Discord community  
**Want to share your app?** Tag us on Twitter with #FlutterAI

---

## Legal Disclaimer

**⚠️ IMPORTANT LEGAL NOTICE**

This application is a **demonstration and educational tool only**. It is NOT intended for:

- Actual medical diagnosis
- Treatment recommendations
- Emergency medical situations

**For real healthcare applications:**

- Obtain proper regulatory approvals (FDA, CE marking, etc.)
- Implement HIPAA/GDPR compliance
- Have medical professionals review content
- Include appropriate disclaimers
- Get legal counsel

**Users should:**

- Always consult qualified healthcare professionals
- Seek emergency care for serious symptoms
- Not rely solely on AI for medical decisions

---

## License

This codelab is released under the MIT License.

```
MIT License

Copyright (c) 2025 Omar Farouk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## About the Author

**Omar Farouk**

- Google Developer Expert in Flutter
- Senior Software Engineer Full Stack
- AI & Mobile Development Trainer

Connect with me:

- LinkedIn: [Your LinkedIn]
- GitHub: [Your GitHub]
- Twitter: [Your Twitter]

---

**Thank you for completing this codelab! Happy coding! 🚀**
