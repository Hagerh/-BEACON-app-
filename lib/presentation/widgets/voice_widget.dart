import 'package:flutter/material.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/presentation/routes/app_routes.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceWidget extends StatefulWidget {
  const VoiceWidget({super.key});

  @override
  State<VoiceWidget> createState() => _VoiceWidgetState();
}

class _VoiceWidgetState extends State<VoiceWidget> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    
    // Set up completion handler
    _flutterTts.setCompletionHandler(() {
      debugPrint('TTS Completed');
    });
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  void _listen() async {
    if (_isProcessing) return; // Prevent multiple simultaneous calls
    
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('STT Error: $errorNotification');
          if (mounted) {
            setState(() {
              _isListening = false;
              _isProcessing = false;
            });
            
         
            if (errorNotification.errorMsg != 'error_no_match') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: ${errorNotification.errorMsg}")),
              );
            } else {
              
              _speak("I didn't hear anything, please try again");
            }
          }
        },
      );

      if (available) {
        setState(() => _isProcessing = true);
      
        await _speak("Listening for your command");
        
        // delay after TTS completes to ensure audio output has stopped
        await Future.delayed(const Duration(milliseconds: 500));
        
      
        if (mounted) {
          setState(() {
            _isListening = true;
            _isProcessing = false;
          });
          
          _speech.listen(
            onResult: (val) {
              debugPrint('Recognized: ${val.recognizedWords}');
              
              // Process when we have final results with reasonable confidence
              if (val.finalResult && val.recognizedWords.isNotEmpty) {
                _processCommand(val.recognizedWords);
              }
            },
            listenFor: const Duration(seconds: 10),
            pauseFor: const Duration(seconds: 3),
            partialResults: false,
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation,
          );
        }
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone not available")),
        );
      }
    } else {
      // Stop listening if already listening
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processCommand(String command) async {
    if (_isProcessing) return; // Prevent double processing
    
    setState(() => _isProcessing = true);
    
    final lowerCommand = command.toLowerCase().trim();
    debugPrint("Processing command: $lowerCommand");

    // Stop listening immediately
    _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }

    //  commands
    if (lowerCommand.contains("create")) {
      await _speak("Opening Create Network");
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pushNamed(context, createNetworkScreen);
    } 
    else if (lowerCommand.contains("join")) {
      await _speak("Opening Join Network");
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pushNamed(context, networkScreen);
    } 
    else if (lowerCommand.contains("profile")) {
      await _speak("Going to Profile");
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pushNamed(context, profileScreen);
    } 
    else {
      await _speak("I didn't understand that command");
    }
    
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      onPressed: _isProcessing ? null : _listen,
      tooltip: 'Voice Command',
      backgroundColor: _isListening 
          ? AppColors.alertRed 
          : (_isProcessing ? Colors.grey : AppColors.buttonPrimary),
      child: Icon(
        _isListening ? Icons.mic : (_isProcessing ? Icons.hourglass_empty : Icons.mic_none),
        color: AppColors.primaryBackground,
      ),
    );
  }
}