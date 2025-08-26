import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_async_result/flutter_async_result.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("AsyncResult States", () {
    test("Equality and hashCode", () {
      const ok1 = AsyncResult<String, Exception>.ok("data");
      const ok2 = AsyncResult<String, Exception>.ok("data");
      final error1 = AsyncResult<String, Exception>.error(Exception("e"));
      final error2 = AsyncResult<String, Exception>.error(Exception("e"));
      const loading1 = AsyncResult<String, Exception>.loading();
      const loading2 = AsyncResult<String, Exception>.loading();
      const empty1 = AsyncResult<String, Exception>.empty();
      const empty2 = AsyncResult<String, Exception>.empty();
      const loadingMore1 = AsyncResult<String, Exception>.loadingMore("data");
      const loadingMore2 = AsyncResult<String, Exception>.loadingMore("data");

      expect(ok1, equals(ok2));
      expect(ok1.hashCode, equals(ok2.hashCode));

      expect(error1, isNot(equals(error2))); // Exceptions with same message are not equal

      expect(loading1, equals(loading2));
      expect(loading1.hashCode, equals(loading2.hashCode));

      expect(empty1, equals(empty2));
      expect(empty1.hashCode, equals(empty2.hashCode));
      
      expect(loadingMore1, equals(loadingMore2));
      expect(loadingMore1.hashCode, equals(loadingMore2.hashCode));
    });
  });

  group("AsyncResultNotifier", () {
    late AsyncResultNotifier<String, Exception> notifier;

    setUp(() {
      notifier = AsyncResultNotifier.from(
        const AsyncResult.empty(),
        onError: (e) => e is Exception ? e : Exception(e.toString()),
      );
    });

    test("Initial state is correct", () {
      expect(notifier.value, isA<Empty>());
    });

    test("getStateValue extracts value correctly", () {
      notifier.value = const AsyncResult.ok("data");
      expect(notifier.getStateValue(), "data");

      notifier.value = AsyncResult.error(Exception("e"), value: "stale");
      expect(notifier.getStateValue(), "stale");

      notifier.value = const AsyncResult.loading(value: "stale");
      expect(notifier.getStateValue(), "stale");
      
      notifier.value = const AsyncResult.loadingMore("stale");
      expect(notifier.getStateValue(), "stale");

      notifier.value = const AsyncResult.empty();
      expect(notifier.getStateValue(), isNull);
    });

    test("refresh transitions Loading -> Ok on success", () async {
      final future = Future.value("success");

      // We need to listen to the notifier to check the states
      final states = <AsyncResult<String, Exception>>[];
      notifier.addListener(() {
        states.add(notifier.value);
      });

      await notifier.refresh(future);

      expect(states.length, 2);
      expect(states[0], isA<Loading>());
      expect(states[1], isA<Ok>().having((ok) => ok.value, "value", "success"));
    });

    test("refresh transitions Loading -> Error on failure", () async {
      final exception = Exception("failure");
      final future = Future<String>.error(exception);

      final states = <AsyncResult<String, Exception>>[];
      notifier.addListener(() {
        states.add(notifier.value);
      });

      await notifier.refresh(future);

      expect(states.length, 2);
      expect(states[0], isA<Loading>());
      expect(states[1], isA<Error>().having((e) => e.error, "error", exception));
    });

    test("listen callback provides new and old values", () async {
      AsyncResult<String, Exception>? oldState;
      AsyncResult<String, Exception>? newState;

      notifier.listen((newVal, [oldVal]) {
        newState = newVal;
        oldState = oldVal;
      });

      notifier.value = const AsyncResult.loading();
      
      expect(oldState, isA<Empty>());
      expect(newState, isA<Loading>());
      
      notifier.value = const AsyncResult.ok("data");
      
      expect(oldState, isA<Loading>());
      expect(newState, isA<Ok>());
    });

    testWidgets("watch method rebuilds widget on state change", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: notifier.watch((context, result) {
              return Text(result.runtimeType.toString());
            }),
          ),
        ),
      );

      expect(find.text("Empty<String, Exception>"), findsOneWidget);

      notifier.value = const AsyncResult.loading();
      await tester.pump();

      expect(find.text("Loading<String, Exception>"), findsOneWidget);

      notifier.value = const AsyncResult.ok("data");
      await tester.pump();

      expect(find.text("Ok<String, Exception>"), findsOneWidget);
    });
    
    test("stream helper yields correct states", () async {
      final controller = StreamController<String>();
      final stream = notifier.stream(controller.stream);
      
      expect(
        stream,
        emitsInOrder([
          isA<Loading>(),
          isA<Ok>().having((ok) => ok.value, "value", "one"),
          isA<Ok>().having((ok) => ok.value, "value", "two"),
          isA<Error>(),
        ]),
      );
      
      controller.add("one");
      await Future.delayed(Duration.zero);
      controller.add("two");
      await Future.delayed(Duration.zero);
      controller.addError(Exception("stream error"));
      await controller.close();
    });
  });
}

