import "dart:async";
import "dart:math";

class MockService {
  Future<String> fetchData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (Random().nextBool()) {
      return "Hello, World! (from the internet)";
    } else {
      throw Exception("Failed to fetch data");
    }
  }

  Future<List<String>> fetchItems() async {
    await Future.delayed(const Duration(seconds: 2));
    return List.generate(10, (index) => "Item ${index + 1}");
  }

  Future<List<String>> fetchEmptyItems() async {
    await Future.delayed(const Duration(seconds: 2));
    return [];
  }

  Stream<int> countStream() {
    return Stream.periodic(const Duration(seconds: 1), (i) => i + 1).take(5);
  }
}
