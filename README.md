# bloc

Flutter BLOC模式实现，使用了Provider库实现

## 使用方法

Bloc子类主要是放置一些业务逻辑，可配合StreamBuilder和RxDart库监听数据变化。下面一个例子可通过点击FlatButton按钮改变name的值并同步改变显示的name：

```dart
class FooBloc extends SubjectBloc {
  BehaviorSubject<String> get nameSubject => getSubjectByName("name");

  void updateName(String name) {
    nameSubject.value = name;
  }
}

class FooPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (_) => FooBloc(),
        builder: (context, fooBloc,_) {
          ///...还可通过BlocProvider.of<FooBloc>(context)获取最近一层的FooBloc
          return Column(
            children: <Widget>[
              StreamBuilder<String>(
                stream: fooBloc.nameSubject,
                builder: (context, snapshot) {
                  return Text(snapshot.data);
                },
              ),
              FlatButton(
                onPressed: () {
                  fooBloc.updateName("newName");
                },
                child: Text("改变name"),
              )
            ],
          );
        });
  }
}

```

1. 对于页面只有单个BLOC对象的情况，创建SubjectBloc子类，并使用BlocProvider即可，如：

```dart
class BarBloc extends SubjectBloc{
  ///...
}
class FooPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_)=>BarBloc(),builder: (context,barBloc,_){
      ///...还可通过BlocProvider.of<BarBloc>(context)获取最近一层的BarBloc
      ///或者context.bloc<BarBloc>()
    });
  }

}

```
2. 对于页面有多个不同类型的BLOC对象的情况，可通过MultiProvider方法创建Widget即可，如：
```dart
class FooPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      BlocProvider(create:(_)=>FooBloc()),
      BlocProvider(create:(_)=>BarBloc()),
    ],child: Consumer<FooBloc>(builder:(context,fooBloc,_){
      ///还可通过 BlocProvider.of<FooBloc>(context)获取
      ///或者context.bloc<BarBloc>()

    }));
  }

}

```

## 扩展方法

1. 对于BuildContext对象，可使用如下方式获取Bloc

```dart
context.bloc<FooBloc>()
```

2. 对于ValueStream对象，可使用如下方式创建StreamBuilder
```dart
valueStream.build((context,snapshot){
  ///....
});
```

## Getting Started

This project is a starting point for a Dart
[package](https://flutter.dev/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
