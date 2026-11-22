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

  /// Retrieves the latest approved odometer reading for a vehicle from Firestore.
  /// Falls back to the vehicle's baseline odometer if no approved claims exist.
  Future<int> getLastApprovedOdometer({
    required String vehicleId,
    int fallbackOdometer = 248000,
  }) async {
    if (!FirebaseService.isInitialized || _firestore == null) {
      return fallbackOdometer;
    }

    try {
      final query = await _firestore!
          .collection('fuel_claims')
          .where('vehicleId', isEqualTo: vehicleId)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final odo = (data['odometerKm'] as num?)?.toInt();
        if (odo != null && odo > 0) {
          debugPrint('[FuelClaimService] Latest approved odometer for $vehicleId: $odo km');
          return odo;
        }
      }

      // Check baseline vehicle document in Firestore
      final vehicleDoc = await _firestore!.collection('vehicles').doc(vehicleId).get();
      if (vehicleDoc.exists) {
        final vData = vehicleDoc.data();
        final vOdo = (vData?['currentOdometer'] as num?)?.toInt();
        if (vOdo != null && vOdo > 0) {
          debugPrint('[FuelClaimService] Baseline odometer from vehicle record: $vOdo km');
          return vOdo;
        }
      }
    } catch (e) {
      debugPrint('[FuelClaimService] Error fetching last approved odometer: $e');
    }

    return fallbackOdometer;
  }

  /// Checks Firestore to ensure an identical image hash has not been submitted previously.
  Future<bool> checkIsDuplicateImageHash(String imageHash) async {
    if (!FirebaseService.isInitialized || _firestore == null || imageHash.isEmpty) {
      return false;
    }

    try {
      final query = await _firestore!
          .collection('fuel_claims')
          .where('imageHash', isEqualTo: imageHash)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[FuelClaimService] Error checking duplicate image hash: $e');
      return false;
    }
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
    int? previousOdometer,
    int? distanceTravelled,
    double? kmPerLitre,
    double? ocrConfidence,
    String captureSource = 'live_camera',
    String? imageHash,
    bool isAnomaly = false,
    String? anomalyReason,
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
          debugPrint('[FuelClaimService] Uploaded watermarked odometer image: $odoUrl');
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
      previousOdometer: previousOdometer,
      distanceTravelled: distanceTravelled,
      kmPerLitre: kmPerLitre,
      ocrConfidence: ocrConfidence,
      captureSource: captureSource,
      imageHash: imageHash,
      isAnomaly: isAnomaly,
      anomalyReason: anomalyReason,
    );

    // 2. Write to Firestore `fuel_claims` collection
    if (FirebaseService.isInitialized && _firestore != null) {
      try {
        await _firestore!.collection('fuel_claims').doc(claimId).set(claim.toMap());

        // Increment vehicle's currentQuotaUsage and currentOdometer
        await _firestore!.collection('vehicles').doc(vehicleId).update({
          'currentQuotaUsage': FieldValue.increment(liters),
          'currentOdometer': odometerKm,
          'lastRefuelDate': FieldValue.serverTimestamp(),
        });

        // Add driver notification (with anomaly flag indicator if detected)
        await _firestore!.collection('notifications').add({
          'userId': driverId,
          'title': isAnomaly ? 'Claim Submitted (Under Audit): $claimId' : 'New Claim Submitted: $claimId',
          'message': isAnomaly
              ? '${liters.toStringAsFixed(1)} L at $stationName logged with audit note: $anomalyReason.'
              : '${liters.toStringAsFixed(1)} L at $stationName is pending manager verification.',
          'type': 'claim_status',
          'claimId': claimId,
          'category': 'quota',
          'priority': isAnomaly ? 'high' : 'normal',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint('[FuelClaimService] Claim document saved to Firestore: $claimId (Anomaly: $isAnomaly)');
      } catch (e) {
        debugPrint('[FuelClaimService] Error writing claim to Firestore: $e');
      }
    }

    // Always maintain local cache for responsive UI
    _fallbackClaims.insert(0, claim);
    return claim;
  }
}
