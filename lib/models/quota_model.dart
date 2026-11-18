class QuotaModel {
  final double currentBalance;
  final double monthlyLimit;
  final double subsidizedRate;
  final double marketRate;
  final int resetDaysRemaining;
  final String resetDate;

  const QuotaModel({
    required this.currentBalance,
    required this.monthlyLimit,
    required this.subsidizedRate,
    required this.marketRate,
    required this.resetDaysRemaining,
    required this.resetDate,
  });

  double get consumed => monthlyLimit - currentBalance;
  double get percentageUsed => ((consumed / monthlyLimit) * 100).clamp(0.0, 100.0);
  double get percentageRemaining => ((currentBalance / monthlyLimit) * 100).clamp(0.0, 100.0);

  static const QuotaModel dummy = QuotaModel(
    currentBalance: 550.0,
    monthlyLimit: 2400.0,
    subsidizedRate: 2.15,
    marketRate: 3.35,
    resetDaysRemaining: 12,
    resetDate: '1 Nov 2026',
  );
}
