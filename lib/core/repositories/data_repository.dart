/// Abstract data repository for future backend integration.
abstract class DataRepository {
  Stream<Map<String, dynamic>> getChildLocation(String childId);
  Future<void> savePayment(Map<String, dynamic> data);
}
