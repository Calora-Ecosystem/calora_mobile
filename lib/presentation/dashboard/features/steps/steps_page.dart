import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' as AppSettings;

@RoutePage()
class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  String _status = '?';
  String _steps = '?';
  bool _permissionGranted = false;
  bool _isPedometerAvailable = false;
  String _errorMessage = '';
  bool _isLoading = true;

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initPlatformState();
    });
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Counter'),
        actions: [
          if (!_permissionGranted)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.orange),
              onPressed: _requestPermission,
              tooltip: 'Permission required',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _retryInitialization,
            tooltip: 'Retry',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_errorMessage.isNotEmpty) _buildErrorCard(),

            if (!_isPedometerAvailable) _buildNotAvailableCard(),

            if (!_permissionGranted) _buildPermissionButton(),

            if (_isPedometerAvailable && _permissionGranted)
              _buildStepCounterUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAvailableCard() {
    return Card(
      color: Colors.orange[50],
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.device_unknown, color: Colors.orange, size: 40),
            SizedBox(height: 8),
            Text(
              'Step counting not available on this device',
              style: TextStyle(color: Colors.orange, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionButton() {
    return Column(
      children: [
        const Icon(Icons.scale, size: 60, color: Colors.blue),
        const SizedBox(height: 16),
        const Text(
          'Step counting requires activity recognition permission',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _requestPermission,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Grant Permission'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _openAppSettings,
          child: const Text('Open App Settings'),
        ),
      ],
    );
  }

  Widget _buildStepCounterUI() {
    return Column(
      children: [
        const Text(
          'Steps Taken',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _steps,
          style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
        ),

        const Divider(height: 40, thickness: 1),

        const Text(
          'Status',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Icon(_getStatusIcon(), size: 80, color: _getStatusColor()),
        const SizedBox(height: 8),
        Text(
          _status.toUpperCase(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case 'walking':
        return Icons.directions_walk;
      case 'stopped':
        return Icons.accessibility_new;
      case 'running':
        return Icons.directions_run;
      default:
        return Icons.error;
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'walking':
        return Colors.green;
      case 'stopped':
        return Colors.blue;
      case 'running':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Future<void> _requestPermission() async {
    try {
      setState(() => _isLoading = true);

      final granted = await _checkActivityRecognitionPermission();

      setState(() {
        _permissionGranted = granted;
        _isLoading = false;
        if (granted) {
          _errorMessage = '';
          _checkPedometerAvailability();
        } else {
          _errorMessage =
              'Permission denied. You can enable it in app settings.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Permission request failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      setState(() {
        _errorMessage = 'Cannot open settings: $e';
      });
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await initPlatformState();
  }

  Future<bool> _checkActivityRecognitionPermission() async {
    try {
      if (Platform.isAndroid) {
        // Check and request ACTIVITY_RECOGNITION permission
        var status = await Permission.activityRecognition.status;
        if (!status.isGranted) {
          status = await Permission.activityRecognition.request();
        }
        return status.isGranted;
      } else if (Platform.isIOS) {
        // For iOS, use motion & fitness permission
        var status = await Permission.sensors.status;
        if (!status.isGranted) {
          status = await Permission.sensors.request();
        }
        return status.isGranted;
      }
      return false;
    } catch (e) {
      log("Permission check error: $e");
      return false;
    }
  }

  Future<void> _checkPedometerAvailability() async {
    try {
      // Cancel existing subscriptions
      await _stepCountSubscription?.cancel();
      await _pedestrianStatusSubscription?.cancel();

      // Try to access pedometer streams
      final stepStream = await Pedometer.stepCountStream;
      final statusStream = await Pedometer.pedestrianStatusStream;

      setState(() {
        _isPedometerAvailable = true;
      });

      // Create new subscriptions
      _stepCountSubscription = stepStream.listen(
        onStepCount,
        onError: onStepCountError,
      );
      _pedestrianStatusSubscription = statusStream.listen(
        onPedestrianStatusChanged,
        onError: onPedestrianStatusError,
      );
    } catch (e) {
      setState(() {
        _isPedometerAvailable = false;
        _errorMessage = 'Step counter not available: ${e.toString()}';
      });
      log("Pedometer availability check failed: $e");
    }
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    setState(() {
      _errorMessage = 'Status error: ${error.toString()}';
    });
  }

  void onStepCountError(error) {
    setState(() {
      _errorMessage = 'Step count error: ${error.toString()}';
    });
  }

  Future<void> initPlatformState() async {
    try {
      final granted = await _checkActivityRecognitionPermission();

      setState(() {
        _permissionGranted = granted;
      });

      if (granted) {
        await _checkPedometerAvailability();
      } else {
        setState(() {
          _errorMessage = 'Permission not granted';
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}
