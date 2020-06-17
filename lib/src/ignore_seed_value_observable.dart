import 'dart:async';

import 'package:rxdart/rxdart.dart';

///为了解决seedValue会触发监听的问题，但又想第一次能取到值
class IgnoreSeedValueObservable<T> extends ConnectableStream<T>
    implements ValueStream<T> {
  final Stream<T> _source;
  final _IgnoreSeedBehaviorSubject<T> _subject;

  IgnoreSeedValueObservable._(this._source, this._subject) : super(_subject);

  ///设置seedValue后不触发监听
  factory IgnoreSeedValueObservable.seeded(
    Stream<T> source,
    T seedValue,
  ) =>
      IgnoreSeedValueObservable<T>._(
          source, _IgnoreSeedBehaviorSubject.seeded(seedValue));

  @override
  ValueStream<T> autoConnect({
    void Function(StreamSubscription<T> subscription) connection,
  }) {
    _subject.onListen = () {
      if (connection != null) {
        connection(connect());
      } else {
        connect();
      }
    };
    return _subject;
  }

  @override
  StreamSubscription<T> connect() {
    return ConnectableStreamSubscription<T>(
      _source.listen(_subject.add, onError: _subject.addError),
      _subject,
    );
  }

  @override
  ValueStream<T> refCount() {
    ConnectableStreamSubscription<T> subscription;

    _subject.onListen = () {
      subscription = ConnectableStreamSubscription<T>(
        _source.listen(_subject.add, onError: _subject.addError),
        _subject,
      );
    };

    _subject.onCancel = () {
      subscription.cancel();
    };

    return _subject;
  }

  @override
  T get value => _subject.value;

  @override
  bool get hasValue => _subject.hasValue;
}

class _IgnoreSeedBehaviorSubject<T> extends Subject<T>
    implements ValueStream<T> {
  _Wrapper<T> _wrapper;

  _IgnoreSeedBehaviorSubject._(
    StreamController<T> controller,
    Stream<T> observable,
    this._wrapper,
  ) : super(controller, observable);

  factory _IgnoreSeedBehaviorSubject.seeded(
    T seedValue, {
    void onListen(),
    void onCancel(),
    bool sync = false,
  }) {
    // ignore: close_sinks
    final controller = StreamController<T>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
    );

    final wrapper = _Wrapper<T>.seeded(seedValue);

    return _IgnoreSeedBehaviorSubject<T>._(
        controller, controller.stream, wrapper);
  }

  @override
  void onAdd(T event) => _wrapper.setValue(event);

  @override
  void onAddError(Object error, [StackTrace stackTrace]) =>
      _wrapper.setError(error, stackTrace);

  @override
  ValueStream<T> get stream => this;

  @override
  bool get hasValue => _wrapper.latestIsValue;

  /// Get the latest value emitted by the Subject
  @override
  T get value => _wrapper.latestValue;

  /// Set and emit the new value
  set value(T newValue) => add(newValue);
}

class _Wrapper<T> {
  T latestValue;
  Object latestError;
  StackTrace latestStackTrace;

  bool latestIsValue = false, latestIsError = false;

  /// Non-seeded constructor
  _Wrapper();

  _Wrapper.seeded(this.latestValue) : latestIsValue = true;

  void setValue(T event) {
    latestIsValue = true;
    latestIsError = false;

    latestValue = event;

    latestError = null;
    latestStackTrace = null;
  }

  void setError(Object error, [StackTrace stackTrace]) {
    latestIsValue = false;
    latestIsError = true;

    latestValue = null;

    latestError = error;
    latestStackTrace = stackTrace;
  }
}
