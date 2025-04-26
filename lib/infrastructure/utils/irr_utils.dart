import 'dart:math';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/valor.dart';

/// Utilidades específicas para el cálculo de IRR.
class IRRUtils {
  /// Factor de descuento: (1 + rate)^(-periods)
  static double discountFactor(double rate, int periods) {
    return pow(1 + rate, -periods).toDouble();
  }

  /// Neto en focal: descuenta cada movimiento al focalPeriod.
  static double netValueAtFocal(
    List<Movimiento> movimientos,
    double rate,
    int focalPeriod,
  ) {
    double net = 0.0;
    for (var m in movimientos) {
      if (m.valor == null) continue;
      final period = m.periodo ?? focalPeriod;
      final int n = period - focalPeriod;
      net += m.valor! * pow(1 + rate, n);
    }
    return net;
  }

  /// Derivada de la ecuación de valor respecto a i.
  static double derivative(
    List<Movimiento> movimientos,
    double rate,
    int focalPeriod,
  ) {
    double deriv = 0.0;
    for (var m in movimientos) {
      if (m.valor == null) continue;
      final period = m.periodo ?? focalPeriod;
      final int n = period - focalPeriod;
      if (n == 0) continue;
      deriv += m.valor! * n * pow(1 + rate, n - 1);
    }
    return deriv;
  }

  /// Newton–Raphson para IRR puro.
  static double solveRate({
    required List<Movimiento> movimientos,
    required int focalPeriod,
    double guess = 0.1,
    double tolerance = 1e-8,
    int maxIter = 100,
  }) {
    double rate = guess;
    for (int i = 0; i < maxIter; i++) {
      final f = netValueAtFocal(movimientos, rate, focalPeriod);
      final df = derivative(movimientos, rate, focalPeriod);
      if (df == 0) break;
      final newRate = rate - f / df;
      if ((newRate - rate).abs() < tolerance) {
        rate = newRate;
        break;
      }
      rate = newRate;
    }
    return rate;
  }

  /// IRR positiva por barrido + secante local.
  static double solveRateSimple({
    required List<Movimiento> movimientos,
    required List<Valor> valores,
    required int focalPeriod,
    double step = 0.0001,
    List<String>? steps,
  }) {
    // Construyo la ecuación en texto
    final terms = <String>[];
    for (var m in movimientos) {
      final n = (m.periodo ?? focalPeriod) - focalPeriod;
      terms.add('${m.valor!.toStringAsFixed(2)}*(1+i)^${n.abs()}');
    }
    for (var v in valores) {
      final n = (v.periodo ?? focalPeriod) - focalPeriod;
      terms.add('${v.valor!.toStringAsFixed(2)}*(1+i)^${n.abs()}');
    }
    steps?.add('Ecuación IRR t=$focalPeriod: ${terms.join(" + ")} = 0');

    // Función objetivo con signo
    double f(double rate) {
      double sum = 0.0;
      for (var m in movimientos) {
        final n = ((m.periodo ?? focalPeriod) - focalPeriod).abs();
        final c = m.valor! * pow(1 + rate, -n);
        sum += m.tipo == 'Ingreso' ? c : -c;
      }
      for (var v in valores) {
        final n = ((v.periodo ?? focalPeriod) - focalPeriod).abs();
        final c = v.valor! * pow(1 + rate, -n);
        sum += v.flujo == 'Ingreso' ? c : -c;
      }
      return sum;
    }

    // Barrido para encontrar cambio de signo
    double r0 = 0.0, f0 = f(0.0);
    for (double r1 = step; r1 <= 1.0; r1 += step) {
      final f1 = f(r1);
      if (f0 * f1 <= 0) {
        final irr = r0 - f0 * (r1 - r0) / (f1 - f0);
        steps?.add(
          'Secante entre ${r0.toStringAsFixed(4)}(${"${f0.toStringAsFixed(2)}"}) '
          'y ${r1.toStringAsFixed(4)}(${"${f1.toStringAsFixed(2)}"}) → '
          'i ≈ ${(irr * 100).toStringAsFixed(4)}%',
        );
        return irr.clamp(0.0, double.infinity);
      }
      r0 = r1;
      f0 = f1;
    }

    steps?.add(
        'No se detectó cambio de signo, IRR ≈ ${(r0 * 100).toStringAsFixed(4)}%');
    return r0;
  }
}
