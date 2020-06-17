import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

class _TestBloc extends SubjectBloc {
  BehaviorSubject<bool> get checkedSubject => getSubjectByName('checked');
}

class _NotFoundBloc extends SubjectBloc {}

class _ValueBloc extends SubjectBloc {
  final String name;

  _ValueBloc(this.name);
}

void main() {
  group('bloc', () {
    test('dispose listener', () async {
      final bloc = _TestBloc();
      var called = false;
      final VoidCallback listener = () {
        called = true;
      };
      bloc.addDisposeListener(listener);
      await bloc.dispose();
      expect(called, true);

      called = false;
      bloc.removeDisposeListener(listener);
      await bloc.dispose();
      expect(called, false);

      called = false;

      final asyncListener = () async {
        await Future.delayed(Duration(seconds: 1));
        called = true;
      };

      bloc.addDisposeListener(asyncListener);
      await bloc.dispose();
      expect(called, true);

      final VoidCallback addListener = () {
        bloc.addDisposeListener(() {});
      };
      bloc.addDisposeListener(addListener);
      await expectLater(() => bloc.dispose(), throwsAssertionError);

      final VoidCallback removeListener = () {
        bloc.addDisposeListener(() {});
      };

      final bloc2 = _TestBloc();
      bloc2.addDisposeListener(removeListener);
      await expectLater(() => bloc.dispose(), throwsAssertionError);
    });

    test('dispose guard', () async {
      final bloc = _TestBloc();

      expect(() => bloc.addDisposeGuard(null), throwsAssertionError);
      expect(() => bloc.removeDisposeGuard(null), throwsAssertionError);

      var permit = false;

      final DisposeGuard guard1 = () {
        return Future.delayed(Duration(microseconds: 100), () {
          return permit;
        });
      };

      final DisposeGuard guard2 = () {
        return permit;
      };

      bloc.addDisposeGuard(guard1);
      bloc.addDisposeGuard(guard2);
      await bloc.dispose();
      expect(bloc.disposed, false);

      permit = true;
      await bloc.dispose();
      expect(bloc.disposed, true);

      permit = false;
      bloc.removeDisposeGuard(guard1);
      bloc.removeDisposeGuard(guard2);
      await bloc.dispose();
      expect(bloc.disposed, true);

      final addListener = () {
        bloc.addDisposeGuard(() {
          return true;
        });
      };
      bloc.addDisposeListener(addListener);
      await expectLater(() => bloc.dispose(), throwsAssertionError);

      final bloc2 = _TestBloc();
      final removeListener = () {
        bloc.removeDisposeGuard(guard1);
      };
      bloc2.addDisposeListener(removeListener);
      await expectLater(() => bloc2.dispose(), throwsAssertionError);
    });

    test('createSubject', () async {
      final bloc = _TestBloc();
      // ignore: close_sinks
      final s1 = bloc.createSubject<double>();
      final s2 = bloc.createSubject<bool>(); // ignore: close_sinks
      final s3 = bloc.createSubject<DateTime>(); // ignore: close_sinks

      // ignore: close_sinks
      final s4 = bloc.getSubjectByName<bool>('kk');

      expect(() => bloc.getSubjectByName(''), throwsAssertionError);

      expect(s1.value, 0);
      expect(s2.value, false);
      expect(s3.value, isNotNull);
      expect(s4.value, false);

      bloc.setAllSubjectValueToNull();

      expect(s1.value, isNull);
      expect(s2.value, isNull);
      expect(s3.value, isNull);
      expect(s4.value, isNull);

      expect(bloc.getSubjectByName('kk').value, isNull);

      // ignore: close_sinks
      final s5 = bloc.createSubject<int>(seed: 4);
      expect(s5.value, 4);
      // ignore: close_sinks
      final s6 = bloc.createSubject<int>(seedProvider: (Type type) {
        switch (type) {
          case int:
            return 100;
        }
        return null;
      });
      expect(s6.value, 100);

      // ignore: close_sinks
      final s7 = bloc.createSubject<int>(seedProvider: null);
      expect(s7.value, isNull);
    });

    test('ignoreSeedObservable', () async {
      final subject = BehaviorSubject<String>();

      final ob = IgnoreSeedValueObservable.seeded(subject, '123');
      expect(ob.value, '123');

      expect(ob.hasValue, true);

      final stream = ob.refCount();
      final sub = stream.listen((_) {});
      await sub.cancel();
      await expectLater(ob, emitsDone);

      final s = ob.connect();
      await s.cancel();
      await expectLater(ob, emitsDone);

      subject.close();
    }, timeout: Timeout(Duration(seconds: 3)));

    test('subject close', () async {
      final bloc = _TestBloc();
      // ignore: close_sinks
      final sub1 = bloc.createSubject<int>(seed: 666);
      // ignore: close_sinks
      final sub2 = bloc.getSubjectByName<int>('sub2', seed: 888);

      await bloc.dispose();
      expect(sub1.isClosed, isTrue);
      expect(sub2.isClosed, isTrue);
    });

    test('combineObservable', () async {
      final bloc = _TestBloc();
      final sub1 = bloc.createSubject<int>(seed: 666);
      final ob =
          bloc.combineObservable([sub1], (list) => list[0], seedValue: 0);
      scheduleMicrotask(() {
        sub1.add(888);
        sub1.close();
      });
      //await expectLater(ob, emitsInOrder([666, 888]));
      final ss1 = ob.listen((_) {});
      final ss2 = ob.listen((_) {});
      await ss1.cancel();
      await expectLater((ob as Subject).isClosed, isFalse);
      await ss2.cancel();
      await expectLater((ob as Subject).isClosed, isFalse);

      await bloc.dispose();
      await expectLater((ob as Subject).isClosed, isTrue);
    }, timeout: Timeout(Duration(seconds: 3)));

    test('observableCheckInput', () async {
      final bloc = _TestBloc();
      // ignore: close_sinks
      final sub1 = bloc.createSubject<int>();
      // ignore: close_sinks
      final sub2 = bloc.createSubject<String>();

      // ignore: close_sinks
      final sub3 = bloc.createSubject<List<int>>(seed: [1, 2, 3]);

      expect(sub1.value, 0);

      final ob = bloc.observableCheckInput([sub1, sub2, sub3]);
      ob.listen((event) {});

      sub2.add("kkk");
      await expectLater(ob, emitsInOrder([true]));
      sub2.add("");
      await expectLater(ob, emitsInOrder([false]));

      sub1.add(0);
      final ob2 =
          bloc.observableCheckInput([sub1, sub2], indexesToValidate: (list) {
        if (list[0] == 0) {
          return [0];
        } else {
          return [0, 1];
        }
      });
      ob2.listen((event) {});
      await expectLater(ob2, emits(true));
      sub1.add(1);
      sub2.add("");
      await expectLater(ob2, emits(false));

      final ob3 = bloc.observableCheckInput([sub3]);

      ob3.listen((event) {});
      expect(ob3.value, isFalse);
      await expectLater(ob3, emitsInOrder([true]));

      sub3.add([]);
      await expectLater(ob3, emitsInOrder([false]));

      await bloc.dispose();
      await expectLater((ob as Subject).isClosed, isTrue);
      ob.listen((_) {});
    }, timeout: Timeout(Duration(seconds: 3)));
  });

  group('widget', () {
    var streamBuildCount = 0;
    testWidgets('dispose widget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiProvider(
          providers: [
            BlocProvider(
              create: (_) => _ValueBloc('parent'),
            ),
            BlocProvider(
              create: (_) => _TestBloc(),
            ),
          ],
          child: Scaffold(
            body: Container(
              child: Column(
                children: <Widget>[
                  BlocProvider(
                      create: (_) => _ValueBloc('child'),
                      builder: (context, bloc, _) {
                        return Text('a');
                      }),
                  Builder(builder: (context) {
                    return BlocProvider.value(
                      value: context.bloc<_ValueBloc>(),
                      child: Text('b'),
                    );
                  }),
                  Consumer<_ValueBloc>(
                    builder: (context, bloc, _) {
                      return Text('c');
                    },
                  ),
                  Builder(builder: (context) {
                    return BlocProvider.value(
                      value: context.bloc<_ValueBloc>(),
                      child: Consumer<_ValueBloc>(
                        builder: (context, bloc, _) {
                          return Text('d');
                        },
                      ),
                    );
                  }),
                  Consumer<_TestBloc>(
                    builder: (context, bloc, _) {
                      return bloc.checkedSubject.build(
                          /*stream: bloc.checkedSubject,
                          initialData: bloc.checkedSubject.value,
                          builder: */
                          (context, snapshot) {
                        streamBuildCount++;
                        return CheckboxListTile(
                          value: snapshot.data,
                          onChanged: bloc.checkedSubject.add,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text('e'),
                        );
                      });
                    },
                  ),
                  //BlocProvider.value(value: BlocProvider.of<_TestBloc>())
                ],
              ),
            ),
          ),
        ),
      ));

      expect(_firstText('a').bloc<_TestBloc>(), isNotNull);
      expect(_firstText('a').bloc<_ValueBloc>(), isNotNull);
      expect(_firstText('b').bloc<_TestBloc>(), isNotNull);

      expect(_firstText('b').bloc<_ValueBloc>().name, 'parent');

      expect(_firstText('a').bloc<_ValueBloc>().name, 'child');

      expect(_firstText('c').bloc<_ValueBloc>().name, 'parent');
      expect(_firstText('d').bloc<_ValueBloc>().name, 'parent');

      expect(_firstText('e').bloc<_TestBloc>().checkedSubject.value, isFalse);

      expect(streamBuildCount, 1);

      await tester.tap(find.text('e'));
      await tester.pump();

      expect(_firstText('e').bloc<_TestBloc>().checkedSubject.value, isTrue);
      await tester.pump();
      expect(streamBuildCount, 2);

      expect(() {
        _firstText('a').bloc<_NotFoundBloc>();
      }, throwsFlutterError);
    });
  });
}

Element _firstText(String text) {
  return find.text(text).evaluate().first;
}
