# Building an AI-Powered Diagnosis App in Flutter

## A Hands-On Workshop with Gemini AI

---

## Important: Start from the `starter` branch!

To follow this codelab, please ensure you are on the `starter` branch of the project. This branch provides the initial setup, including:

- **Models, Screens, and Widgets**: These UI and data structure components are already in place.
- **`audio_service.dart`**: This service is fully implemented and ready to use.
- **`gemini_service.dart`**: This service contains placeholder (mockup) functions that return dummy data. You will progressively integrate the actual Gemini AI logic into this file throughout the codelab.

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

## Table of Contents

- [Step 1: Getting Started](#step-1-getting-started)
- [Step 2: Understanding the Project Structure](#step-2-understanding-the-project-structure)
- [Step 3: Implement the Gemini AI Service](#step-3-implement-the-gemini-ai-service)
- [Step 4: Run the App and Test](#step-4-run-the-app-and-test)
- [Step 5: Error Handling & Edge Cases](#step-5-error-handling--edge-cases)
- [Step 6: Deployment Considerations](#step-6-deployment-considerations)
- [Step 7: Congratulations!](#step-7-congratulations-)
- [Next Steps](#next-steps)
- [Resources](#resources)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [About the Author](#about-the-author)

---

## Step 1: Getting Started

### 1.1 Get the Starter Code

Instead of creating a new project from scratch, you'll clone the starter project from GitHub.

Open your terminal and clone the repository:

```bash
git clone <repository_url>
cd <repository_name>
```

Then, switch to the `starter` branch:

```bash
git checkout starter
```

Finally, get the dependencies:

```bash
flutter pub get
```

### 1.2 Set Up Environment Variables

Create a `.env` file in the root of your project:

```bash
touch .env
```

Add your Gemini API key to `.env`:

```env
GEMINI_API_KEY=your_api_key_here
```

**⚠️ Important:** The `.env` file is already included in the project's `.gitignore`.

Update `pubspec.yaml` to include the `.env` file as an asset:

```yaml
flutter:
  assets:
    - .env
```

### 1.3 Configure Platform Permissions

The starter project should already have the necessary permissions configured. However, it's good practice to verify them.

#### Android Setup

Check `android/app/src/main/AndroidManifest.xml` for these permissions:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    ...
</manifest>
```

#### iOS Setup

Check `ios/Runner/Info.plist` for these keys:

```xml
<dict>
    ...
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access to record your symptoms via voice</string>
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>
    ...
</dict>
```

### 1.4 Verify Installation

Run your app to ensure everything is set up correctly:

```bash
flutter run
```

You should see the home screen of the diagnosis app.

---

## Step 2: Understanding the Project Structure

### 2.1 The Starter Project

The `starter` branch provides a solid foundation for our codelab. Here's what's already included:

- **`main.dart`**: The app's entry point, with theme and `Provider` setup.
- **Models**: `symptom.dart` and `diagnosis_result.dart` are fully implemented.
- **Screens**: `home_screen.dart` and `diagnosis_screen.dart` contain the complete UI.
- **Widgets**: `symptom_input_widget.dart` and `audio_recorder_widget.dart` are ready to use.
- **`audio_service.dart`**: A complete service for handling audio recording and file management.

### 2.2 Your Goal

Your main task is to bring the app to life by implementing the `GeminiService`. Currently, it contains placeholder methods that return mock data. You will replace these with actual calls to the Gemini AI API.

### 2.3 Understanding the Architecture

Our app follows a clean architecture pattern:

- **Models**: Data structures (Symptom, DiagnosisResult).
- **Services**: The communication layer. You'll be working in `GeminiService`. `AudioService` is already complete.
- **Screens**: Full-page views (Home, Diagnosis).
- **Widgets**: Reusable UI components.

---

## Step 3: Implement the Gemini AI Service

This is the core of the codelab. You will be working in `lib/services/gemini_service.dart`.

### 3.1 The Starter Code

Open `lib/services/gemini_service.dart`. It contains placeholder methods that return mock data. This allows the UI to function while you implement the AI logic.

Here's the initial content of the file:

```dart
// lib/services/gemini_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/symptom.dart';
import '../models/diagnosis_result.dart';

class GeminiService {
  // MOCK IMPLEMENTATION
  // In this codelab, you will replace these mock methods with real API calls.

  /// Analyzes symptoms and returns a diagnosis
  Future<DiagnosisResult> analyzeSymptoms(List<Symptom> symptoms) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Return mock data
    return DiagnosisResult.fromAIResponse(
      '''
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
      ''',
    );
  }

  /// Extracts symptoms from an audio file
  Future<List<Symptom>> extractSymptomsFromAudio(String audioPath) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    // Return mock data
    return [
      Symptom(name: 'Headache', severity: 6, duration: '3 days', description: 'From audio'),
      Symptom(name: 'Fever', severity: 5, duration: '2 days', description: 'From audio'),
    ];
  }

  /// Asks a follow-up question about the diagnosis
  Future<String> askFollowUp(String question) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return 'This is a mock response to your follow-up question: "$question". In a real app, I would provide a more detailed answer.';
  }

  void dispose() {
    // No resources to dispose in mock implementation
  }
}
```

### 3.2 Initialize the Gemini Model

First, let's set up the actual Gemini `GenerativeModel` and `ChatSession`.

Replace the mock `GeminiService` class content with the following initialization code. This will read your API key and configure the model.

```dart
// lib/services/gemini_service.dart

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

  // ... methods will be added here

  void dispose() {
    // Clean up if needed
  }

  /// Resets the chat session
  void resetChat() {
    _chatSession = _model.startChat(history: []);
  }
}
```

### 3.3 Implement Symptom Analysis from Text

Now, let's implement the `analyzeSymptoms` method. This method takes a list of `Symptom` objects, builds a detailed prompt, and sends it to Gemini.

Add the following methods inside your `GeminiService` class:

```dart
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
```

### 3.4 Implement Symptom Extraction from Audio

Next, implement the `extractSymptomsFromAudio` method. This powerful feature uses Gemini's multimodal capabilities to process an audio file and extract structured data from it.

Add this method to your `GeminiService` class:

````dart
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

````

### 3.5 Implement Follow-up Questions

Finally, implement the `askFollowUp` method. This uses the `_chatSession` to maintain conversational context, allowing the user to ask questions about their diagnosis.

Add this method to your `GeminiService` class:

```dart
  /// Asks a follow-up question about the diagnosis
  Future<String> askFollowUp(String question) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(question));
      return response.text ?? 'No response generated';
    } catch (e) {
      throw Exception('Failed to process follow-up: $e');
    }
  }
```

Your `GeminiService` is now fully implemented! The rest of the app's UI will now work with the live AI service.

---

## Step 4: Run the App and Test

Since the UI is already built in the starter project, and you've now implemented the core AI logic, the app is ready to be tested!

### 4.1 Run the Application

```bash
flutter run
```

### 4.2 Test Cases to Try

**Test Case 1: Simple Symptoms (Text Input)**

- Tap the "Add Symptom" button.
- Add: "Headache" (Severity: 7, Duration: 2 days)
- Add: "Fever" (Severity: 6, Duration: 2 days)
- Tap "Analyze Symptoms".
- **Expected:** The app should display a diagnosis related to a common cold or flu with "Low" urgency.

**Test Case 2: Emergency Symptoms (Text Input)**

- Add: "Chest pain" (Severity: 9, Duration: 1 hour)
- Add: "Difficulty breathing" (Severity: 8, Duration: 30 minutes)
- Tap "Analyze Symptoms".
- **Expected:** The app should display a "High" or "Emergency" urgency level.

**Test Case 3: Voice Input**

- Tap the microphone button.
- Record: "I've been having a severe headache for the past two days, along with a fever and body aches."
- **Expected:** The app should process the audio and add the extracted symptoms to the list. You can then tap "Analyze Symptoms".

**Test Case 4: Follow-up Questions**

- After getting a diagnosis, ask a follow-up question in the chat interface, such as: "What over-the-counter medication can I take?"
- **Expected:** The AI should provide a relevant answer based on the context of the diagnosis.

### 4.3 Verify Key Features

✅ Symptoms can be added, edited, and removed.  
✅ Audio recording works and extracts symptoms correctly.  
✅ AI analysis provides a structured response.  
✅ Follow-up questions maintain context.  
✅ Error handling works (try analyzing with no internet).  
✅ The UI is responsive and intuitive.

---

## Step 5: Error Handling & Edge Cases

### 5.1 Add Network Error Handling

The `analyzeSymptoms` method you implemented already includes timeout and API error handling. This is a great start for building a robust app.

```dart
// From lib/services/gemini_service.dart

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
```

### 5.2 Input Validation

The starter project already includes form validation in the `SymptomInputWidget`. You can review it in `lib/widgets/symptom_input_widget.dart`.

### 5.3 Audio-Specific Error Handling

The provided `AudioService` in `lib/services/audio_service.dart` already contains robust error handling for permissions and recording operations.

---

## Step 6: Deployment Considerations

### 6.1 Security Best Practices

**❌ Never commit your API key to Git.** The starter project's `.gitignore` is already configured to ignore the `.env` file.

**✅ For production, use a backend proxy:**

```
// Production architecture (recommended)
//
// Flutter App → Your Backend API → Gemini API
//
// This keeps your API key secure on the server.
```

### 6.2 Loading States

The starter project already includes loading indicators for a better user experience. You can see them in `home_screen.dart` when the `_isAnalyzing` state is true.

---

## Step 7: Congratulations! 🎉

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

---

**Thank you for completing this codelab! Happy coding! 🚀**
