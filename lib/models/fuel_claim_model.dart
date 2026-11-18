enum ClaimStatus {
  approved('Approved'),
  pending('Pending'),
  rejected('Rejected');

  final String label;
  const ClaimStatus(this.label);
}

class FuelClaimModel {
  final String id;
  final String stationName;
  final String date;
  final double liters;
  final double ratePerLiter;
  final int odometerKm;
  final ClaimStatus status;
  final bool locationVerified;
  final bool receiptUploaded;
  final bool odometerVerified;
  final String lorryPlate;

  const FuelClaimModel({
    required this.id,
    required this.stationName,
    required this.date,
    required this.liters,
    required this.ratePerLiter,
    required this.odometerKm,
    required this.status,
    required this.locationVerified,
    required this.receiptUploaded,
    required this.odometerVerified,
    required this.lorryPlate,
  });

  double get totalAmount => liters * ratePerLiter;

  static List<FuelClaimModel> dummyList = const [
    FuelClaimModel(
      id: 'CLM-40921',
      stationName: 'Shell Rawang R&R (Northbound)',
      date: '12 Oct 2026 • 14:32',
      liters: 280.5,
      ratePerLiter: 2.15,
      odometerKm: 248930,
      status: ClaimStatus.approved,
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: true,
      lorryPlate: 'JDT 1111',
    ),
    FuelClaimModel(
      id: 'CLM-40918',
      stationName: 'Shell Gombak Tollbound',
      date: '09 Oct 2026 • 09:15',
      liters: 310.0,
      ratePerLiter: 2.15,
      odometerKm: 248650,
      status: ClaimStatus.pending,
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: false,
      lorryPlate: 'JDT 1111',
    ),
    FuelClaimModel(
      id: 'CLM-40899',
      stationName: 'Shell Kempas Highway Stop',
      date: '04 Oct 2026 • 18:40',
      liters: 350.2,
      ratePerLiter: 2.15,
      odometerKm: 248340,
      status: ClaimStatus.approved,
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: true,
      lorryPlate: 'JDT 1111',
    ),
    FuelClaimModel(
      id: 'CLM-40842',
      stationName: 'Shell Pasir Gudang Port Access',
      date: '28 Sep 2026 • 11:05',
      liters: 299.3,
      ratePerLiter: 2.15,
      odometerKm: 247990,
      status: ClaimStatus.approved,
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: true,
      lorryPlate: 'JDT 1111',
    ),
  ];
}
