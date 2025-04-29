// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:math';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

class FinancialAnalysisPVFV {
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];

    /* ── 1) Validaciones ─────────────────────────────────────── */
    if (d.tasasDeInteres.isEmpty) {
      throw StateError('Se necesita al menos una tasa de interés.');
    }

    // Buscamos exactamente una incógnita: valor nulo o "X"
    final valoresNull = d.valores.where((v) => v.valor == null).toList();
    final valoresX = d.valores
        .where((v) =>
            v.valor is String &&
            (v.valor as String).trim().toUpperCase() == 'X')
        .toList();

    if (valoresNull.length + valoresX.length != 1) {
      throw StateError(
        'Debe existir exactamente un Valor con valor=null o "X" como incógnita.',
      );
    }

    // Identificamos el elemento que contiene la incógnita
    final Valor valorIncognita =
        valoresNull.isNotEmpty ? valoresNull.single : valoresX.single;

    // El periodo focal será el indicado por el diagrama, o si no viene, el del PV/FV
    final int focal = d.periodoFocal ?? valorIncognita.periodo!;

    /* ── 2) Normalizar tasas a periódica-vencida ───────────────── */
    final tasasOk = d.tasasDeInteres.map((t) {
      final yaOk = t.periodicidad.id == d.unidadDeTiempo.id &&
          t.capitalizacion.id == d.unidadDeTiempo.id &&
          RateConversionUtils.normalizeTipo(t.tipo) == 'vencida';

      if (yaOk) return t;

      final nuevaRate = RateConversionUtils.periodicRateForDiagram(
        tasa: t,
        unidadObjetivo: d.unidadDeTiempo,
      );

      return TasaDeInteres(
        id: t.id,
        valor: nuevaRate,
        periodicidad: d.unidadDeTiempo,
        capitalizacion: d.unidadDeTiempo,
        tipo: 'Vencida',
        periodoInicio: t.periodoInicio,
        periodoFin: t.periodoFin,
        aplicaA: t.aplicaA,
      );
    }).toList();

    steps.add('Tasas normalizadas (% ${d.unidadDeTiempo.nombre}):');
    for (final t in tasasOk) {
      steps.add(
        ' • ${t.periodoInicio}-${t.periodoFin}: '
        '${(t.valor * 100).toStringAsFixed(6)}%, aplica a ${t.aplicaA}',
      );
    }

    /* ── 3) Trasladar flujos a la fecha focal ──────────────────── */
    double netInFocal = 0.0;

    // Busca la tasa efectiva en un periodo dado
    double _getRate(int periodo, String tipoFlujo) {
      final tipoNorm = RateConversionUtils.normalizeTipo(tipoFlujo);

      final tasasAplicables = tasasOk.where((t) {
        final inRango = periodo >= t.periodoInicio && periodo <= t.periodoFin;
        final aplica = RateConversionUtils.normalizeTipo(t.aplicaA);
        return inRango && (aplica == 'todos' || aplica == tipoNorm);
      }).toList();

      if (tasasAplicables.isEmpty) {
        throw StateError(
            '❌ No se encontró tasa aplicable para t=$periodo ($tipoFlujo)');
      }

      final sumaTasas =
          tasasAplicables.map((t) => t.valor).reduce((a, b) => a + b);

      steps.add(
        '🔎 Tasas en t=$periodo ($tipoFlujo): '
        '${tasasAplicables.map((t) => (t.valor * 100).toStringAsFixed(4)).join('% + ')} '
        '= ${(sumaTasas * 100).toStringAsFixed(4)}%',
      );

      return sumaTasas;
    }

    // Calcula el factor entre el flujo y el focal
    double _factor(int periodo, double tasa) {
      final n = (periodo - focal).abs();
      if (periodo > focal) {
        // flujo después de focal → descuento
        return 1 / pow(1 + tasa, n);
      } else if (periodo < focal) {
        // flujo antes del focal → capitalizar
        return pow(1 + tasa, n).toDouble();
      } else {
        return 1.0;
      }
    }

    // Procesamos movimientos (todos los movimientos DEBEN ser double)
    for (final m in d.movimientos) {
      if (m.periodo == null || m.valor == null) continue;
      if (m.valor is! double) {
        throw StateError('Movimientos deben tener valores numéricos dobles.');
      }
      final tasaAplicable = _getRate(m.periodo!, m.tipo);
      final ingreso = RateConversionUtils.normalizeTipo(m.tipo) == 'ingreso';
      final aporte = (ingreso ? 1 : -1) *
          (m.valor as double) *
          _factor(m.periodo!, tasaAplicable);

      steps.add(
        '${m.tipo} \$${(m.valor as double).toStringAsFixed(2)} '
        'en t=${m.periodo} → ${aporte.toStringAsFixed(6)} en t=$focal',
      );
      netInFocal += aporte;
    }

    // Procesamos valores conocidos (ignoramos el valorIncognita)
    for (final v in d.valores) {
      if (v == valorIncognita) continue;
      if (v.periodo == null || v.valor == null) continue;
      if (v.valor is! double) {
        throw StateError(
            'Valores deben ser numéricos dobles, excepto la incógnita.');
      }
      final tasaAplicable = _getRate(v.periodo!, v.flujo);
      final ingreso = RateConversionUtils.normalizeTipo(v.flujo) == 'ingreso';
      final aporte = (ingreso ? 1 : -1) *
          (v.valor as double) *
          _factor(v.periodo!, tasaAplicable);

      steps.add(
        '${v.flujo} \$${(v.valor as double).toStringAsFixed(2)} '
        'en t=${v.periodo} → ${aporte.toStringAsFixed(6)} en t=$focal',
      );
      netInFocal += aporte;
    }

    /* ── 4) Despeje del Valor faltante ────────────────────────── */
    final ingresoObjetivo =
        RateConversionUtils.normalizeTipo(valorIncognita.flujo) == 'ingreso';
    final signoObjetivo = ingresoObjetivo ? 1 : -1;

    // netInFocal + signoObjetivo * X = 0  =>  X = -netInFocal / signoObjetivo
    final double X = -netInFocal / signoObjetivo;

    steps.add(
      'Ecuación en t=$focal: ${netInFocal.toStringAsFixed(6)} '
      '${signoObjetivo == 1 ? '+' : '-'} X = 0',
    );
    steps.add('⇒ X = ${X.toStringAsFixed(6)}');

    return EquationAnalysis(
      equation: 'X = ${X.toStringAsFixed(6)}',
      steps: steps,
      solution: X,
    );
  }
}
