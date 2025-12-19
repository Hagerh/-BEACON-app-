import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/presentation/routes/app_routes.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Import Cubits
import 'package:projectdemo/business/cubit/network_dashboard_cubit.dart';
import 'package:projectdemo/business/cubit/private_chat_cubit.dart';

class VoiceWidget extends StatefulWidget {
  const VoiceWidget({super.key});

  @override
  State<VoiceWidget> createState() => _VoiceWidgetState();
}

class _VoiceWidgetState extends State<VoiceWidget> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  // Track if a voice session is active
  bool _isSessionActive = false;

  // Track if currently listening
  bool _isListening = false;
// Track if processing a command
  
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
  
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }


  void _toggleSession() {
    if (_isSessionActive) {
      _stopSession();
    } else {
      _startSession();
    }
  }

  void _startSession() {
    setState(() => _isSessionActive = true);
    _listen(); 
  }

  void _stopSession() {
    setState(() {
      _isSessionActive = false;
      _isListening = false;
      _isProcessing = false;
    });
    _speech.stop();
    _flutterTts.stop();
  }


  void _listen() async {
    if (!_isSessionActive || _isProcessing) return;

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');

          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);

            // Automatically restart if session is still active and we aren't processing a command
            if (_isSessionActive && !_isProcessing && mounted) {
              // Small delay to prevent tight loops
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_isSessionActive) _listen();
              });
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('STT Error: $errorNotification');
          if (mounted) {
            setState(() => _isListening = false);

            if (_isSessionActive &&
                errorNotification.errorMsg == 'error_no_match') {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_isSessionActive) _listen();
              });
            } else if (_isSessionActive) {
              _stopSession();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: ${errorNotification.errorMsg}")),
              );
            }
          }
        },
      );

      if (available) {
        if (mounted) setState(() => _isListening = true);

        _speech.listen(
          onResult: (val) {
     
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
      } else {
        _stopSession();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone not available")),
          );
        }
      }
    }
  }

void _processCommand(String command) async {
    _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });
    }

    final lowerCommand = command.toLowerCase().trim();
    debugPrint("Processing command: $lowerCommand");

    // Get the current route name
    final currentRoute = ModalRoute.of(context)?.settings.name;

    try {
      if (lowerCommand.contains("stop listening")) {
        await _speak("Goodbye");
        _stopSession();
        return;
      } 
      
      // ---navigation commands---
      
      else if (lowerCommand.contains("home") || lowerCommand == "go back") {
        if (currentRoute == landingScreen) {
           await _speak("You are already on the Home screen");
        } else {
           await _speak("Going Home");
           if (mounted) {
             Navigator.pushNamedAndRemoveUntil(
               context,
               landingScreen,
               (route) => false,
             );
           }
        }
      } 
      
      else if (lowerCommand.contains("create network")) {
        //  Check if we are already here
        if (currentRoute == createNetworkScreen) {
          await _speak("You are already on the Create Network screen");
        } else {
          await _speak("Opening Create Network");
          if (mounted) Navigator.pushNamed(context, createNetworkScreen);
        }
      } 
      
      else if (lowerCommand.contains("join network")) {
        if (currentRoute == networkScreen) {
           await _speak("You are already on the Join Network screen");
        } else {
           await _speak("Opening Join Network");
           if (mounted) Navigator.pushNamed(context, networkScreen);
        }
      } 
      
      else if (lowerCommand.contains("profile")) {
        if (currentRoute == profileScreen) {
           await _speak("You are already on the Profile screen");
        } else {
           await _speak("Opening Profile");
           if (mounted) Navigator.pushNamed(context, profileScreen);
        }
      } 
      
      else if (lowerCommand.contains("resources")) {
        if (currentRoute == resourceScreen) {
           await _speak("You are already on the Resources screen");
        } else {
           await _speak("Opening Resources");
           if (mounted) Navigator.pushNamed(context, resourceScreen);
        }
      }
      
      // --- broadcast and chat commands ---
      
      
      else if (lowerCommand.contains("broadcast")) {
        final message = _extractMessage(lowerCommand, "broadcast");
        if (message.isNotEmpty) {
          try {
            final cubit = context.read<NetworkDashboardCubit>();
            cubit.broadcastMessage(message);
            await _speak("Broadcasting message: $message");
          } catch (e) {
            await _speak("You can only broadcast from the Network Dashboard.");
          }
        } else {
          await _speak("Say broadcast followed by your message.");
        }
      } 
      
      else if (lowerCommand.startsWith("send")) {
        final message = _extractMessage(lowerCommand, "send");
        if (message.isNotEmpty) {
          try {
            context.read<PrivateChatCubit>().sendMessage(message);
            await _speak("Message sent");
          } catch (e) {
            await _speak("Open a private chat to send messages.");
          }
        } else {
          await _speak("Say send followed by your message.");
        }
      } 
      
      else if (lowerCommand.contains("leave network")) {
        try {
          await context.read<NetworkDashboardCubit>().leaveNetwork();
          await _speak("Leaving network");
          if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        } catch (e) {
          await _speak("You are not in a network.");
        }
      } else {
        await _speak("I didn't understand that.");
      }
    } catch (e) {
      debugPrint("Voice Command Error: $e");
      await _speak("Something went wrong.");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        if (_isSessionActive) {
          _listen();
        }
      }
    }
  }

  String _extractMessage(String fullCommand, String keyword) {
    final index = fullCommand.indexOf(keyword);
    if (index != -1 && fullCommand.length > index + keyword.length) {
      return fullCommand.substring(index + keyword.length).trim();
    }
    return "";
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
      onPressed: _toggleSession,
      tooltip: _isSessionActive ? 'Stop Listening' : 'Start Voice Control',
      // Red = mic on, Green =Speaking
      backgroundColor: _isListening
          ? AppColors.alertRed
          : (_isSessionActive ? Colors.green : AppColors.buttonPrimary),
      child: Icon(
   
        _isListening
            ? Icons.mic
            : (_isSessionActive ? Icons.hearing : Icons.mic_none),
        color: AppColors.primaryBackground,
      ),
    );
  }
}
