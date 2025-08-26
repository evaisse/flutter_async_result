import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_async_result/flutter_async_result.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("AsyncResult States", () {
    test("Equality and hashCode", () {
      const ok1 = AsyncResult<String, Exception>.ok("data");
      const ok2 = AsyncResult<String, Exception>.ok("data");
      const ok3 = AsyncResult<String, Exception>.ok("different data");
      final error1 = AsyncResult<String, Exception>.error(Exception("e"));
      final error2 = AsyncResult<String, Exception>.error(Exception("e"));
      final error3 = AsyncResult<String, Exception>.error(Exception("e2"));
      final error4 = AsyncResult<String, Exception>.error(Exception("e"), value: "stale");
      final sharedException = Exception("shared");
      final error5 = AsyncResult<String, Exception>.error(sharedException, value: "a");
      final error6 = AsyncResult<String, Exception>.error(sharedException, value: "a");
      final error7 = AsyncResult<String, Exception>.error(sharedException, value: "b");
      const loading1 = AsyncResult<String, Exception>.loading();
      const loading2 = AsyncResult<String, Exception>.loading();
      const loading3 = AsyncResult<String, Exception>.loading(value: "data");
      const empty1 = AsyncResult<String, Exception>.empty();
      const empty2 = AsyncResult<String, Exception>.empty();
      const loadingMore1 = AsyncResult<String, Exception>.loadingMore("data");
      const loadingMore2 = AsyncResult<String, Exception>.loadingMore("data");
      const loadingMore3 = AsyncResult<String, Exception>.loadingMore("different data");
      final loadingMore4 = AsyncResult<String, Exception>.loadingMore("data", error: Exception("e"));

      expect(ok1, equals(ok2));
      expect(ok1.hashCode, equals(ok2.hashCode));
      expect(ok1, isNot(equals(ok3)));

      expect(error1, isNot(equals(error2))); // Exceptions with same message are not equal
      expect(error1, isNot(equals(error3)));
      expect(error1, isNot(equals(error4)));
      expect(error5, equals(error6));
      expect(error5.hashCode, equals(error6.hashCode));
      expect(error5, isNot(equals(error7)));

      expect(loading1, equals(loading2));
      expect(loading1.hashCode, equals(loading2.hashCode));
      expect(loading1, isNot(equals(loading3)));

      expect(empty1, equals(empty2));
      expect(empty1.hashCode, equals(empty2.hashCode));
      
      expect(loadingMore1, equals(loadingMore2));
      expect(loadingMore1.hashCode, equals(loadingMore2.hashCode));
      expect(loadingMore1, isNot(equals(loadingMore3)));
      expect(loadingMore1, isNot(equals(loadingMore4)));
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

    group("handleAsyncSnapshot", () {
      test("handles ConnectionState.none", () {
        const snapshot = AsyncSnapshot<String>.nothing();
        notifier.handleAsyncSnapshot(snapshot);
        expect(notifier.value, isA<Empty>());
      });

      test("handles ConnectionState.waiting without data", () {
        const snapshot = AsyncSnapshot<String>.waiting();
        notifier.handleAsyncSnapshot(snapshot);
        expect(notifier.value, isA<Loading>());
      });

      test("handles ConnectionState.waiting with data (for LoadingMore)", () {
        final snapshot = AsyncSnapshot<String>.withData(ConnectionState.waiting, "stale data");
        notifier.handleAsyncSnapshot(snapshot);
        expect(notifier.value, isA<LoadingMore>());
        expect((notifier.value as LoadingMore).value, "stale data");
      });

      

      test("handles ConnectionState.done with data", () {
        final snapshot = const AsyncSnapshot<String>.withData(ConnectionState.done, "new data");
        notifier.handleAsyncSnapshot(snapshot);
        expect(notifier.value, isA<Ok>());
        expect((notifier.value as Ok).value, "new data");
      });

      

      test("handles ConnectionState.done with error", () {
        final error = Exception("test error");
        final snapshot = AsyncSnapshot<String>.withError(ConnectionState.done, error);
        notifier.handleAsyncSnapshot(snapshot);
        expect(notifier.value, isA<Error>());
        expect((notifier.value as Error).error, error);
      });
    });
  });
}

