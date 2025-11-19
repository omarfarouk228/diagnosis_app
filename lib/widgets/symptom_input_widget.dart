import 'package:flutter/material.dart';
import '../models/symptom.dart';

class SymptomInputWidget extends StatefulWidget {
  final Function(Symptom) onSymptomAdded;

  const SymptomInputWidget({super.key, required this.onSymptomAdded});

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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                if (value.trim().length < 2) {
                  return 'Symptom name too short';
                }
                if (value.trim().length > 100) {
                  return 'Symptom name too long';
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
                return DropdownMenuItem(value: duration, child: Text(duration));
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
              child: const Text('Add Symptom', style: TextStyle(fontSize: 16)),
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
