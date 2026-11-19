import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class UnauthorizedRoleException implements Exception {
  final String message;
  const UnauthorizedRoleException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth? _auth = FirebaseService.isInitialized ? FirebaseAuth.instance : null;
  final FirebaseFirestore? _firestore = FirebaseService.isInitialized ? FirebaseFirestore.instance : null;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Stream<UserModel?> authStateChanges() {
    if (!FirebaseService.isInitialized || _auth == null) {
      return Stream.value(_currentUser);
    }
    return _auth!.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _currentUser = null;
        return null;
      }
      return _fetchUserDoc(user.uid, user.email ?? '');
    });
  }

  Future<UserModel> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    final cleanInput = emailOrUsername.trim();
    final email = cleanInput.contains('@')
        ? cleanInput
        : '${cleanInput.toLowerCase().replaceAll(' ', '')}@obp.com.my';

    debugPrint('[AuthService] Attempting login for email: $email');

    // 1. Firebase Live Authentication
    if (FirebaseService.isInitialized && _auth != null && _firestore != null) {
      try {
        final credential = await _auth!.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final firebaseUser = credential.user;
        if (firebaseUser == null) {
          throw Exception('Authentication failed: user is null.');
        }

        // Fetch User record from Firestore
        final userModel = await _fetchUserDoc(firebaseUser.uid, email);

        // Strict Role-Based Access Control (RBAC)
        if (!userModel.isDriver) {
          debugPrint('[AuthService] RBAC Violation: user is ${userModel.role}');
          await _auth!.signOut();
          _currentUser = null;
          throw const UnauthorizedRoleException(
            'Access Denied: Managers must use the Web Dashboard (obp-fleet-hub). Only Drivers can access the mobile cabin.',
          );
        }

        _currentUser = userModel;
        return userModel;
      } on FirebaseAuthException catch (e) {
        debugPrint('[AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
        rethrow;
      }
    }

    // 2. Demo / Fallback Authentication Mode
    await Future.delayed(const Duration(milliseconds: 600));

    // Simulate Manager rejection test
    if (cleanInput.toLowerCase().contains('manager') || cleanInput.toLowerCase().contains('admin')) {
      throw const UnauthorizedRoleException(
        'Access Denied: Managers must use the Web Dashboard (obp-fleet-hub). Only Drivers can access the mobile cabin.',
      );
    }

    // Default Driver
    _currentUser = UserModel(
      uid: 'demo_driver_001',
      email: email,
      displayName: 'Ahmad Bin Razak',
      role: 'driver',
      driverId: cleanInput.toUpperCase(),
      assignedVehicleId: 'veh_jdt1111',
      phone: '+60 12-345 6789',
      status: 'active',
    );

    return _currentUser!;
  }

  Future<UserModel> _fetchUserDoc(String uid, String email) async {
    try {
      final doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(uid, doc.data()!);
      }

      // Query by email or driverId
      final query = await _firestore!
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromMap(query.docs.first.id, query.docs.first.data());
      }
    } catch (e) {
      debugPrint('[AuthService] Error fetching user doc: $e');
    }

    // Default fallback to driver if doc missing
    return UserModel(
      uid: uid,
      email: email,
      displayName: 'Driver',
      role: 'driver',
      driverId: 'DRV-8821',
      assignedVehicleId: 'veh_jdt1111',
      status: 'active',
    );
  }

  Future<void> signOut() async {
    if (FirebaseService.isInitialized && _auth != null) {
      await _auth!.signOut();
    }
    _currentUser = null;
  }
}
