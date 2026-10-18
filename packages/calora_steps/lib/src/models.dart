enum StepIssue {
  disabled,
  activityPermission,
  noSource,
  serviceStopped;

  static StepIssue? fromWire(Object? value) => switch (value) {
    'disabled' => StepIssue.disabled,
    'activity_permission' => StepIssue.activityPermission,
    'no_source' => StepIssue.noSource,
    'service_stopped' => StepIssue.serviceStopped,
    _ => null,
  };
}

enum StepSourceKind {
  sensor,
  healthConnect,
  recording;

  static StepSourceKind fromWire(Object? value) => switch (value) {
    'health_connect' => StepSourceKind.healthConnect,
    'recording' => StepSourceKind.recording,
    _ => StepSourceKind.sensor,
  };
}

enum HealthConnectAvailability {
  available,
  updateRequired,
  notInstalled,
  unsupported;

  static HealthConnectAvailability fromWire(Object? value) => switch (value) {
    'available' => HealthConnectAvailability.available,
    'update_required' => HealthConnectAvailability.updateRequired,
    'not_installed' => HealthConnectAvailability.notInstalled,
    _ => HealthConnectAvailability.unsupported,
  };

  bool get canBeInstalled =>
      this == HealthConnectAvailability.notInstalled ||
      this == HealthConnectAvailability.updateRequired;
}

enum HealthConnectConnectResult {
  connected,
  denied,
  storeOpened,
  unsupported,
  unavailable;

  static HealthConnectConnectResult fromWire(Object? value) => switch (value) {
    'connected' => HealthConnectConnectResult.connected,
    'denied' => HealthConnectConnectResult.denied,
    'store_opened' => HealthConnectConnectResult.storeOpened,
    'unsupported' => HealthConnectConnectResult.unsupported,
    _ => HealthConnectConnectResult.unavailable,
  };
}

class StepSnapshot {
  const StepSnapshot({
    required this.day,
    required this.steps,
    this.sensorSteps = 0,
    this.pendingSteps = 0,
    this.healthConnectSteps,
    this.recordingSteps,
    this.source = StepSourceKind.sensor,
    this.enabled = false,
    this.serviceRunning = false,
    this.sensorListening = false,
    this.issue,
    this.updatedAt,
  });

  factory StepSnapshot.fromMap(Map<Object?, Object?> map) {
    final updatedAt = _int(map['updatedAt']);
    return StepSnapshot(
      day: map['day'] as String?,
      steps: _int(map['steps']),
      sensorSteps: _int(map['sensorSteps']),
      pendingSteps: _int(map['pendingSteps']),
      healthConnectSteps: _intOrNull(map['healthConnectSteps']),
      recordingSteps: _intOrNull(map['recordingSteps']),
      source: StepSourceKind.fromWire(map['source']),
      enabled: map['enabled'] == true,
      serviceRunning: map['serviceRunning'] == true,
      sensorListening: map['sensorListening'] == true,
      issue: StepIssue.fromWire(map['issue']),
      updatedAt: updatedAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(updatedAt)
          : null,
    );
  }

  static const empty = StepSnapshot(day: null, steps: 0);

  final String? day;
  final int steps;
  final int sensorSteps;
  final int pendingSteps;
  final int? healthConnectSteps;
  final int? recordingSteps;
  final StepSourceKind source;
  final bool enabled;
  final bool serviceRunning;
  final bool sensorListening;
  final StepIssue? issue;
  final DateTime? updatedAt;

  bool get isCounting => issue == null;
}

class TrackerAppStatus {
  const TrackerAppStatus({
    required this.id,
    required this.name,
    required this.packageName,
    required this.syncing,
  });

  factory TrackerAppStatus.fromMap(Map<Object?, Object?> map) =>
      TrackerAppStatus(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        packageName: map['package'] as String? ?? '',
        syncing: map['syncing'] == true,
      );

  final String id;
  final String name;
  final String packageName;
  final bool syncing;
}

class StepTrackingStatus {
  const StepTrackingStatus({
    this.activityRecognition = false,
    this.notifications = false,
    this.batteryUnrestricted = false,
    this.autoStartScreen = false,
    this.sensorAvailable = false,
    this.recordingAvailable = false,
    this.healthConnect = HealthConnectAvailability.unsupported,
    this.healthConnectConnected = false,
    this.healthConnectBackgroundAvailable = false,
    this.healthConnectBackgroundGranted = false,
    this.phoneStepsInHealthConnect = false,
    this.trackers = const [],
    this.enabled = false,
    this.serviceRunning = false,
    this.manufacturer = '',
    this.sdkInt = 0,
  });

  factory StepTrackingStatus.fromMap(Map<Object?, Object?> map) =>
      StepTrackingStatus(
        activityRecognition: map['activityRecognition'] == true,
        notifications: map['notifications'] == true,
        batteryUnrestricted: map['batteryUnrestricted'] == true,
        autoStartScreen: map['autoStartScreen'] == true,
        sensorAvailable: map['sensorAvailable'] == true,
        recordingAvailable: map['recordingAvailable'] == true,
        healthConnect: HealthConnectAvailability.fromWire(map['healthConnect']),
        healthConnectConnected: map['healthConnectConnected'] == true,
        healthConnectBackgroundAvailable:
            map['healthConnectBackgroundAvailable'] == true,
        healthConnectBackgroundGranted:
            map['healthConnectBackgroundGranted'] == true,
        phoneStepsInHealthConnect: map['phoneStepsInHealthConnect'] == true,
        trackers: [
          for (final item in (map['trackers'] as List<Object?>? ?? const []))
            if (item is Map) TrackerAppStatus.fromMap(item),
        ],
        enabled: map['enabled'] == true,
        serviceRunning: map['serviceRunning'] == true,
        manufacturer: map['manufacturer'] as String? ?? '',
        sdkInt: _int(map['sdkInt']),
      );

  static const unknown = StepTrackingStatus();

  final bool activityRecognition;
  final bool notifications;
  final bool batteryUnrestricted;
  final bool autoStartScreen;
  final bool sensorAvailable;
  final bool recordingAvailable;
  final HealthConnectAvailability healthConnect;
  final bool healthConnectConnected;
  final bool healthConnectBackgroundAvailable;
  final bool healthConnectBackgroundGranted;
  final bool phoneStepsInHealthConnect;
  final List<TrackerAppStatus> trackers;
  final bool enabled;
  final bool serviceRunning;
  final String manufacturer;
  final int sdkInt;

  bool get canCountOnPhone => activityRecognition && sensorAvailable;

  bool get hasAnySource =>
      canCountOnPhone || healthConnectConnected || recordingAvailable;

  List<TrackerAppStatus> get trackersNotSyncing =>
      trackers.where((t) => !t.syncing).toList();
}

class StepNotificationLabels {
  const StepNotificationLabels({
    required this.channel,
    required this.title,
    required this.goal,
    required this.kcal,
    required this.goalReached,
    required this.locale,
  });

  final String channel;
  final String title;
  final String goal;
  final String kcal;
  final String goalReached;
  final String locale;

  Map<String, Object?> toMap() => {
    'channel': channel,
    'title': title,
    'goal': goal,
    'kcal': kcal,
    'goalReached': goalReached,
    'locale': locale,
  };
}

int _int(Object? value) => value is num ? value.toInt() : 0;

int? _intOrNull(Object? value) => value is num ? value.toInt() : null;
