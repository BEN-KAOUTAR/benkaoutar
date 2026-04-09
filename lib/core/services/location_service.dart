import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تحديث موقع الولد (من جهة الطفل أو الـ app)
  Future<void> updateChildLocation(String childId, Position position) async {
    await _firestore.collection('children_locations').doc(childId).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'isMoving': true,
    }, SetOptions(merge: true));
  }

  // الاستماع للموقع فـ realtime (في صفحة الوالد)
  Stream<DocumentSnapshot> getChildLocationStream(String childId) {
    return _firestore
        .collection('children_locations')
        .doc(childId)
        .snapshots();   // هذا هو الـ realtime!
  }
}
