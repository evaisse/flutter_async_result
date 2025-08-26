import "package:flutter/material.dart";
import "package:flutter_async_result/flutter_async_result.dart";
import "../mock_service.dart";

class SnapshotHandlerTab extends StatefulWidget {
  const SnapshotHandlerTab({super.key});

  @override
  State<SnapshotHandlerTab> createState() => _SnapshotHandlerTabState();
}

class _SnapshotHandlerTabState extends State<SnapshotHandlerTab> {
  late final AsyncResultNotifier<String, Exception> _notifier;
  final _service = MockService();
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _notifier = AsyncResultNotifier.from(
      const AsyncResult.empty(),
      onError: (e) => e is Exception ? e : Exception(e.toString()),
    );
    _fetch();
  }

  void _fetch() {
    setState(() {
      _future = _service.fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // This FutureBuilder's only job is to drive the notifier's state.
        FutureBuilder<String>(
          future: _future,
          builder: (context, snapshot) {
            // The snapshot is converted to an AsyncResult state.
            _notifier.handleAsyncSnapshot(snapshot);
            // The UI below will be rebuilt by the notifier, not the FutureBuilder.
            return const SizedBox.shrink();
          },
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // This UI reacts to the notifier's state changes.
                _notifier.watch((context, result) {
                  return switch (result) {
                    Loading() => const CircularProgressIndicator(),
                    Ok(value: final data) =>
                      Text("Success: $data", style: Theme.of(context).textTheme.headlineSmall),
                    Error(error: final e) =>
                      Text("Error: $e", style: const TextStyle(color: Colors.red)),
                    Empty() => const Text("Waiting for data..."),
                  };
                }),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _fetch, child: const Text("Refetch Data")),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
