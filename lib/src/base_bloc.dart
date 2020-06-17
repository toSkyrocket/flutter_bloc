import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/src/bloc.dart';

typedef DisposeGuard = FutureOr<bool> Function();

class BaseBloc implements Bloc {
  var _disposed = false;

  var _debugLocked = false;

  final _disposeListeners = Set<dynamic Function()>();

  ///添加dispose回调
  void addDisposeListener(listener()) {
    assert(!_debugLocked, 'dispose过程中不能添加');
    assert(listener != this.dispose, '不能添加自身的dispose');
    _disposeListeners.add(listener);
  }

  ///移除dispose回调
  void removeDisposeListener(listener()) {
    assert(!_debugLocked, 'dispose过程中不能移除');
    assert(!_debugLocked);
    _disposeListeners.remove(listener);
  }

  @protected
  @visibleForTesting
  bool get disposed => _disposed;

  Set<DisposeGuard> _disposeGuards;

  ///添加dispose守卫，当所有守卫返回true时才能dispose
  @protected
  @visibleForTesting
  void addDisposeGuard(DisposeGuard guard) {
    assert(!_debugLocked, 'dispose过程中不能添加');
    assert(guard != null);
    if (_disposeGuards == null) {
      _disposeGuards = <DisposeGuard>{};
    }
    _disposeGuards.add(guard);
  }

  ///移除dispose守卫
  @protected
  @visibleForTesting
  void removeDisposeGuard(DisposeGuard guard) {
    assert(!_debugLocked, 'dispose过程中不能移除');
    assert(guard != null);
    _disposeGuards?.remove(guard);
  }

  ///当所有[DisposeGuard]返回true时才会dispose
  @override
  Future dispose() async {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    if (_disposeGuards != null) {
      for (var guard in _disposeGuards) {
        final success = await guard();
        if (!success) {
          assert(() {
            _debugLocked = false;
            return true;
          }());
          return;
        }
      }
    }
    _disposed = true;

    final futures = <Future>[];
    _disposeListeners.forEach((it) {
      final result = it();
      if (result is Future) {
        futures.add(result);
      }
    });
    await Future.wait(futures);
    _disposeListeners.clear();
    _disposeGuards?.clear();
    assert(() {
      _debugLocked = false;
      return true;
    }());
  }
}
