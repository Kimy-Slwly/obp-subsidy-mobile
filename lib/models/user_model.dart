class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // "driver" | "manager"
  final String driverId; // e.g. "DRV-8821"
  final String? assignedVehicleId; // e.g. "veh_jdt1111"
  final String? phone;
  final String status; // "active" | "inactive"

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.driverId,
    this.assignedVehicleId,
    this.phone,
    this.status = 'active',
  });

  bool get isDriver => role.toLowerCase() == 'driver';
  bool get isManager => role.toLowerCase() == 'manager';

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? data['name'] as String? ?? 'Driver',
      role: (data['role'] as String? ?? 'driver').toLowerCase(),
      driverId: data['driverId'] as String? ?? 'DRV-8821',
      assignedVehicleId: data['assignedVehicleId'] as String? ?? data['vehicleId'] as String?,
      phone: data['phoneNumber'] as String? ?? data['phone'] as String?,
      status: data['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'driverId': driverId,
      'assignedVehicleId': assignedVehicleId,
      'phoneNumber': phone,
      'status': status,
    };
  }

  static const UserModel dummyDriver = UserModel(
    uid: 'demo_driver_001',
    email: 'ahmad.razak@obp.com.my',
    displayName: 'Ahmad Bin Razak',
    role: 'driver',
    driverId: 'DRV-8821',
    assignedVehicleId: 'veh_jdt1111',
    phone: '+60 12-345 6789',
    status: 'active',
  );
}
