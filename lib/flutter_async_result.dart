import "package:flutter/material.dart";

import "dart:async";

/// Provides a type-safe state management solution for handling asynchronous
/// operations in Flutter applications.
///
/// Instead of relying on `FutureBuilder` and manually checking connection states,
/// this utility introduces a more robust and predictable system built around a
/// sealed class hierarchy (`AsyncResult`). This design choice encourages the use of
/// pattern matching (via `switch` statements) to handle all possible outcomes
/// of an async call, preventing common errors where a state might be overlooked.
///
/// The sealed class defines a clear and finite set of states:
/// *   [Loading]: An operation is in progress for the first time.
/// *   [LoadingMore]: An operation is in progress, but there is already existing
///     data (e.g., for pagination or pull-to-refresh).
/// *   [Ok]: The operation completed successfully with data.
/// *   [Error]: The operation failed.
/// *   [Empty]: The operation completed successfully but returned no data.
///
/// On top of this state model, the [AsyncResultNotifier] acts as a [ValueNotifier],
/// holding the current state and providing utility functions to execute futures,
/// manage state transitions, and connect seamlessly to the Flutter UI.
///
/// [T] is the type of the data.
/// [E] is the type of the error.
sealed class AsyncResult<T extends Object, E extends Exception> {
  const AsyncResult();

  /// Creates a `AsyncResult` instance with a success state and a value.
  const factory AsyncResult.ok(T value) = Ok._;

  /// Creates a `AsyncResult` instance with an error state.
  const factory AsyncResult.error(E error, {T? value, StackTrace? stackTrace}) =
      Error._;

  /// Creates a `AsyncResult` instance with a loading state.
  const factory AsyncResult.loading({T? value, E? error}) = Loading._;

  /// Creates a `AsyncResult` instance with a loading more state, indicating
  /// that more data is being loaded while previous data is still available.
  const factory AsyncResult.loadingMore(T value, {E? error}) = LoadingMore._;

  /// Creates a `AsyncResult` instance with an empty state.
  const factory AsyncResult.empty() = Empty._;
}

/// A sealed class that represents a `AsyncResult` that can either be `Empty` or a `Result`.
sealed class Maybe<T extends Object, E extends Exception>
    extends AsyncResult<T, E> {
  const Maybe._();
}

/// Represents an empty state, where there is no data.
class Empty<T extends Object, E extends Exception> extends Maybe<T, E> {
  const Empty._() : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Empty && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// A sealed class that represents the result of an operation, which can be either `Ok` or `Error`.
sealed class Result<T extends Object, E extends Exception> extends Maybe<T, E> {
  const Result._() : super._();
}

/// Represents a successful result with a value.
class Ok<T extends Object, E extends Exception> extends Result<T, E> {
  final T value;

  const Ok._(this.value) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ok && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Represents a failure with an error and an optional value.
class Error<T extends Object, E extends Exception> extends Result<T, E> {
  final E error;
  final T? value;
  final StackTrace? stackTrace; //ignore: unused-code

  const Error._(this.error, {this.value, this.stackTrace}) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          value == other.value;

  @override
  int get hashCode => error.hashCode;
}

/// Represents the state where data is being loaded.
class Loading<T extends Object, E extends Exception> extends AsyncResult<T, E> {
  final T? value;
  final E? error;

  const Loading._({this.value, this.error});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Loading &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          value == other.value;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Represents the state where more data is being loaded while previous data is still available.
class LoadingMore<T extends Object, E extends Exception> extends Loading<T, E> {
  @override // just nee to override this to make non optional.
  // ignore: overridden_fields
  final T value;

  const LoadingMore._(this.value, {super.error}) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingMore &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A `ValueNotifier` that holds a `AsyncResult` object and notifies listeners of changes.
class AsyncResultNotifier<T extends Object, E extends Exception>
    extends ValueNotifier<AsyncResult<T, E>> {
  /// A function that converts an error object into an exception of type [E].
  E Function(Object? error) onError;

  /// Creates a `AsyncResultNotifier` with an initial `AsyncResult` state.
  AsyncResultNotifier.from(super.data, {required this.onError});

  /// Refreshes the data from a `Future`.
  ///
  /// Sets the state to `Loading` before executing the future, and then updates
  /// the state to `Ok` on success or `Error` on failure.
  //ignore: unused-code
  Future<void> refresh(Future<T> future) async {
    value = AsyncResult.loading(value: getStateValue());
    try {
      final fv = await future;
      value = AsyncResult.ok(fv);
    } catch (e, stackTrace) {
      value = AsyncResult.error(onError(e), stackTrace: stackTrace);
    }
  }

  /// Extracts the value from the current `AsyncResult` state, if available.
  T? getStateValue() {
    return switch (value) {
      Ok<T, E>(:final value) => value,
      Error<T, E>(:final value) => value,
      Loading<T, E>(:final value) => value,
      Empty<T, E>() => null,
    };
  }

  /// Handles an `AsyncSnapshot` and updates the `AsyncResult` state accordingly.
  //ignore: unused-code
  void handleAsyncSnapshot(AsyncSnapshot<T> snapshot) {
    final rec = (
      state: snapshot.connectionState,
      data: snapshot.data,
      error: snapshot.error,
    );

    value = switch (rec) {
      (state: ConnectionState.none, data: Object? _, error: Object? _) =>
        const AsyncResult.empty(),
      (state: ConnectionState.waiting, :T? data, error: Object? _) =>
        data != null
            ? AsyncResult.loadingMore(data)
            : const AsyncResult.loading(),
      (
        state: ConnectionState.active || ConnectionState.done,
        data: T? _,
        :Object error,
      ) =>
        AsyncResult.error(onError(error), stackTrace: snapshot.stackTrace),
      (
        state: ConnectionState.active || ConnectionState.done,
        :T? data,
        error: null,
      ) =>
        data?.let((d) => AsyncResult.ok(data)) ?? const AsyncResult.empty(),
    };
  }

  /// Converts a `Stream<T>` into a `Stream<AsyncResult<T, E>>`.
  ///
  /// Yields a `Loading` state initially, then `Ok` for each value in the
  /// stream, and `Error` if the stream emits an error.
  //ignore: unused-code
  Stream<AsyncResult<T, E>> stream(Stream<T> stream) async* {
    yield AsyncResult.loading();
    try {
      await for (final value in stream) {
        yield AsyncResult.ok(value);
      }
    } catch (e, stackTrace) {
      yield AsyncResult.error(onError(e), stackTrace: stackTrace);
    }
  }

  /// A convenience method for using `ValueListenableBuilder` to watch for changes.
  Widget watch(
    Widget Function(BuildContext context, AsyncResult<T, E> value) builder,
  ) {
    return ValueListenableBuilder(
      valueListenable: this,
      builder: (context, value, child) => builder(context, value),
    );
  }

  /// Listens for changes to the `AsyncResult` state.
  void listen(
    void Function(AsyncResult<T, E> newValue, [AsyncResult<T, E>? oldValue])
    listener,
  ) {
    AsyncResult<T, E>? oldValue = value; // Initialize with current value

    addListener(() {
      final newValue = value;
      listener(newValue, oldValue);
      oldValue = newValue; // Update oldValue
    });
  }
}

extension _CastOrExtension<FROM> on FROM {
  TO? let<TO extends Object>(TO? Function(FROM value) func) {
    final that = this;
    return that != null ? func(that) : null;
  }
}

TO? tryCast<TO extends Object>(Object? input) {
  if (input is TO) {
    return input;
  } else {
    return null;
  }
}
