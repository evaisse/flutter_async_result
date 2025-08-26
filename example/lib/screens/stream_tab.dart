import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_async_result/flutter_async_result.dart";
import "../mock_service.dart";

class StreamTab extends StatefulWidget {
  const StreamTab({super.key});

  @override
  State<StreamTab> createState() => _StreamTabState();
}

class _StreamTabState extends State<StreamTab> {
  late final AsyncResultNotifier<int, Exception> _notifier;
  final _service = MockService();
  StreamSubscription<AsyncResult<int, Exception>>? _subscription;

  @override
  void initState() {
    super.initState();
    _notifier = AsyncResultNotifier.from(
      const AsyncResult.empty(),
      onError: (e) => e is Exception ? e : Exception(e.toString()),
    );
  }

  void _startStream() {
    _subscription?.cancel();
    _subscription = _notifier.stream(_service.countStream()).listen((result) {
      _notifier.value = result;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _notifier.watch((context, result) {
            return switch (result) {
              Loading() => const CircularProgressIndicator(),
              Ok(value: final data) =>
                Text("Latest value: $data", style: Theme.of(context).textTheme.headlineSmall),
              Error(error: final e) =>
                Text("Stream Error: $e", style: const TextStyle(color: Colors.red)),
              Empty() => const Text("Press the button to start the stream."),
            };
          }),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _startStream, child: const Text("Start Stream")),
        ],
      ),
    );
  }
}
