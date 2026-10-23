import 'package:intl/intl.dart';

abstract class AppFormatters {
  static final _currencyFormatter = NumberFormat('#,##0', 'en_US');

  /// Formats amount in Tanzanian Shillings (e.g. 50000 -> "TSh 50,000")
  static String formatTsh(num amount) {
    return 'TSh ${_currencyFormatter.format(amount)}';
  }

  /// Formats date in Swahili (e.g. "06 Septemba 2026")
  static String formatSwahiliDate(DateTime date) {
    const swahiliMonths = [
      'Januari',
      'Februari',
      'Machi',
      'Aprili',
      'Mei',
      'Juni',
      'Julai',
      'Agosti',
      'Septemba',
      'Oktoba',
      'Novemba',
      'Desemba'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = swahiliMonths[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }
}
