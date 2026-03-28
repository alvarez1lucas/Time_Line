// Widget to display voice control status or buttons.

import 'package:flutter/material.dart';
import '../../services/speech_service.dart';

class VoiceControlWidget extends StatefulWidget {
  const VoiceControlWidget({Key? key, required this.onCommand}) : super(key: key);

  /// Called when speech recognition produces a final command string.
  final void Function(String command) onCommand;

  @override
  State<VoiceControlWidget> createState() => _VoiceControlWidgetState();
}

class _VoiceControlWidgetState extends State<VoiceControlWidget> {
  final SpeechService _speech = SpeechService();
  String _lastWords = '';
  bool _listening = false;

  void _toggleListening() async {
    if (_listening) {
      await _speech.stopListening();
      setState(() => _listening = false);
      widget.onCommand(_lastWords.toLowerCase());
    } else {
      await _speech.startListening((words) {
        setState(() {
          _lastWords = words;
        });
      });
      setState(() => _listening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          icon: Icon(_listening ? Icons.mic : Icons.mic_none),
          label: Text(_listening ? 'Listening...' : 'Speak'),
          onPressed: _toggleListening,
        ),
        if (_lastWords.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Heard: $_lastWords', style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }
}
