import 'package:flutter/widgets.dart';

/// Keeps streams/futures stable across rebuilds.
///
/// `StreamBuilder(stream: query.snapshots())` inside `build` creates a new
/// subscription every rebuild, which flashes a spinner and re-reads data.
/// Wrap it as `stream: memo(('name', arg1, arg2), () => query.snapshots())`
/// so the same object is reused until one of the key parts changes.
mixin MemoMixin<T extends StatefulWidget> on State<T> {
  final Map<Object?, Object?> _memo = {};

  R memo<R>(Object? key, R Function() create) {
    if (_memo.length > 500) _memo.clear(); // safety valve for churny keys
    return _memo.putIfAbsent(key, create) as R;
  }

  /// Drops cached values so the next build re-creates them (e.g. after a
  /// pull-to-refresh or a write that the cached future would not see).
  void clearMemo() => _memo.clear();
}
