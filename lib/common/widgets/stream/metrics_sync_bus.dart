import 'dart:async';
import 'dart:developer';

import 'package:injectable/injectable.dart';

@lazySingleton
class MetricsSyncService {
  final _controller = StreamController<int>.broadcast();

  Stream<int> get stream => _controller.stream;

  void notifyUpdated(int steps) {
    if (_controller.isClosed) return;
    _controller.add(steps);
    log('📣 MetricsSyncService notifyUpdated steps=$steps');
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
