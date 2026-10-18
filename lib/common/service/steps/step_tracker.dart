enum StepSource { health, pedometer, none }

sealed class StepCounterEvent {
  const StepCounterEvent();
}

class HealthDataNotSyncing extends StepCounterEvent {
  final String detectedApp;

  const HealthDataNotSyncing(this.detectedApp);
}

abstract interface class StepTracker {
  Stream<int> get stream;

  int get currentSteps;

  StepSource get source;

  Stream<StepCounterEvent> get events;

  Future<void> start();

  Future<void> stop();

  Future<void> refresh();

  Future<void> retryHealth();

  Future<void> forcePedometer();

  Future<void> dispose();
}
