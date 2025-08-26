import "package:flutter/material.dart";
import "package:flutter_async_result/flutter_async_result.dart";
import "../mock_service.dart";

class BasicFetchTab extends StatefulWidget {
  const BasicFetchTab({super.key});

  @override
  State<BasicFetchTab> createState() => _BasicFetchTabState();
}

class _BasicFetchTabState extends State<BasicFetchTab> {
  late final AsyncResultNotifier<String, Exception> _notifier;
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
    _notifier.refresh(_service.fetchData());
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
              Ok(value: final data) => Text("Success: $data", style: Theme.of(context).textTheme.headlineSmall),
              Error(error: final e) => Text("Error: $e", style: const TextStyle(color: Colors.red)),
              Empty() => const Text("Press the button to fetch data."),
            };
          }),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _fetch, child: const Text("Fetch Data")),
        ],
      ),
    );
  }
}
