enum ClaimStatus {
  approved('Approved'),
  pending('Pending'),
  rejected('Rejected');

  final String label;
  const ClaimStatus(this.label);

  static ClaimStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'approved':
        return ClaimStatus.approved;
      case 'rejected':
        return ClaimStatus.rejected;
      default:
        return ClaimStatus.pending;
    }
  }
}

class FuelClaimModel {
  final String id;
  final String claimId;
  final String driverId;
  final String driverName;
  final String vehicleId;
  final String vehiclePlate;
  final String stationName;
  final double liters;
  final double ratePerLiter; // Subsidized rate e.g. RM2.15
  final double totalAmount;
  final int odometerKm;
  final String? odometerImageUrl;
  final String? receiptImageUrl;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String? gpsAddress;
  final bool locationVerified;
  final bool receiptUploaded;
  final bool odometerVerified;
  final ClaimStatus status;
  final String? managerFeedback;
  final DateTime createdAt;

  const FuelClaimModel({
    required this.id,
    required this.claimId,
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.vehiclePlate,
    required this.stationName,
    required this.liters,
    required this.ratePerLiter,
    required this.totalAmount,
    required this.odometerKm,
    this.odometerImageUrl,
    this.receiptImageUrl,
    this.gpsLatitude,
    this.gpsLongitude,
    this.gpsAddress,
    this.locationVerified = true,
    this.receiptUploaded = true,
    this.odometerVerified = true,
    this.status = ClaimStatus.pending,
    this.managerFeedback,
    required this.createdAt,
  });

  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = monthNames[createdAt.month - 1];
    final year = createdAt.year;
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$day $month $year • $hour:$minute';
  }

  factory FuelClaimModel.fromMap(String id, Map<String, dynamic> data) {
    final liters = (data['liters'] as num?)?.toDouble() ?? 0.0;
    final rate = (data['ratePerLiter'] as num?)?.toDouble() ?? 2.15;
    final total = (data['totalAmount'] as num?)?.toDouble() ?? (liters * rate);

    DateTime created;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is DateTime) {
        created = data['createdAt'] as DateTime;
      } else if (data['createdAt'] is String) {
        created = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
      } else {
        // Firestore Timestamp compatibility
        try {
          created = (data['createdAt'] as dynamic).toDate() as DateTime;
        } catch (_) {
          created = DateTime.now();
        }
      }
    } else {
      created = DateTime.now();
    }

    return FuelClaimModel(
      id: id,
      claimId: data['claimId'] as String? ?? id,
      driverId: data['driverId'] as String? ?? '',
      driverName: data['driverName'] as String? ?? 'Driver',
      vehicleId: data['vehicleId'] as String? ?? '',
      vehiclePlate: data['vehiclePlate'] as String? ?? 'JDT 1111',
      stationName: data['stationName'] as String? ?? 'Shell Station',
      liters: liters,
      ratePerLiter: rate,
      totalAmount: total,
      odometerKm: (data['odometerKm'] as num?)?.toInt() ?? 0,
      odometerImageUrl: data['odometerImageUrl'] as String?,
      receiptImageUrl: data['receiptImageUrl'] as String?,
      gpsLatitude: (data['gpsLatitude'] as num?)?.toDouble(),
      gpsLongitude: (data['gpsLongitude'] as num?)?.toDouble(),
      gpsAddress: data['gpsAddress'] as String?,
      locationVerified: data['locationVerified'] as bool? ?? true,
      receiptUploaded: data['receiptUploaded'] as bool? ?? true,
      odometerVerified: data['odometerVerified'] as bool? ?? true,
      status: ClaimStatus.fromString(data['status'] as String?),
      managerFeedback: data['managerFeedback'] as String?,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'claimId': claimId,
      'driverId': driverId,
      'driverName': driverName,
      'vehicleId': vehicleId,
      'vehiclePlate': vehiclePlate,
      'stationName': stationName,
      'liters': liters,
      'ratePerLiter': ratePerLiter,
      'totalAmount': totalAmount,
      'odometerKm': odometerKm,
      'odometerImageUrl': odometerImageUrl,
      'receiptImageUrl': receiptImageUrl,
      'gpsLatitude': gpsLatitude,
      'gpsLongitude': gpsLongitude,
      'gpsAddress': gpsAddress,
      'locationVerified': locationVerified,
      'receiptUploaded': receiptUploaded,
      'odometerVerified': odometerVerified,
      'status': status.name,
      'managerFeedback': managerFeedback,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _calcDate(int monthsAgo, int day, int hour, int minute) {
    final now = DateTime.now();
    int y = now.year;
    int m = now.month - monthsAgo;
    while (m <= 0) {
      m += 12;
      y -= 1;
    }
    final maxDay = DateTime(y, m + 1, 0).day;
    final clampedDay = day.clamp(1, maxDay);
    return DateTime(y, m, clampedDay, hour, minute);
  }

  static List<FuelClaimModel> dummyList = [
    // Current Month (e.g. November 2026)
    FuelClaimModel(
      id: 'claim_1',
      claimId: 'CLM-40921',
      driverId: 'demo_driver_001',
      driverName: 'Ahmad Bin Razak',
      vehicleId: 'veh_jdt1111',
      vehiclePlate: 'JDT 1111',
      stationName: 'Shell Rawang R&R (Northbound)',
      liters: 280.5,
      ratePerLiter: 2.15,
      totalAmount: 603.08,
      odometerKm: 248930,
      odometerImageUrl: 'https://placehold.co/600x400/png?text=Odometer+248930KM',
      receiptImageUrl: 'https://placehold.co/400x600/png?text=Shell+Receipt+RM603.08',
      gpsLatitude: 3.3214,
      gpsLongitude: 101.5781,
      gpsAddress: 'Shell Rawang R&R, Lebuhraya Utara-Selatan',
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: true,
      status: ClaimStatus.approved,
      createdAt: _calcDate(0, 19, 14, 30),
    ),
    FuelClaimModel(
      id: 'claim_2',
      claimId: 'CLM-40918',
      driverId: 'demo_driver_001',
      driverName: 'Ahmad Bin Razak',
      vehicleId: 'veh_jdt1111',
      vehiclePlate: 'JDT 1111',
      stationName: 'Shell Gombak Tollbound',
      liters: 310.0,
      ratePerLiter: 2.15,
      totalAmount: 666.50,
      odometerKm: 248650,
      gpsLatitude: 3.2514,
      gpsLongitude: 101.7312,
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: false,
      status: ClaimStatus.pending,
      createdAt: _calcDate(0, 16, 11, 15),
    ),
    FuelClaimModel(
      id: 'claim_3',
      claimId: 'CLM-40899',
      driverId: 'demo_driver_001',
      driverName: 'Ahmad Bin Razak',
      vehicleId: 'veh_jdt1111',
      vehiclePlate: 'JDT 1111',
      stationName: 'Shell Kempas Highway Stop',
      liters: 350.2,
      ratePerLiter: 2.15,
      totalAmount: 752.93,
      odometerKm: 248340,
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: true,
      status: ClaimStatus.approved,
      createdAt: _calcDate(0, 9, 16, 45),
    ),

    // 1 Month Ago (e.g. October 2026)
    FuelClaimModel(
      id: 'claim_4',
      claimId: 'CLM-40842',
      driverId: 'demo_driver_001',
      driverName: 'Ahmad Bin Razak',
      vehicleId: 'veh_jdt1111',
      vehiclePlate: 'JDT 1111',
      stationName: 'Shell Pasir Gudang Port Access',
      liters: 299.3,
      ratePerLiter: 2.15,
      totalAmount: 643.50,
      odometerKm: 247990,
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: true,
      status: ClaimStatus.approved,
      createdAt: _calcDate(1, 28, 13, 20),
    ),
    FuelClaimModel(
      id: 'claim_5',
      claimId: 'CLM-40785',
      driverId: 'demo_driver_001',
      driverName: 'Ahmad Bin Razak',
      vehicleId: 'veh_jdt1111',
      vehiclePlate: 'JDT 1111',
      stationName: 'Shell Skudai Highway',
      liters: 320.0,
      ratePerLiter: 2.15,
      totalAmount: 688.00,
      odometerKm: 247510,
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: true,
      status: ClaimStatus.rejected,
      managerFeedback: 'Receipt image blurry, please re-upload clear photo of Shell Card.',
      createdAt: _calcDate(1, 15, 9, 45),
    ),

    // 2 Months Ago (e.g. September 2026)
    FuelClaimModel(
      id: 'claim_6',
      claimId: 'CLM-40610',
      driverId: 'demo_driver_001',
      driverName: 'Ahmad Bin Razak',
      vehicleId: 'veh_jdt1111',
      vehiclePlate: 'JDT 1111',
      stationName: 'Shell Senai Airport Junction',
      liters: 275.4,
      ratePerLiter: 2.15,
      totalAmount: 592.11,
      odometerKm: 246980,
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: true,
      status: ClaimStatus.approved,
      createdAt: _calcDate(2, 22, 15, 10),
    ),
  ];
}
