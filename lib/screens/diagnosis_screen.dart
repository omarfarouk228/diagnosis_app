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
    _messages.add(
      ChatMessage(
        text: widget.result.additionalNotes,
        isUser: false,
        timestamp: widget.result.timestamp,
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnosis Results'), elevation: 0),
      body: Column(
        children: [
          // Results summary
          _buildResultsSummary(),

          // Chat messages
          Expanded(child: _buildChatSection()),

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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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
      _messages.add(
        ChatMessage(text: question, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _questionController.clear();

    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final response = await geminiService.askFollowUp(question);

      setState(() {
        _messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
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
