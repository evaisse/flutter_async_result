import "package:flutter/material.dart";
import "package:flutter_async_result/flutter_async_result.dart";
import "../mock_service.dart";

class EmptyStateTab extends StatefulWidget {
  const EmptyStateTab({super.key});

  @override
  State<EmptyStateTab> createState() => _EmptyStateTabState();
}

class _EmptyStateTabState extends State<EmptyStateTab> {
  late final AsyncResultNotifier<List<String>, Exception> _notifier;
  final _service = MockService();

  @override
  void initState() {
    super.initState();
    _notifier = AsyncResultNotifier.from(
      const AsyncResult.empty(),
      onError: (e) => e is Exception ? e : Exception(e.toString()),
    );
  }

  void _fetch() {
    _notifier.refresh(_service.fetchEmptyItems());
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
              Ok(value: final data) => Text("Success! Items received: ${data.length}"),
              Error(error: final e) =>
                Text("Error: $e", style: const TextStyle(color: Colors.red)),
              Empty() => const Text("The operation was successful but returned no data.",
                  style: TextStyle(color: Colors.orange)),
            };
          }),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _fetch, child: const Text("Fetch Empty Data")),
        ],
      ),
    );
  }
}
