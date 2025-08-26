# flutter_async_result

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A robust and type-safe solution for managing asynchronous operation states in Flutter.

I works as a lightweight completion to [the flutter type-safe error handling recommandation](https://docs.flutter.dev/app-architecture/design-patterns/result)   

## Overview

This package provides a type-safe state management solution for handling asynchronous operations in Flutter applications. Instead of relying on `FutureBuilder` and manually checking connection states, this utility introduces a more predictable system built around a sealed class hierarchy (`AsyncResult`).

This design encourages the use of pattern matching (via `switch` statements) to handle all possible outcomes of an async call, preventing common errors where a state might be overlooked.

## Core Concepts

The `AsyncResult` sealed class defines a clear and finite/immutable set of states for any asynchronous operation:

-   **`Loading`**: An operation is in progress for the first time.
-   **`LoadingMore`**: An operation is in progress, but there is already existing data (e.g., for pagination or pull-to-refresh).
-   **`Ok`**: The operation completed successfully with data.
-   **`Error`**: The operation failed.
-   **`Empty`**: The operation completed successfully but returned no data.
-   **`Maybe`**: is a state that just focus on "sync" values, `Error|Ok|Empty`.

The `AsyncResultNotifier` acts as a `ValueNotifier`, holding the current state and providing utility functions to execute futures, manage state transitions, and connect seamlessly to the Flutter UI.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_async_result: ^latest_version # Replace with the latest version
```

Then, run `flutter pub get` in your terminal.

## Usage

### 1. Create an `AsyncResultNotifier`

The notifier is responsible for holding the state of your asynchronous operation. You typically create it within a `StatefulWidget` or provide it using a state management solution like `provider`.

```dart
import 'package:flutter_async_result/flutter_async_result.dart';

class MyNotifier extends AsyncResultNotifier<String, Exception> {
  MyNotifier() : super.from(
    const AsyncResult.empty(),
    onError: (e) => e is Exception ? e : Exception(e.toString()),
  );

  Future<void> fetchData() async {
    // A mock API call
    final future = Future.delayed(const Duration(seconds: 2), () {
      if (DateTime.now().second.isEven) {
        return "Hello from the Future!";
      } else {
        throw Exception("Failed to fetch data.");
      }
    });

    await refresh(future);
  }
}
```

### 2. Build Your UI with `watch`

Use the `notifier.watch()` method to listen to state changes and rebuild your UI accordingly. The `switch` statement ensures you handle every possible state in a type-safe way.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_async_result/flutter_async_result.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late final MyNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = MyNotifier();
    _notifier.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AsyncResult Demo'),
      ),
      body: _notifier.watch((context, result) {
        return switch (result) {
          Loading() => const Center(child: CircularProgressIndicator()),
          LoadingMore(value: final data) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Text('Refreshing data: $data'),
            ],
          ),
          Ok(value: final data) => Center(
            child: Text('Success: $data'),
          ),
          Error(error: final e) => Center(
            child: Text(
              'An error occurred: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          Empty() => const Center(
            child: Text('No data yet. Tap refresh to start.'),
          ),
        };
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _notifier.fetchData(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

## Example Application

A fully functional Flutter application demonstrating the concepts described above is available in the `/example` directory of this repository. You can run it to see a live demonstration of `AsyncResultNotifier` in action.

## API Overview

### `AsyncResult<T, E>`

A sealed class representing the state.

-   `AsyncResult.ok(T value)`: Success state with data.
-   `AsyncResult.error(E error, {T? value})`: Error state with an exception.
-   `AsyncResult.loading({T? value})`: Loading state, optionally with previous data.
-   `AsyncResult.loadingMore(T value)`: Loading state with existing data (for refresh scenarios).
-   `AsyncResult.empty()`: Initial or empty data state.

### `AsyncResultNotifier<T, E>`

A `ValueNotifier` to manage and expose the `AsyncResult` state.

-   `AsyncResultNotifier.from(AsyncResult<T, E> initialData, {required E Function(Object?) onError})`: Constructor to create the notifier. The `onError` function is crucial for converting caught exceptions into the desired error type `E`.
-   `Future<void> refresh(Future<T> future)`: Executes a future, automatically transitioning between `Loading`, `Ok`, and `Error` states.
-   `T? getStateValue()`: A utility to extract the current data from the state, if available.
-   `Widget watch(Widget Function(BuildContext, AsyncResult<T, E>) builder)`: A convenience method that uses a `ValueListenableBuilder` to rebuild your widget when the state changes.
-   `void listen(void Function(AsyncResult<T, E> newValue, [AsyncResult<T, E>? oldValue]) listener)`: Allows you to listen to state changes programmatically, for side-effects like showing a snackbar.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.