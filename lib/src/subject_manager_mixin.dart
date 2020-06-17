import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';

///
/// 用来管理多个Subject
mixin SubjectManagerMixin on BaseBloc {
  final _subjectsMap = <String, BehaviorSubject>{};
  final _subjectsList = <BehaviorSubject>[];

  @visibleForTesting
  void setAllSubjectValueToNull() {
    _subjectsMap.values.forEach((it) => it.add(null));
    _subjectsList.forEach((it) => it.add(null));
  }

  /// 根据名称获得subject（名称必须保证唯一），若没有则创建它，以[seed]为初始值，创建的subject会自动close，
  /// 当[seed]值为null时，会调用[seedProvider]获取默认初始值，若[seedProvider]为null，则初始值为null。
  @protected
  @visibleForTesting
  BehaviorSubject<R> getSubjectByName<R>(
    String subjectName, {
    R seed,
    dynamic seedProvider(Type type) = _getInitValue,
  }) {
    assert(subjectName != null && subjectName.isNotEmpty);
    var result = _subjectsMap[subjectName];
    if (result == null) {
      result = _newSubject<R>(seed: seed, seedProvider: seedProvider);
      _subjectsMap[subjectName] = result;
      addDisposeListener(result.close);
    }
    return result;
  }

  static dynamic _getInitValue(Type R) {
    dynamic initValue;
    switch (R) {
      case String:
        initValue = '';
        break;
      case int:
        initValue = 0;
        break;
      case double:
        initValue = 0.0;
        break;
      case bool:
        initValue = false;
        break;
      case DateTime:
        initValue = DateTime.now();
        break;
      default:
        initValue = null;
        break;
    }
    return initValue;
  }

  BehaviorSubject<R> _newSubject<R>({
    R seed,
    dynamic seedProvider(Type type) = _getInitValue,
  }) {
    ///seed会作为默认值，有个缺陷：streamBuilder可能会被相同的初始值触发两次build
    return BehaviorSubject<R>.seeded(
        seed != null ? seed : (seedProvider == null ? null : seedProvider(R)));
  }

  ///以[seed]为初始值创建subject，会自动close
  ///当[seed]值为null时，会调用[seedProvider]获取默认初始值，若[seedProvider]为null，则初始值为null。
  @protected
  @visibleForTesting
  BehaviorSubject<R> createSubject<R>({
    R seed,
    dynamic seedProvider(Type type) = _getInitValue,
  }) {
    final result = _newSubject<R>(
      seed: seed,
      seedProvider: seedProvider,
    );
    _subjectsList.add(result);
    addDisposeListener(result.close);
    return result;
  }
}
