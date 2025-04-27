// lib/infrastructure/utils/financial_analysis.dart
import 'package:collection/collection.dart'; // ← NUEVO
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/infrastructure/utils/financial_utils.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

/// Rama «n»  (hay ≥ 1 tasa **y** un flujo con `periodo == null`)
class FinancialAnalysis {
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];

    /* ───── Validación ───────────────────────────────────────── */
    final hasRates = d.tasasDeInteres.isNotEmpty;
    final hasUnknownPeriod = d.movimientos.any((m) => m.periodo == null) ||
        d.valores.any((v) => v.periodo == null);

    if (!hasRates || !hasUnknownPeriod) {
      throw StateError('Condición no soportada para análisis-n');
    }

    /* ───── Normalizar tasas a periódica-vencida en la unidad del diagrama ─ */
    final List<TasaDeInteres> tasasOk = d.tasasDeInteres.map((t) {
      final yaOk = t.periodicidad.id == d.unidadDeTiempo.id &&
          t.capitalizacion.id == d.unidadDeTiempo.id &&
          t.tipo.toLowerCase() == 'vencida';

      if (yaOk) return t;

      final rate = RateConversionUtils.periodicRateForDiagram(
        tasa: t,
        unidadObjetivo: d.unidadDeTiempo,
      );

      return TasaDeInteres(
        id: t.id,
        valor: rate,
        periodicidad: d.unidadDeTiempo,
        capitalizacion: d.unidadDeTiempo,
        tipo: 'Vencida',
        periodoInicio: t.periodoInicio,
        periodoFin: t.periodoFin,
      );
    }).toList();

    steps.add('→ Calcular n con tasas normalizadas');
    for (final t in tasasOk) {
      steps.add(
        'Tramo ${t.periodoInicio}-${t.periodoFin}: '
        '${(t.valor * 100).toStringAsFixed(4)} % '
        '(${d.unidadDeTiempo.nombre}, vencida)',
      );
    }

    /* ───── 1) Valor presente de los flujos fechados ──────────── */
    double pv = 0.0;

    double _pv(double monto, int p, bool ingreso) {
      final df = PeriodUtils.discountFactorPiecewise(tasasOk, p);
      final contrib = (ingreso ? 1 : -1) * monto * df;
      steps.add(
        '${ingreso ? "Ingreso" : "Egreso"} \$${monto.toStringAsFixed(2)} '
        'en t=$p • DF=${df.toStringAsFixed(6)} '
        '→ PV=${contrib.toStringAsFixed(2)}',
      );
      return contrib;
    }

    for (final m in d.movimientos) {
      if (m.periodo != null && m.valor != null) {
        pv += _pv(m.valor!, m.periodo!, m.tipo == 'Ingreso');
      }
    }
    for (final v in d.valores) {
      if (v.periodo != null && v.valor != null) {
        pv += _pv(v.valor!, v.periodo!, v.flujo == 'Ingreso');
      }
    }
    steps.add('Sumatoria PV = ${pv.toStringAsFixed(2)}');

    /* ───── 2) Flujo objetivo (periodo == null) ───────────────── */
    final Movimiento? movNull =
        d.movimientos.firstWhereOrNull((m) => m.periodo == null);
    final Valor? valNull = movNull == null
        ? d.valores.firstWhereOrNull((v) => v.periodo == null)
        : null;

    // ya sabemos que uno de los dos existe
    final double fvRaw = (movNull?.valor ?? valNull!.valor)! *
        (movNull != null
            ? (movNull.tipo == 'Ingreso' ? 1 : -1)
            : (valNull!.flujo == 'Ingreso' ? 1 : -1));

    // Si PV y FV difieren de signo → usamos |PV|, |FV|
    final signosOpuestos = pv * fvRaw < 0;
    final pvAbs = signosOpuestos ? pv.abs() : pv;
    final fv = signosOpuestos ? fvRaw.abs() : fvRaw;

    steps.add(
      signosOpuestos
          ? '⚠️  PV y FV tienen signos opuestos; se usan |PV| = '
              '\$${pvAbs.toStringAsFixed(2)}, |FV| = \$${fv.toStringAsFixed(2)}'
          : 'Flujo objetivo (FV): ${movNull != null ? "Movimiento" : "Valor"} '
              'de \$${fv.toStringAsFixed(2)}',
    );

    /* ───── 3) Despejar n con la última tasa ──────────────────── */
    final lastRate = tasasOk.last.valor;
    final eq =
        '${pvAbs.toStringAsFixed(2)}*(1+${lastRate.toStringAsFixed(4)})^n '
        '= ${fv.toStringAsFixed(2)}';
    steps.add('Ecuación: $eq');

    final n = PeriodUtils.solvePeriodsForFutureValue(
      presentValue: pvAbs,
      futureValue: fv,
      rate: lastRate,
    );
    steps.add('n = ln(FV/PV) / ln(1+i) = ${n.toStringAsFixed(4)} periodos');

    return EquationAnalysis(equation: eq, steps: steps, solution: n);
  }
}
