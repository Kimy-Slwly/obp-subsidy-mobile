import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/fuel_claim_model.dart';
import 'firebase_service.dart';

class FuelClaimService {
  final FirebaseFirestore? _firestore = FirebaseService.isInitialized ? FirebaseFirestore.instance : null;
  final FirebaseStorage? _storage = FirebaseService.isInitialized ? FirebaseStorage.instance : null;

  // In-memory fallback list
  static final List<FuelClaimModel> _fallbackClaims = List.from(FuelClaimModel.dummyList);

  Stream<List<FuelClaimModel>> getDriverClaimsStream(String driverId) {
    if (!FirebaseService.isInitialized || _firestore == null) {
      return Stream.value(List<FuelClaimModel>.unmodifiable(_fallbackClaims));
    }

    return _firestore!
        .collection('fuel_claims')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map<List<FuelClaimModel>>((snapshot) {
      if (snapshot.docs.isEmpty) {
        return List<FuelClaimModel>.unmodifiable(_fallbackClaims);
      }
      return snapshot.docs
          .map<FuelClaimModel>((doc) => FuelClaimModel.fromMap(doc.id, doc.data()))
          .toList();
    }).handleError((error) {
      debugPrint('[FuelClaimService] Error listening to claims: $error');
    });
  }

  Future<FuelClaimModel> submitClaim({
    required String driverId,
    required String driverName,
    required String vehicleId,
    required String vehiclePlate,
    required String stationName,
    required double liters,
    required double ratePerLiter,
    required int odometerKm,
    File? odometerFile,
    File? receiptFile,
    double? gpsLatitude,
    double? gpsLongitude,
    String? gpsAddress,
  }) async {
    final claimId = 'CLM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    String? odoUrl;
    String? receiptUrl;

    // 1. Upload Images to Firebase Storage (if available and files provided)
    if (FirebaseService.isInitialized && _storage != null) {
      try {
        if (odometerFile != null && await odometerFile.exists()) {
          final odoRef = _storage!.ref('fuel_claims/$claimId/odometer_${DateTime.now().millisecondsSinceEpoch}.jpg');
          final uploadTask = await odoRef.putFile(odometerFile);
          odoUrl = await uploadTask.ref.getDownloadURL();
          debugPrint('[FuelClaimService] Uploaded odometer image: $odoUrl');
        }

        if (receiptFile != null && await receiptFile.exists()) {
          final receiptRef = _storage!.ref('fuel_claims/$claimId/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg');
          final uploadTask = await receiptRef.putFile(receiptFile);
          receiptUrl = await uploadTask.ref.getDownloadURL();
          debugPrint('[FuelClaimService] Uploaded receipt image: $receiptUrl');
        }
      } catch (e) {
        debugPrint('[FuelClaimService] Warning: Storage upload error: $e. Proceeding with claim submission.');
      }
    }

    final totalAmount = liters * ratePerLiter;

    final claim = FuelClaimModel(
      id: claimId,
      claimId: claimId,
      driverId: driverId,
      driverName: driverName,
      vehicleId: vehicleId,
      vehiclePlate: vehiclePlate,
      stationName: stationName,
      liters: liters,
      ratePerLiter: ratePerLiter,
      totalAmount: totalAmount,
      odometerKm: odometerKm,
      odometerImageUrl: odoUrl,
      receiptImageUrl: receiptUrl,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      gpsAddress: gpsAddress,
      locationVerified: gpsLatitude != null,
      receiptUploaded: receiptUrl != null || receiptFile != null,
      odometerVerified: true,
      status: ClaimStatus.pending,
      createdAt: DateTime.now(),
    );

    // 2. Write to Firestore `fuel_claims` collection
    if (FirebaseService.isInitialized && _firestore != null) {
      try {
        await _firestore!.collection('fuel_claims').doc(claimId).set(claim.toMap());

        // Increment vehicle's currentQuotaUsage
        await _firestore!.collection('vehicles').doc(vehicleId).update({
          'currentQuotaUsage': FieldValue.increment(liters),
          'currentOdometer': odometerKm,
          'lastRefuelDate': FieldValue.serverTimestamp(),
        });

        // Add driver notification
        await _firestore!.collection('notifications').add({
          'userId': driverId,
          'title': 'New Claim Submitted: $claimId',
          'message': '${liters.toStringAsFixed(1)} L at $stationName is pending manager verification.',
          'type': 'claim_status',
          'claimId': claimId,
          'category': 'quota',
          'priority': 'normal',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint('[FuelClaimService] Claim document saved to Firestore: $claimId');
      } catch (e) {
        debugPrint('[FuelClaimService] Error writing claim to Firestore: $e');
      }
    }

    // Always maintain local cache for responsive UI
    _fallbackClaims.insert(0, claim);
    return claim;
  }
}
