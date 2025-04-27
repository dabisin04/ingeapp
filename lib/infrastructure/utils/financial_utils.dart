import 'dart:math';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';

class PeriodUtils {
  static double discountFactor(double rate, int periods) =>
      pow(1 + rate, -periods).toDouble();
  static double discountFactorPiecewise(List<TasaDeInteres> tasas, int period) {
    final tramo = tasas.firstWhere(
      (t) => period >= t.periodoInicio && period <= t.periodoFin,
      orElse: () => throw StateError(
          'El periodo $period no está cubierto por ninguna tasa'),
    );
    return pow(1 + tramo.valor, -period).toDouble();
  }

  static double solvePeriodsForFutureValue({
    required double presentValue,
    required double futureValue,
    required double rate,
  }) =>
      log(futureValue / presentValue) / log(1 + rate);
}
