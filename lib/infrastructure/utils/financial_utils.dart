// lib/infrastructure/utils/period_utils.dart

import 'dart:math';

class PeriodUtils {
  /// Factor de descuento: 1 / (1 + rate)^periods
  static double discountFactor(double rate, int periods) {
    return pow(1 + rate, -periods).toDouble();
  }

  /// Resuelve n de PV*(1+rate)^n = FV
  static double solvePeriodsForFutureValue({
    required double presentValue,
    required double futureValue,
    required double rate,
  }) {
    return log(futureValue / presentValue) / log(1 + rate);
  }
}
