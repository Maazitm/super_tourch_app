

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torch_light/torch_light.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:screen_brightness/screen_brightness.dart';

class TorchController extends GetxController {
  var isTorchOn = false.obs;
  var isSosActive = false.obs;
  var isBlinkActive = false.obs;
  var isPoliceLightActive = false.obs;
  var isSirenActive = false.obs;
  var isCompassActive = false.obs;
  var isScreenLightActive = false.obs;
  var isNightLightActive = false.obs; // NEW: For study/night light

  // Current screen color for police light effect and screen light
  var policeLightColor = Colors.transparent.obs;

  // Auto-off duration in seconds (0 means no auto-off)
  var autoOffDuration = 0.obs; // Default to no auto-off
  final List<int> availableDurations = [0, 30, 60, 120, 300]; // 0s, 30s, 1min, 2min, 5min

  Timer? _loopTimer;
  Timer? _autoOffTimer;

  bool _isLoopRunning = false;

  final _audioPlayer = AudioPlayer();
  double? _originalBrightness;

  @override
  void onInit() {
    super.onInit();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _audioPlayer.setAsset('assets/sounds/siren.mp3');
        _audioPlayer.setLoopMode(LoopMode.one);
      }
    } catch (e) {
      print('Error loading siren sound: $e');
    }
  }

  /// --- Core Torch Methods ---
  Future<void> _turnOn() async {
    try {
      await TorchLight.enableTorch();
      isTorchOn.value = true;
    } catch (e) {
      Get.snackbar('Torch Error', 'Could not enable torch: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  Future<void> _turnOff() async {
    try {
      await TorchLight.disableTorch();
      isTorchOn.value = false;
    } catch (e) {
      // Error is ignored
    }
  }

  /// Stops all running patterns, turns off the torch, and cancels auto-off timer.
  Future<void> _stopAllPatterns() async {
    _loopTimer?.cancel();
    _autoOffTimer?.cancel();
    _isLoopRunning = false;
    isSosActive.value = false;
    isBlinkActive.value = false;
    isPoliceLightActive.value = false;
    isCompassActive.value = false;
    isNightLightActive.value = false; // NEW: Stop night light
    await _stopScreenLight();
    await _stopSiren();
    await _turnOff();
    policeLightColor.value = Colors.transparent;
  }

  /// Starts the auto-off timer if a duration is set.
  void _startAutoOffTimer() {
    _autoOffTimer?.cancel();
    if (autoOffDuration.value > 0) {
      _autoOffTimer = Timer(Duration(seconds: autoOffDuration.value), () async {
        Get.snackbar(
          'Auto Off',
          'Torch automatically turned off after ${autoOffDuration.value} seconds.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blueGrey.withOpacity(0.8),
          colorText: Colors.white,
        );
        await _stopAllPatterns();
      });
    }
  }

  // --- Public Toggle Methods ---

  /// Toggles the main torch power.
  Future<void> toggleTorch() async {
    if (isSosActive.value ||
        isBlinkActive.value ||
        isPoliceLightActive.value ||
        isSirenActive.value ||
        isScreenLightActive.value ||
        isNightLightActive.value) { // UPDATED
      await _stopAllPatterns();
    } else {
      isTorchOn.value ? await _turnOff() : await _turnOn();
      if (isTorchOn.value) {
        _startAutoOffTimer();
      } else {
        _autoOffTimer?.cancel();
      }
    }
  }

  /// Toggles the SOS pattern.
  Future<void> toggleSos() async {
    if (isSosActive.value) {
      await _stopAllPatterns();
    } else {
      await _stopAllPatterns();
      isSosActive.value = true;
      _isLoopRunning = true;
      _runSosLoop();
      _startAutoOffTimer();
    }
  }

  /// Toggles the fast blink pattern.
  Future<void> toggleBlink() async {
    if (isBlinkActive.value) {
      await _stopAllPatterns();
    } else {
      await _stopAllPatterns();
      isBlinkActive.value = true;
      _isLoopRunning = true;
      _loopTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (!_isLoopRunning || !isBlinkActive.value) {
          timer.cancel();
          _stopAllPatterns();
          return;
        }
        if (isTorchOn.value) {
          _turnOff();
        } else {
          _turnOn();
        }
      });
      _startAutoOffTimer();
    }
  }

  /// Toggles the Police Light screen pattern.
  Future<void> togglePoliceLight() async {
    if (isPoliceLightActive.value) {
      await _stopAllPatterns();
    } else {
      await _stopAllPatterns();
      isPoliceLightActive.value = true;
      _isLoopRunning = true;
      _runPoliceLightLoop();
      _startAutoOffTimer();
    }
  }

  /// Toggles the audio siren.
  Future<void> toggleSiren() async {
    if (isSirenActive.value) {
      await _stopAllPatterns();
    } else {
      await _stopAllPatterns();
      isSirenActive.value = true;
      _startSiren();
      _startAutoOffTimer();
    }
  }

  /// Toggles the compass display.
  void toggleCompass() {
    if (isCompassActive.value) {
      isCompassActive.value = false;
    } else {
      _stopAllPatterns();
      isCompassActive.value = true;
    }
  }

  /// Toggles the screen light mode.
  Future<void> toggleScreenLight() async {
    if (isScreenLightActive.value) {
      await _stopScreenLight();
    } else {
      await _stopAllPatterns();
      isScreenLightActive.value = true;
      await _activateScreenLight(Colors.white, 1.0);
      _startAutoOffTimer();
    }
  }

  /// NEW: Toggles the night light / study light mode.
  Future<void> toggleNightLight() async {
    if (isNightLightActive.value) {
      await _stopAllPatterns();
    } else {
      await _stopAllPatterns();
      isNightLightActive.value = true;
      // A warm, dim yellow light for studying
      await _activateScreenLight(const Color.fromARGB(255, 248, 240, 176), 0.5);
      _startAutoOffTimer();
    }
  }

  // --- Pattern Logic ---

  Future<void> _runSosLoop() async {
    while (_isLoopRunning && isSosActive.value) {
      await _blink(3, 200);
      if (!_isLoopRunning || !isSosActive.value) break;

      await _blink(3, 600);
      if (!_isLoopRunning || !isSosActive.value) break;

      await _blink(3, 200);
      if (!_isLoopRunning || !isSosActive.value) break;

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!_isLoopRunning || !isSosActive.value) break;
    }
    if ((!_isLoopRunning || !isSosActive.value) && (isSosActive.value || isTorchOn.value)) {
      _stopAllPatterns();
    }
  }

  Future<void> _runPoliceLightLoop() async {
    while (_isLoopRunning && isPoliceLightActive.value) {
      policeLightColor.value = const Color.fromARGB(255, 1, 86, 244);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!_isLoopRunning || !isPoliceLightActive.value) break;

      policeLightColor.value = const Color.fromARGB(255, 251, 18, 1);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!_isLoopRunning || !isPoliceLightActive.value) break;
    }
    if ((!_isLoopRunning || !isPoliceLightActive.value) && (isPoliceLightActive.value || isTorchOn.value)) {
      _stopAllPatterns();
    }
  }

  Future<void> _blink(int count, int durationMs) async {
    for (int i = 0; i < count; i++) {
      if (!_isLoopRunning || !isSosActive.value) break;
      await _turnOn();
      await Future.delayed(Duration(milliseconds: durationMs));
      if (!_isLoopRunning || !isSosActive.value) break;
      await _turnOff();
      await Future.delayed(const Duration(milliseconds: 250));
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // --- Siren Logic ---
  void _startSiren() {
    if (Platform.isAndroid || Platform.isIOS) {
      if (_audioPlayer.processingState != ProcessingState.ready) {
        _audioPlayer.setAsset('assets/sounds/siren.mp3').then((_) {
          _audioPlayer.setVolume(1.0);
          _audioPlayer.play();
        });
      } else {
        _audioPlayer.setVolume(1.0);
        _audioPlayer.play();
      }
    } else {
      Get.snackbar('Siren Not Supported', 'Audio siren is only available on mobile devices.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blueGrey.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  Future<void> _stopSiren() async {
    isSirenActive.value = false;
    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero);
  }

  // --- Screen Light Logic ---
  Future<void> _activateScreenLight(Color color, double brightness) async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        _originalBrightness = await ScreenBrightness().current;
        await ScreenBrightness().setScreenBrightness(brightness);
        policeLightColor.value = color;
      } catch (e) {
        Get.snackbar('Screen Light Error', 'Could not adjust screen brightness: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white);
      }
    } else {
      Get.snackbar('Screen Light Not Supported', 'Screen brightness control is only available on mobile devices.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blueGrey.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  Future<void> _stopScreenLight() async {
    isScreenLightActive.value = false;
    policeLightColor.value = Colors.transparent;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        if (_originalBrightness != null) {
          await ScreenBrightness().setScreenBrightness(_originalBrightness!);
          _originalBrightness = null;
        } else {
          await ScreenBrightness().resetScreenBrightness();
        }
      } catch (e) {
        Get.snackbar('Screen Brightness Error', 'Could not reset screen brightness: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white);
      }
    }
  }

  // --- Auto-off duration selection ---
  void setAutoOffDuration(int seconds) {
    autoOffDuration.value = seconds;
    if (isTorchOn.value ||
        isSosActive.value ||
        isBlinkActive.value ||
        isPoliceLightActive.value ||
        isSirenActive.value ||
        isScreenLightActive.value ||
        isNightLightActive.value) { // UPDATED
      _startAutoOffTimer();
    }
    String message = seconds == 0
        ? 'Auto-off disabled.'
        : 'Auto-off set for ${seconds ~/ 60 > 0 ? '${seconds ~/ 60} min ' : ''}${seconds % 60} sec.';
    Get.snackbar(
      'Timer Set',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  /// Ensures the torch is off and timers are cancelled when the app is closed.
  @override
  void onClose() {
    _stopAllPatterns();
    _audioPlayer.dispose();
    super.onClose();
  }
}
