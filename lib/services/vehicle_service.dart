import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';
import 'firebase_service.dart';

class VehicleService {
  final FirebaseFirestore? _firestore = FirebaseService.isInitialized ? FirebaseFirestore.instance : null;

  Stream<VehicleModel> getAssignedVehicleStream(String vehicleId) {
    if (!FirebaseService.isInitialized || _firestore == null) {
      return Stream.value(VehicleModel.dummy);
    }

    return _firestore!
        .collection('vehicles')
        .doc(vehicleId)
        .snapshots()
        .map<VehicleModel>((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return VehicleModel.fromMap(snapshot.id, snapshot.data()!);
      }
      return VehicleModel.dummy;
    }).handleError((error) {
      debugPrint('[VehicleService] Error listening to vehicle $vehicleId: $error');
    });
  }

  Future<VehicleModel> getVehicle(String vehicleId) async {
    if (!FirebaseService.isInitialized || _firestore == null) {
      return VehicleModel.dummy;
    }

    try {
      final doc = await _firestore!.collection('vehicles').doc(vehicleId).get();
      if (doc.exists && doc.data() != null) {
        return VehicleModel.fromMap(doc.id, doc.data()!);
      }
    } catch (e) {
      debugPrint('[VehicleService] Error fetching vehicle $vehicleId: $e');
    }
    return VehicleModel.dummy;
  }
}
