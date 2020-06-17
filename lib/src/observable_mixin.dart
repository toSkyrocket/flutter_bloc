import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';

///检查输出及安全更新subject
mixin ObservableMixin on BaseBloc {
  @protected
  static bool _checkInput(dynamic item, [int index]) {
    if (item == null) return false;
    if (item is String) {
      return item.isNotEmpty;
    } else if (item is bool) {
      return item;
    } else if (item is Iterable) {
      return item.isNotEmpty;
    }
    return true;
  }

  ///创建Observable用来监听[streams]的所有值是否不为空，会自动close，若有值为空则返回false，若所有值都不为空则返回true.
  ///检查值是否为空通过调用[validator]判断。
  ///若要根据[streams]的某些值决定验证哪些stream，可指定[indexesToValidate]参数，
  ///[indexesToValidate]：根据[streams]所有项的值返回要验证的stream的位置集合。
  ///在bloc dispose时会自动取消订阅，无须手动取消
  ///
  /// ### Example
  ///
  /// observableCheckInput([
  ///        fooSubject,
  ///        barSubject,
  ///      ], indexesToValidate: (values) {
  ///        ///根据streams当前的某些值决定要验证是否为空的stream
  ///        if (values[0] =="") {
  ///          return [0]; ///验证第0个stream，即fooSubject是否为空
  ///        } else {
  ///          return [0，1]; ///验证第0个和第1个stream，即fooSubject和barSubject是否为空
  ///        }
  ///      })
  ///
  @protected
  @visibleForTesting
  ValueStream<bool> observableCheckInput(Iterable<Stream> streams,
      {List<int> Function(List) indexesToValidate,
      bool Function(dynamic, int) validator = _checkInput}) {
    var valid = false;
    assert(validator != null);
    final bool Function(List) combiner = indexesToValidate == null
        ? (values) {
            for (var i = 0; i < values.length; ++i) {
              if (!validator(values[i], i)) {
                return false;
              }
            }
            return true;
          }
        : (values) {
            final indexes = indexesToValidate(values);
            for (var index in indexes) {
              assert(index >= 0 && index < values.length);
              if (!validator(values[index], index)) {
                return false;
              }
            }
            return true;
          };
    var observable = Rx.combineLatest(streams, combiner).where((newValid) {
      bool success = newValid != valid;
      valid = newValid;
      return success;
    });

    final result = IgnoreSeedValueObservable<bool>.seeded(observable, false);

    return result.autoConnect(connection: (subscription) {
      ///dispose时取消订阅
      addDisposeListener(subscription.cancel);
    });
  }

  ///合并stream并监听值变化，仅当值与上次的值不同时才会触发监听。
  ///在bloc dispose时会自动取消订阅，无须手动取消
  ValueStream<R> combineObservable<R>(
    Iterable<Stream> streams,
    R Function(List) combiner, {
    R seedValue,
  }) {
    R oldValue = seedValue;
    var observable = Rx.combineLatest(streams, combiner).where((newValue) {
      bool success = newValue != oldValue;
      oldValue = newValue;
      return success;
    });

    final result = IgnoreSeedValueObservable<R>.seeded(observable, seedValue);

    return result.autoConnect(connection: (subscription) {
      ///dispose时取消订阅
      addDisposeListener(subscription.cancel);
    });
  }
}
