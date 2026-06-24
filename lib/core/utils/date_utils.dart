class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static DateTime calculateWarrantyExpiry(DateTime saleDate, int months) {
    return DateTime(
      saleDate.year + (saleDate.month + months - 1) ~/ 12,
      (saleDate.month + months - 1) % 12 + 1,
      saleDate.day,
      saleDate.hour,
      saleDate.minute,
      saleDate.second,
    );
  }

  static bool isWarrantyActive(DateTime expiryDate) {
    return expiryDate.isAfter(DateTime.now());
  }

  static String formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
      count++;
    }

    return '\$${buffer.toString().split('').reversed.join()}.$decimalPart';
  }

  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  static ({DateTime start, DateTime end}) getDateRange(String filterType) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filterType.toLowerCase()) {
      case 'daily':
        return (
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case 'weekly':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (
          start: weekStart,
          end: weekStart.add(const Duration(days: 7)),
        );
      case 'monthly':
        final monthStart = DateTime(today.year, today.month, 1);
        final monthEnd = DateTime(today.year, today.month + 1, 1);
        return (
          start: monthStart,
          end: monthEnd,
        );
      case 'all':
      default:
        return (
          start: DateTime(2000, 1, 1),
          end: now.add(const Duration(days: 365 * 100)),
        );
    }
  }
}
