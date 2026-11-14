import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as st;

import '../../core/interfaces/gloss_engine.dart';

class SpeechToTextInput implements SpeechInput {
  SpeechToTextInput({st.SpeechToText? speechToText})
    : _speechToText = speechToText ?? st.SpeechToText();

  final st.SpeechToText _speechToText;
  bool _initialized = false;

  @override
  Future<bool> isAvailable() async {
    if (!_initialized) {
      _initialized = true;
      final initialized = await _speechToText.initialize();
      if (!initialized) {
        return false;
      }
    }
    return _speechToText.isAvailable;
  }

  @override
  Stream<String> listen() {
    final controller = StreamController<String>.broadcast();

    unawaited(_startListening(controller));
    return controller.stream;
  }

  Future<void> _startListening(StreamController<String> controller) async {
    if (!await isAvailable()) {
      if (!controller.isClosed) {
        controller.addError(StateError('Voice input is unavailable.'));
        await controller.close();
      }
      return;
    }

    await _speechToText.listen(
      onResult: (result) {
        if (controller.isClosed) {
          return;
        }

        final text = result.recognizedWords.trim();
        if (text.isNotEmpty) {
          controller.add(text);
        }

        if (result.finalResult) {
          unawaited(controller.close());
        }
      },
      listenOptions: st.SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }
}
