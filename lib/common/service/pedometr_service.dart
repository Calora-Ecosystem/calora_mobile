import 'dart:async';
import 'dart:io';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PedometerService {
  // Callbacks for UI updates
  final ValueChanged<int> onStepCountUpdate;
  final ValueChanged<String> onStatusUpdate;
  final ValueChanged<bool> onPermissionUpdate;
  final ValueChanged<String> onError;

  // Stream subscriptions
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  // State variables
  bool _permissionGranted = false;
  bool _isPedometerAvailable = false;
  bool _isListening = false;

  PedometerService({
    required this.onStepCountUpdate,
    required this.onStatusUpdate,
    required this.onPermissionUpdate,
    required this.onError,
  });

  // Initialize the pedometer service
  Future<void> initialize() async {
    try {
      final granted = await _checkActivityRecognitionPermission();
      _permissionGranted = granted;
      onPermissionUpdate(granted);

      if (granted) {
        await _checkPedometerAvailability();
      } else {
        onError('Permission not granted');
      }
    } catch (e) {
      onError('Initialization failed: ${e.toString()}');
    }
  }

  // Check and request permission
  Future<bool> _checkActivityRecognitionPermission() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.activityRecognition.status;
        if (!status.isGranted) {
          status = await Permission.activityRecognition.request();
        }
        return status.isGranted;
      } else if (Platform.isIOS) {
        var status = await Permission.sensors.status;
        if (!status.isGranted) {
          status = await Permission.sensors.request();
        }
        return status.isGranted;
      }
      return false;
    } catch (e) {
      onError("Permission check error: $e");
      return false;
    }
  }

  // Check if pedometer is available
  Future<void> _checkPedometerAvailability() async {
    try {
      // Try to access pedometer streams
      final stepStream = await Pedometer.stepCountStream;
      final statusStream = await Pedometer.pedestrianStatusStream;

      _isPedometerAvailable = true;

      // Start listening if we're not already
      if (!_isListening) {
        _startListening(stepStream, statusStream);
      }
    } catch (e) {
      _isPedometerAvailable = false;
      onError('Step counter not available: ${e.toString()}');
    }
  }

  // Start listening to pedometer streams
  void _startListening(Stream<StepCount> stepStream, Stream<PedestrianStatus> statusStream) {
    _stepCountSubscription = stepStream.listen(
      onStepCount,
      onError: onStepCountError,
    );

    _pedestrianStatusSubscription = statusStream.listen(
      onPedestrianStatusChanged,
      onError: onPedestrianStatusError,
    );

    _isListening = true;
  }

  // Handle step count updates
  void onStepCount(StepCount event) {
    onStepCountUpdate(event.steps);
  }

  // Handle status updates
  void onPedestrianStatusChanged(PedestrianStatus event) {
    onStatusUpdate(event.status);
  }

  // Handle step count errors
  void onStepCountError(error) {
    onError('Step count error: ${error.toString()}');
  }

  // Handle status errors
  void onPedestrianStatusError(error) {
    onError('Status error: ${error.toString()}');
  }

  // Request permission (can be called from UI)
  Future<void> requestPermission() async {
    try {
      final granted = await _checkActivityRecognitionPermission();
      _permissionGranted = granted;
      onPermissionUpdate(granted);

      if (granted) {
        await _checkPedometerAvailability();
      }
    } catch (e) {
      onError('Permission request failed: $e');
    }
  }

  // Check current permission status
  bool get isPermissionGranted => _permissionGranted;

  // Check if pedometer is available
  bool get isPedometerAvailable => _isPedometerAvailable;

  // Check if service is listening
  bool get isListening => _isListening;

  // Dispose of resources
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _isListening = false;
  }
}