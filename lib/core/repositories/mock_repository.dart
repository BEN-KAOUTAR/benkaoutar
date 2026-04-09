import 'data_repository.dart';

/// Mock repository implementation for prototype.
/// Will be replaced with Firebase/API repository when backend is ready.
class MockRepository implements DataRepository {
  @override
  Stream<Map<String, dynamic>> getChildLocation(String childId) async* {
    yield {
      'latitude': 33.5731,
      'longitude': -7.5898,
      'isMoving': false,
    };
  }

  @override
  Future<void> savePayment(Map<String, dynamic> data) async {
    // Mock save — does nothing in prototype
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
