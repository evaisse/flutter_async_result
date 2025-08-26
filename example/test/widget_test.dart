import "package:flutter/material.dart";
import "package:flutter_async_result_example/main.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("App smoke test: initial state and tab navigation", (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the initial tab (Basic Fetch) is displayed.
    expect(find.text("Basic Fetch"), findsOneWidget);
    expect(find.text("Press the button to fetch data."), findsOneWidget);

    // Tap the 'Refresh' tab and trigger a frame.
    await tester.tap(find.text("Refresh"));
    await tester.pumpAndSettle(); // Wait for animations and futures

    // Verify the second tab is displayed with its initial list.
    expect(find.text("Item 1"), findsOneWidget);

    // Tap the 'Stream' tab.
    await tester.tap(find.text("Stream"));
    await tester.pump();

    // Verify the third tab is displayed.
    expect(find.text("Press the button to start the stream."), findsOneWidget);
    
    // Tap the 'Empty State' tab.
    await tester.tap(find.text("Empty State"));
    await tester.pump();

    // Verify the fourth tab is displayed.
    expect(find.text("The operation was successful but returned no data."), findsNothing);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets("Basic Fetch Tab - Success Flow", (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Find the button and tap it.
    await tester.tap(find.widgetWithText(ElevatedButton, "Fetch Data"));
    await tester.pump(); // Start the future

    // Verify loading indicator is shown.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the future to complete.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Check for either success or error, as it's random.
    final successFinder = find.textContaining("Success: Hello, World!");
    final errorFinder = find.textContaining("Error: Exception: Failed to fetch data");

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(successFinder.evaluate().isNotEmpty || errorFinder.evaluate().isNotEmpty, isTrue);
  });

  testWidgets("Refresh Tab - Initial load and RefreshIndicator", (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Go to the refresh tab.
    await tester.tap(find.text("Refresh"));
    await tester.pump(); // Start initial fetch

    // Should be in loading state initially.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Finish initial load.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify list is present.
    expect(find.text("Item 1"), findsOneWidget);
    expect(find.text("Item 10"), findsOneWidget);

    // Simulate a pull-to-refresh.
    await tester.fling(find.text("Item 1"), const Offset(0.0, 300.0), 1000.0);
    await tester.pump(); // Start the refresh
    
    // The list should still be visible, with a loading indicator for LoadingMore state.
    expect(find.text("Item 1"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the refresh to complete.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // List should still be there, indicator should be gone.
    expect(find.text("Item 1"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  
  testWidgets("Empty State Tab - Fetches and shows empty message", (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Go to the empty state tab.
    await tester.tap(find.text("Empty State"));
    await tester.pump();

    // Tap the fetch button.
    await tester.tap(find.widgetWithText(ElevatedButton, "Fetch Empty Data"));
    await tester.pump(); // Start the future

    // Verify loading indicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for future to complete.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify the empty state message is shown.
    expect(find.text("The operation was successful but returned no data."), findsOneWidget);
  });
}
