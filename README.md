# linea_de_vida

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Whisper Speech Recognition Setup

This project uses offline voice recognition via **whisper.cpp** (desktop platforms)
and alternatives for web and mobile.

### Platform-Specific Implementations

#### **Web (Primary prototype target)**

For web, the `record` package and `Process.run()` are not available.
Instead, use the **Web Speech API** via the `js` package:

1. Add `js: ^0.6.7` to `pubspec.yaml` (or use `web_speech_api` if available).
2. Update `SpeechService` to use JavaScript interop for web:
   ```dart
   import 'dart:js' as js;
   // Access window.SpeechRecognition or navigator.mediaDevices.getUserMedia
   ```
3. For production, consider a lightweight wrapper or existing package like
   `speech_recognition` (check pub.dev for current web support).

Alternatively, deploy to Firebase Hosting with a lightweight transcription
service (e.g., toggling to local web workers or a backend Whisper instance).

#### **Desktop (Windows, macOS, Linux)**

Uses the local `whisper.cpp` binary:

1. **Download the whisper.cpp binary** for your platform (see
   https://github.com/ggerganov/whisper.cpp) and make sure it is
   accessible in your PATH or bundled with the app.
2. **Ensure you have a model file** (e.g. `ggml-base.bin`) and note its
   path when invoking the binary (modify `SpeechService._runWhisper` if needed).
3. The app records audio to a temporary WAV file and passes it to the
   whisper CLI for transcription.

#### **Mobile (iOS, Android)**

The `record` package works on mobile, but `Process.run()` does not.
Options:

- Use native APIs via method channels (iOS: `SFSpeechRecognizer`,
  Android: `SpeechRecognizer`) and wrap them in a Dart plugin.
- Or, fall back to an online service / backend endpoint.
- For prototyping, consider disabling voice on mobile or using a simple
  fallback UI.

### Current Implementation

The `SpeechService` class currently implements desktop support.
To enable web support:

1. **Add a `kIsWeb` check** in `SpeechService` and provide a separate
   implementation for web.
2. **Use a platform-specific factory** or method to instantiate the
   correct engine:
   ```dart
   factory SpeechService() {
     if (kIsWeb) return WebSpeechService();
     return DesktopSpeechService();
   }
   ```
3. Update `VoiceControlWidget` to handle any UI differences between
   platforms (e.g., streaming vs. button-based recording).

### Dependencies

Current `pubspec.yaml` includes:
- `record: ^4.4.0` — for audio capture (desktop & mobile).

For web, additionally add:
- `js: ^0.6.7` — to access JavaScript Web Speech API.

Alternatively, use a dedicated voice plugin that supports multiple platforms.

### Next Steps

1. **For your web prototype**, prioritise the **Web Speech API** via
   `js` interop or a lightweight wrapper.
2. **For mobile**, decide whether to use native APIs (requires more
   setup) or defer to a later phase.
3. **Conditionally import** the right `SpeechService` implementation
   based on `kIsWeb` and `Platform`.
