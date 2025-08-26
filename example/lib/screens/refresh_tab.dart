import "package:flutter/material.dart";
import "package:flutter_async_result/flutter_async_result.dart";
import "../mock_service.dart";

class RefreshTab extends StatefulWidget {
  const RefreshTab({super.key});

  @override
  State<RefreshTab> createState() => _RefreshTabState();
}

class _RefreshTabState extends State<RefreshTab> {
  late final AsyncResultNotifier<List<String>, Exception> _notifier;
  final _service = MockService();

  @override
  void initState() {
    super.initState();
    _notifier = AsyncResultNotifier.from(
      const AsyncResult.loading(),
      onError: (e) => e is Exception ? e : Exception(e.toString()),
    );
    _fetch();
  }

  Future<void> _fetch() {
    return _notifier.refresh(_service.fetchItems());
  }

  @override
  Widget build(BuildContext context) {
    return _notifier.watch((context, result) {
      final isLoadingMore = result is LoadingMore;

      return RefreshIndicator(
        onRefresh: _fetch,
        child: switch (result) {
          Ok(value: final items) ||
          LoadingMore(value: final items) =>
            ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(items[index]),
                  trailing: isLoadingMore && index == 0
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                );
              },
            ),
          Loading() => const Center(child: CircularProgressIndicator()),
          Error(error: final e) =>
            Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red))),
          Empty() => const Center(child: Text("No items found.")),
        },
      );
    });
  }
}
