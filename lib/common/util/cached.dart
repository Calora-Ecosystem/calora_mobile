import 'dart:async';

import 'package:calora/common/base/base_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:logger/logger.dart';

class Cached<T> {
  final BaseStore<T?> store;
  final Future<T> Function() fetch;

  final FutureOr Function(dynamic value)? map;

  FutureOr _map(dynamic value) => map == null ? value : map!(value);

  Cached({required this.store, required this.fetch, this.map});

  Future<T> get network async {
    final fetched = await fetch();
    await store.set(fetched);
    return await _map(fetched) as T;
  }

  Future<T?> get cache => store().then((e) async => await _map(e) as T?);

  Stream<T> get cacheAndNetwork async* {
    try {
      final cached = await cache;
      if (cached != null) yield cached;
    } catch (e, st) {
      getIt<Logger>().e(e.toString(), stackTrace: st);
    }
    yield await network;
  }

  Future<T> get cacheOrNetwork async {
    try {
      final cached = await cache;
      if (cached != null) return cached;
    } catch (e, st) {
      getIt<Logger>().e(e.toString(), stackTrace: st);
    }
    return network;
  }

  Stream<T?> use({
    bool cache = true,
    bool and = true,
    bool network = true,
    bool watch = false,
    bool nullable = false,
    Stream<void>? refresh,
  }) async* {
    T? cached;
    if (cache) {
      try {
        cached = await this.cache;
        if (nullable || cached != null) yield cached;
      } catch (e, st) {
        getIt<Logger>().e(e.toString(), stackTrace: st);
      }
    }

    if (network && ((!cache || and) || cached == null)) {
      yield await this.network;
    }

    if (watch) {
      yield* store
          .watch()
          .where((e) => nullable || e != null)
          .asyncMap((e) async => await _map(e) as T?);
      if (refresh != null) {
        yield* refresh.asyncMap((_) => this.network);
      }
    }
  }
}
