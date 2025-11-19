import 'package:diagnosis_app/models/diagnosis_result.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/symptom.dart';
import '../services/gemini_service.dart';
import 'diagnosis_screen.dart';
import '../widgets/symptom_input_widget.dart';
import '../widgets/audio_recorder_widget.dart';

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
        actions: [
          // Audio input button
          IconButton(
            onPressed: _showAudioRecorder,
            icon: const Icon(Icons.mic),
            tooltip: 'Voice Input',
          ),
        ],
      ),
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
                  Icon(Icons.health_and_safety, size: 48, color: Colors.white),
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
      final prompt =
          '''
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
              symptoms:
                  [], // Voice symptoms don't have structured Symptom objects
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first symptom',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
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
            builder: (context) =>
                DiagnosisScreen(result: result, symptoms: _symptoms),
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
