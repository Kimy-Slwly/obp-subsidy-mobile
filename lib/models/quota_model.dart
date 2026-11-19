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

  /// Computes the 1st day of the upcoming month dynamically (e.g. "1 Dec 2026")
  static String formatNextResetDate([DateTime? referenceDate]) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = referenceDate ?? DateTime.now();
    int nextMonth = now.month + 1;
    int nextYear = now.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }
    return '1 ${monthNames[nextMonth - 1]} $nextYear';
  }

  /// Computes days left until the 1st of the next month
  static int calcDaysRemaining([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    int nextMonth = now.month + 1;
    int nextYear = now.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }
    final nextFirst = DateTime(nextYear, nextMonth, 1);
    return nextFirst.difference(now).inDays.clamp(1, 31);
  }

  static QuotaModel get dummy => QuotaModel(
    currentBalance: 760.0,
    monthlyLimit: 1400.0,
    subsidizedRate: 2.15,
    marketRate: 3.35,
    resetDaysRemaining: calcDaysRemaining(),
    resetDate: formatNextResetDate(),
  );
}
