class DriverModel {
  final String id;
  final String name;
  final String role;
  final String lorryPlate;
  final String lorryModel;
  final String depot;
  final String company;
  final String gdlLicenseNo;
  final String gdlExpiry;
  final String hazmatCertNo;
  final String hazmatExpiry;
  final String subsidyCardId;
  final double onTimeRate;
  final int totalDieselPumped;
  final double safetyRating;
  final bool biometricEnabled;
  final bool autoFlashEnabled;
  final String language;

  const DriverModel({
    required this.id,
    required this.name,
    required this.role,
    required this.lorryPlate,
    required this.lorryModel,
    required this.depot,
    required this.company,
    required this.gdlLicenseNo,
    required this.gdlExpiry,
    required this.hazmatCertNo,
    required this.hazmatExpiry,
    required this.subsidyCardId,
    required this.onTimeRate,
    required this.totalDieselPumped,
    required this.safetyRating,
    this.biometricEnabled = true,
    this.autoFlashEnabled = true,
    this.language = 'EN',
  });

  DriverModel copyWith({
    bool? biometricEnabled,
    bool? autoFlashEnabled,
    String? language,
  }) {
    return DriverModel(
      id: id,
      name: name,
      role: role,
      lorryPlate: lorryPlate,
      lorryModel: lorryModel,
      depot: depot,
      company: company,
      gdlLicenseNo: gdlLicenseNo,
      gdlExpiry: gdlExpiry,
      hazmatCertNo: hazmatCertNo,
      hazmatExpiry: hazmatExpiry,
      subsidyCardId: subsidyCardId,
      onTimeRate: onTimeRate,
      totalDieselPumped: totalDieselPumped,
      safetyRating: safetyRating,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoFlashEnabled: autoFlashEnabled ?? this.autoFlashEnabled,
      language: language ?? this.language,
    );
  }

  static const DriverModel dummy = DriverModel(
    id: 'DRV-8821',
    name: 'Ahmad Bin Razak',
    role: 'Senior Tanker Driver',
    lorryPlate: 'JDT 1111',
    lorryModel: 'Scania R500 (40 Tonne Tanker)',
    depot: 'Pasir Gudang Depot #2',
    company: 'Ong Brothers Petroleum Sdn Bhd',
    gdlLicenseNo: 'GDL-8821-E',
    gdlExpiry: '14 May 2027',
    hazmatCertNo: 'HAZ-DG-4401',
    hazmatExpiry: '30 Nov 2026',
    subsidyCardId: 'SKDS-OBP-9921',
    onTimeRate: 99.2,
    totalDieselPumped: 148200,
    safetyRating: 4.9,
    biometricEnabled: true,
    autoFlashEnabled: true,
    language: 'EN',
  );
}
