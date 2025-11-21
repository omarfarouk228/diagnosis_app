import 'dart:async';
import 'package:diagnosis_app/models/symptom.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/gemini_service.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(List<Symptom> symptoms) onSymptomsExtracted;

  const AudioRecorderWidget({super.key, required this.onSymptomsExtracted});

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
      width: MediaQuery.sizeOf(context).width,
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Text(
            _isRecording
                ? 'Describe your symptoms'
                : 'Tap the microphone to start',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
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
          child: const Icon(Icons.mic, color: Colors.white, size: 50),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

      if (!mounted) return;
      // Transcribe audio using Gemini
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final symptoms = await geminiService.extractSymptomsFromAudio(audioPath);

      // Delete the audio file after transcription
      await _audioService.deleteRecording(audioPath);

      if (mounted) {
        widget.onSymptomsExtracted(symptoms);
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
