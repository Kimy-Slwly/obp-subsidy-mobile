class VehicleModel {
  final String id;
  final String plateNumber;
  final String model;
  final double monthlyQuotaLimit; // e.g. 1400.0 L (shares 5,400L total across 4 lorries)
  final double currentQuotaUsage; // e.g. 850.0 L
  final String status; // "active" | "maintenance" | "inactive"
  final String? assignedDriverId;
  final String? assignedDriverName;
  final int currentOdometer;
  final String depot;
  final DateTime? lastRefuelDate;

  const VehicleModel({
    required this.id,
    required this.plateNumber,
    required this.model,
    required this.monthlyQuotaLimit,
    required this.currentQuotaUsage,
    this.status = 'active',
    this.assignedDriverId,
    this.assignedDriverName,
    this.currentOdometer = 248930,
    this.depot = 'Pasir Gudang Depot #2',
    this.lastRefuelDate,
  });

  double get remainingQuota => (monthlyQuotaLimit - currentQuotaUsage).clamp(0.0, monthlyQuotaLimit);
  double get usagePercentage => (currentQuotaUsage / monthlyQuotaLimit).clamp(0.0, 1.0);
  double get remainingPercentage => (remainingQuota / monthlyQuotaLimit).clamp(0.0, 1.0);

  bool get isActive => status.toLowerCase() == 'active';
  bool get isMaintenance => status.toLowerCase() == 'maintenance';

  factory VehicleModel.fromMap(String id, Map<String, dynamic> data) {
    return VehicleModel(
      id: id,
      plateNumber: data['plateNumber'] as String? ?? data['plate'] as String? ?? 'JDT 1111',
      model: data['model'] as String? ?? 'Scania R500 (40T)',
      monthlyQuotaLimit: (data['monthlyQuotaLimit'] as num?)?.toDouble() ?? 1400.0,
      currentQuotaUsage: (data['currentQuotaUsage'] as num?)?.toDouble() ?? (data['quotaUsed'] as num?)?.toDouble() ?? 850.0,
      status: data['status'] as String? ?? 'active',
      assignedDriverId: data['assignedDriverId'] as String?,
      assignedDriverName: data['assignedDriverName'] as String?,
      currentOdometer: (data['currentOdometer'] as num?)?.toInt() ?? 248930,
      depot: data['depot'] as String? ?? 'Pasir Gudang Depot #2',
      lastRefuelDate: data['lastRefuelDate'] != null ? DateTime.tryParse(data['lastRefuelDate'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'model': model,
      'monthlyQuotaLimit': monthlyQuotaLimit,
      'currentQuotaUsage': currentQuotaUsage,
      'status': status,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'currentOdometer': currentOdometer,
      'depot': depot,
      'lastRefuelDate': lastRefuelDate?.toIso8601String(),
    };
  }

  static const VehicleModel dummy = VehicleModel(
    id: 'veh_jdt1111',
    plateNumber: 'JDT 1111',
    model: 'Scania R500 (40T Tanker)',
    monthlyQuotaLimit: 1400.0,
    currentQuotaUsage: 850.0,
    status: 'active',
    assignedDriverId: 'DRV-8821',
    assignedDriverName: 'Ahmad Bin Razak',
    currentOdometer: 248930,
    depot: 'Pasir Gudang Depot #2',
  );
}
