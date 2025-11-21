# AI-Powered Diagnosis Assistant

This is a Flutter-based mobile application that acts as an AI-powered medical diagnosis assistant. It allows users to input their symptoms either manually or through voice recording, and then uses Google's Gemini AI to provide a preliminary health assessment.

## 🚀 Features

- **Symptom Input**: Add, edit, and delete symptoms with details like severity, duration, and description.
- **Voice-to-Symptom**: Record your symptoms using your voice. The app uses Gemini AI to extract structured symptom data from the audio.
- **AI-Powered Analysis**: Get a preliminary health assessment based on your symptoms, including possible conditions, an urgency level, and recommended actions.
- **Conversational Follow-up**: Ask follow-up questions about your diagnosis in a chat-like interface.
- **Clean & Modern UI**: A user-friendly interface built with Material 3.

## 🛠️ Technologies Used

- **Framework**: [Flutter](https://flutter.dev/)
- **AI Model**: [Google Gemini](https://ai.google.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **AI Integration**: [google_generative_ai](https://pub.dev/packages/google_generative_ai)
- **Audio Recording**: [record](https://pub.dev/packages/record)
- **Environment Variables**: [flutter_dotenv](https://pub.dev/packages/flutter_dotenv)

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- A Gemini API Key. You can get one for free at [Google AI Studio](https://aistudio.google.com/app/apikey).

### Setup

1.  **Clone the repository:**

    ```bash
    git clone <repository_url>
    cd diagnosis_app
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Set up your API Key:**

    - Create a file named `.env` in the root of the project.
    - Add your Gemini API key to the file like this:

      ```
      GEMINI_API_KEY=your_api_key_here
      ```

4.  **Run the app:**

    ```bash
    flutter run
    ```

## 📂 Project Structure

The project follows a clean architecture to separate concerns:

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models (Symptom, DiagnosisResult)
│   ├── diagnosis_result.dart
│   └── symptom.dart
├── screens/                  # UI for each screen
│   ├── diagnosis_screen.dart
│   └── home_screen.dart
├── services/                 # Business logic and external communication
│   ├── audio_service.dart
│   ├── gemini_service.dart
│   └── gemini_mock_service.dart
└── widgets/                  # Reusable UI components
    ├── audio_recorder_widget.dart
    └── symptom_input_widget.dart
```

## workshop/

This project also contains a `workshop/` directory with a `CODELAB.md` file. This codelab is designed to guide developers through the process of building this app from a starter branch, focusing on the integration of the Gemini AI service.
