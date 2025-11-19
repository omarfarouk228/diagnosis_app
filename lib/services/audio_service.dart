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
      return Duration(milliseconds: (amplitude.current * 1000).toInt());
    } catch (e) {
      return Duration.zero;
    }
  }

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
