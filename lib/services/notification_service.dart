import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'firebase_service.dart';

class NotificationService {
  final FirebaseFirestore? _firestore =
      FirebaseService.isInitialized ? FirebaseFirestore.instance : null;

  static final List<NotificationModel> _fallbackNotifications =
      List.from(NotificationModel.dummyList);

  Stream<List<NotificationModel>> getDriverNotificationsStream(
      String driverId) {
    if (!FirebaseService.isInitialized || _firestore == null) {
      return Stream.value(
          List<NotificationModel>.unmodifiable(_fallbackNotifications));
    }

    return _firestore!
        .collection('notifications')
        .where('userId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map<List<NotificationModel>>((snapshot) {
      if (snapshot.docs.isEmpty) {
        return List<NotificationModel>.unmodifiable(_fallbackNotifications);
      }
      return snapshot.docs
          .map<NotificationModel>(
              (doc) => NotificationModel.fromMap(doc.id, doc.data()))
          .toList();
    }).handleError((error) {
      debugPrint('[NotificationService] Error streaming notifications: $error');
    });
  }

  Future<void> markAsRead(String notificationId) async {
    if (FirebaseService.isInitialized && _firestore != null) {
      try {
        await _firestore!
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      } catch (e) {
        debugPrint(
            '[NotificationService] Error marking notification as read: $e');
      }
    }

    final index =
        _fallbackNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _fallbackNotifications[index] =
          _fallbackNotifications[index].copyWith(isRead: true);
    }
  }

  Future<void> markAllAsRead(String driverId) async {
    if (FirebaseService.isInitialized && _firestore != null) {
      try {
        final query = await _firestore!
            .collection('notifications')
            .where('userId', isEqualTo: driverId)
            .where('isRead', isEqualTo: false)
            .get();

        final batch = _firestore!.batch();
        for (final doc in query.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      } catch (e) {
        debugPrint('[NotificationService] Error batch marking as read: $e');
      }
    }

    for (int i = 0; i < _fallbackNotifications.length; i++) {
      _fallbackNotifications[i] =
          _fallbackNotifications[i].copyWith(isRead: true);
    }
  }
}
