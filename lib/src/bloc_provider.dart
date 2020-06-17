import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/bloc.dart';

/// 类似于[Provider]，但只能注入Bloc对象，对于多个Bloc可使用[MultiProvider]
class BlocProvider<T extends Bloc> extends InheritedProvider<T> {
  BlocProvider._({
    Key key,
    @required Create<T> create,
    Dispose<T> dispose,
    Widget child,
    bool lazy,
  }) : super(
            key: key,
            create: create,
            dispose: dispose,
            lazy: lazy,
            child: child);

  ///创建Widget并注入BLOC依赖，在子Widget可通过[of]方法获取BLOC，或者通过[Consumer]获取
  /// [create]用来创建bloc，还可在创建后进行一些初始化操作
  ///[lazy]表示是否在第一次使用bloc时才调用[create]方法创建bloc，还是在插入widget时就调用[create]，默认是true
  ///当[builder]不为null时会创建[Consumer]并将[child]传给[Consumer]，如果[builder]为null则直接使用child
  BlocProvider({
    Key key,
    @required Create<T> create,
    Widget Function(BuildContext context, T bloc, Widget child) builder,
    Widget child,
    bool lazy,
  }) : this._(
          key: key,
          create: create,
          dispose: (_, bloc) => bloc?.dispose(),
          lazy: lazy,
          child: builder != null
              ? Consumer<T>(
                  builder: builder,
                  child: child,
                )
              : child,
        );

  ///不能用来创建新的Bloc，只能使用现有的Bloc，通过这种方式创建的BlocProvider不会dispose bloc
  ///在子Widget可通过[of]方法获取BLOC，或者通过[Consumer]获取
  /// ```dart
  /// BlocProvider.value(
  ///   value: BlocProvider.of<BlocA>(context),
  ///   child: ScreenA(),
  /// );
  BlocProvider.value({
    Key key,
    @required T value,
    Widget child,
  }) : this._(key: key, create: (_) => value, child: child);

  /// Method that allows widgets to access a [bloc] instance as long as their
  /// `BuildContext` contains a [BlocProvider] instance.
  ///
  /// If we want to access an instance of `BlocA` which was provided higher up
  /// in the widget tree we can do so via:
  ///
  /// ```dart
  /// BlocProvider.of<BlocA>(context)
  /// ```
  static T of<T extends Bloc>(BuildContext context) {
    try {
      return Provider.of<T>(context, listen: false);
    } on ProviderNotFoundException catch (_) {
      throw FlutterError(
        """
        BlocProvider.of() called with a context that does not contain a Bloc of type $T.
        No ancestor could be found starting from the context that was passed to BlocProvider.of<$T>().

        This can happen if the context you used comes from a widget above the BlocProvider.

        The context used was: $context
        """,
      );
    }
  }
}

extension BlocProviderExtension on BuildContext {
  /// Performs a lookup using the `BuildContext` to obtain
  /// the nearest ancestor `Bloc` of type [B].
  ///
  /// Calling this method is equivalent to calling:
  ///
  /// ```dart
  /// BlocProvider.of<B>(context)
  /// ```
  B bloc<B extends Bloc>() => BlocProvider.of<B>(this);
}
