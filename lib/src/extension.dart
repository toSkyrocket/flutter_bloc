import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

extension ValueStreamExtension<T> on ValueStream<T> {
  StreamBuilder<T> build(AsyncWidgetBuilder<T> builder, [Key key]) {
    return StreamBuilder<T>(
      key: key,
      builder: builder,
      initialData: this.value,
      stream: this,
    );
  }
}
