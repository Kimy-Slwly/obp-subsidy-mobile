import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static bool isInitialized = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      isInitialized = true;
      debugPrint('[FirebaseService] Firebase successfully initialized.');
    } catch (e) {
      isInitialized = false;
      debugPrint('[FirebaseService] Firebase initialization skipped or deferred: $e');
      debugPrint('[FirebaseService] App will run with resilient fallback mode until google-services.json is configured.');
    }
  }
}
