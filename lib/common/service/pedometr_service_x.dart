// import 'dart:async';
// import 'dart:io';
// import 'package:pedometer/pedometer.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
//
// class PedometerService {
//   // Callbacks for UI updates
//   final ValueChanged<int> onStepCountUpdate;
//   final ValueChanged<String> onStatusUpdate;
//   final ValueChanged<bool> onPermissionUpdate;
//   final ValueChanged<String> onError;
//
//   // Stream subscriptions
//   StreamSubscription<StepCount>? _stepCountSubscription;
//   StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
//
//   // State variables
//   bool _permissionGranted = false;
//   bool _isPedometerAvailable = false;
//   bool _isListening = false;
//
//   PedometerService({
//     required this.onStepCountUpdate,
//     required this.onStatusUpdate,
//     required this.onPermissionUpdate,
//     required this.onError,
//   });
//
//   // Initialize the pedometer service
//   Future<void> initialize() async {
//     try {
//       final granted = await _checkPhysicalActivityPermission();
//       _permissionGranted = granted;
//       onPermissionUpdate(granted);
//
//       if (granted) {
//         await _checkPedometerAvailability();
//       } else {
//         onError('Physical activity permission not granted');
//       }
//     } catch (e) {
//       onError('Initialization failed: ${e.toString()}');
//     }
//   }
//
//   // Check and request physical activity permission (for past 24 hours data access)
//   Future<bool> _checkPhysicalActivityPermission() async {
//     try {
//       if (Platform.isAndroid) {
//         // Request multiple permissions for comprehensive access
//         Map<Permission, PermissionStatus> permissions = await [
//           Permission.activityRecognition,
//           Permission.sensors,
//         ].request();
//
//         // Check if activity recognition is granted (main permission for step counting)
//         bool activityRecognitionGranted = permissions[Permission.activityRecognition]?.isGranted ?? false;
//         bool sensorsGranted = permissions[Permission.sensors]?.isGranted ?? false;
//
//         if (kDebugMode) {
//           print('Activity Recognition Permission: $activityRecognitionGranted');
//           print('Sensors Permission: $sensorsGranted');
//         }
//
//         // Activity recognition is the primary permission needed
//         return activityRecognitionGranted;
//
//       } else if (Platform.isIOS) {
//         // For iOS, request motion & fitness permission
//         var status = await Permission.sensors.status;
//         if (!status.isGranted) {
//           status = await Permission.sensors.request();
//         }
//
//         if (kDebugMode) {
//           print('iOS Sensors Permission: ${status.isGranted}');
//         }
//
//         return status.isGranted;
//       }
//       return false;
//     } catch (e) {
//       onError("Physical activity permission check error: $e");
//       return false;
//     }
//   }
//
//   // Check if pedometer is available
//   Future<void> _checkPedometerAvailability() async {
//     try {
//       // Try to access pedometer streams
//       final stepStream = await Pedometer.stepCountStream;
//       final statusStream = await Pedometer.pedestrianStatusStream;
//
//       _isPedometerAvailable = true;
//
//       // Start listening if we're not already
//       if (!_isListening) {
//         _startListening(stepStream, statusStream);
//       }
//     } catch (e) {
//       _isPedometerAvailable = false;
//       onError('Step counter not available: ${e.toString()}');
//     }
//   }
//
//   // Start listening to pedometer streams
//   void _startListening(Stream<StepCount> stepStream, Stream<PedestrianStatus> statusStream) {
//     _stepCountSubscription = stepStream.listen(
//       onStepCount,
//       onError: onStepCountError,
//     );
//
//     _pedestrianStatusSubscription = statusStream.listen(
//       onPedestrianStatusChanged,
//       onError: onPedestrianStatusError,
//     );
//
//     _isListening = true;
//   }
//
//   // Handle step count updates
//   void onStepCount(StepCount event) {
//     if (kDebugMode) {
//       print('Step count update: ${event.steps} at ${event.timeStamp}');
//     }
//     onStepCountUpdate(event.steps);
//   }
//
//   // Handle status updates
//   void onPedestrianStatusChanged(PedestrianStatus event) {
//     if (kDebugMode) {
//       print('Pedestrian status: ${event.status} at ${event.timeStamp}');
//     }
//     onStatusUpdate(event.status);
//   }
//
//   // Handle step count errors
//   void onStepCountError(error) {
//     onError('Step count error: ${error.toString()}');
//   }
//
//   // Handle status errors
//   void onPedestrianStatusError(error) {
//     onError('Status error: ${error.toString()}');
//   }
//
//   // Request permission (can be called from UI)
//   Future<void> requestPermission() async {
//     try {
//       final granted = await _checkPhysicalActivityPermission();
//       _permissionGranted = granted;
//       onPermissionUpdate(granted);
//
//       if (granted) {
//         await _checkPedometerAvailability();
//       } else {
//         onError('Physical activity permission denied. Please enable it in device settings to access step data from the past 24 hours.');
//       }
//     } catch (e) {
//       onError('Permission request failed: $e');
//     }
//   }
//
//   // Check current permission status
//   bool get isPermissionGranted => _permissionGranted;
//
//   // Check if pedometer is available
//   bool get isPedometerAvailable => _isPedometerAvailable;
//
//   // Check if service is listening
//   bool get isListening => _isListening;
//
//   // Method to get detailed permission status
//   Future<Map<String, bool>> getPermissionStatus() async {
//     Map<String, bool> status = {};
//
//     if (Platform.isAndroid) {
//       status['activityRecognition'] = await Permission.activityRecognition.isGranted;
//       status['sensors'] = await Permission.sensors.isGranted;
//     } else if (Platform.isIOS) {
//       status['sensors'] = await Permission.sensors.isGranted;
//     }
//
//     return status;
//   }
//
//   // Dispose of resources
//   void dispose() {
//     _stepCountSubscription?.cancel();
//     _pedestrianStatusSubscription?.cancel();
//     _isListening = false;
//   }
// }
