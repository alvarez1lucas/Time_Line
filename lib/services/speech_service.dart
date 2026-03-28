// Service handling speech-to-text logic using OpenAI Whisper API.
// Records audio in AAC format (.m4a) and sends it to OpenAI for transcription.

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

/// Speech recognition via OpenAI Whisper API.
/// Records audio locally and uploads it for transcription.
/// Requires an OpenAI API key (set in _apiKey).
class SpeechService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  void Function(String)? _callback;

  // TODO: Move to environment variable or secure storage
  static const String _apiKey = 'YOUR_OPENAI_API_KEY_HERE';

  /// Checks microphone permission.
  Future<bool> init() async {
    return await _recorder.hasPermission();
  }

  /// Starts recording audio in AAC format (.m4a).
  /// The [callback] will be invoked once recording stops and transcription completes.
  Future<void> startListening(
    void Function(String recognized) callback, {
    bool continuous = false,
  }) async {
    if (!await init()) return;
    _callback = callback;

    final filePath = 'speech_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);
    _recording = true;
  }

  /// Stops recording and sends the audio file to OpenAI Whisper API for transcription.
  Future<void> stopListening() async {
    if (!_recording) return;
    final path = await _recorder.stop();
    _recording = false;

    if (path == null) return;
    try {
      final transcription = await _transcribeWithOpenAI(path);
      if (_callback != null) _callback!(transcription);
    } catch (e) {
      print('OpenAI transcription error: $e');
      if (_callback != null) _callback!('Error en transcripción');
    }
  }

  /// Sends the recorded audio file to OpenAI Whisper API.
  Future<String> _transcribeWithOpenAI(String audioPath) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found');
    }

    final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = 'es'
      ..files.add(await http.MultipartFile.fromPath('file', audioPath));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      // Parse JSON response (assuming { "text": "transcription" })
      final json = responseBody; // Simple parsing, use jsonDecode in real app
      return json.replaceFirst('{"text":"', '').replaceFirst('"}', '');
    } else {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
  }

  bool get isListening => _recording;
  bool get isAutomatic => false;
}
