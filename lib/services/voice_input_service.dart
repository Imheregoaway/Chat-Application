import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;

  bool get isListening => _listening;
  bool get isAvailable => _available;

  Future<bool> initialize() async {
    try {
      _available = await _speech.initialize(
        onError: (e) => debugPrint('Speech error: $e'),
        onStatus: (s) => debugPrint('Speech status: $s'),
      );
    } catch (e) {
      debugPrint('Speech init failed: $e');
      _available = false;
    }
    return _available;
  }

  Future<void> startListening({
    required void Function(String text) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_available || _listening) return;
    _listening = true;
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          _listening = false;
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
  }

  void dispose() {
    _speech.stop();
  }
}
