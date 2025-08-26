import "package:flutter/material.dart";
import "package:flutter_async_result_example/screens/basic_fetch_tab.dart";
import "package:flutter_async_result_example/screens/empty_state_tab.dart";
import "package:flutter_async_result_example/screens/refresh_tab.dart";
import "package:flutter_async_result_example/screens/snapshot_handler_tab.dart";
import "package:flutter_async_result_example/screens/stream_tab.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AsyncResult Example",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("AsyncResult Examples"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Basic Fetch"),
              Tab(text: "Refresh"),
              Tab(text: "Stream"),
              Tab(text: "Empty State"),
              Tab(text: "Snapshot Handler"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BasicFetchTab(),
            RefreshTab(),
            StreamTab(),
            EmptyStateTab(),
            SnapshotHandlerTab(),
          ],
        ),
      ),
    );
  }
}