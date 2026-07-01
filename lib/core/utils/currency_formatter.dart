import 'package:intl/intl.dart';

/// Formats amounts as Bangladeshi Taka with thousands separators, e.g.
/// `formatBDT(125000)` -> `৳1,25,000` (using the South Asian digit
/// grouping convention — lakhs/crores — rather than the western
/// thousands-only grouping).
///
/// Centralizing this avoids the inconsistent `'৳${amount.toStringAsFixed(0)}'`
/// pattern scattered across screens, which doesn't add thousands
/// separators and reads poorly for larger trip budgets.
String formatBDT(num amount) {
  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '৳', decimalDigits: 0);
  return formatter.format(amount);
}
