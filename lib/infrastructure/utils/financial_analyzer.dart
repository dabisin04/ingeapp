import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';

import 'financial_analysis.dart';
import 'financial_analysis_pvfv.dart';
import 'financial_analysis_irr.dart';
import 'financial_analysis_unknown.dart'; // ← Asegúrate de importar esto también

class FinancialAnalyzer {
  /* ────────────────── Función de Debug ─────────────────────── */

  static void debugPrintDiagramaDeFlujo(DiagramaDeFlujo d) {
    print('═════════════════════════════════════════════════════════');
    print('📋 Diagrama recibido:');
    print('Unidad de Tiempo: ${d.unidadDeTiempo.nombre}');
    print('Cantidad de Periodos: ${d.cantidadDePeriodos}');
    print('Periodo Focal: ${d.periodoFocal}');
    print('── Tasas de Interés ──');
    for (final t in d.tasasDeInteres) {
      print('• Desde ${t.periodoInicio} hasta ${t.periodoFin} => '
          'Valor: ${(t.valor * 100).toStringAsFixed(6)}% '
          '(Tipo: ${t.tipo}, Aplica: ${t.aplicaA}) '
          '[Periodicidad: ${t.periodicidad.nombre}, Capitalización: ${t.capitalizacion.nombre}]');
    }
    print('── Valores ──');
    for (final v in d.valores) {
      print('• Tipo: ${v.tipo}, Flujo: ${v.flujo}, '
          'Periodo: ${v.periodo?.toString() ?? "null"}, '
          'Valor: ${v.valor}');
    }
    print('── Movimientos ──');
    for (final m in d.movimientos) {
      print('• Tipo: ${m.tipo}, '
          'Periodo: ${m.periodo?.toString() ?? "null"}, '
          'Valor: ${m.valor}');
    }
    print('═════════════════════════════════════════════════════════');
  }

  /* ────────────────── Selección de rama ─────────────────────── */

  static String branch(DiagramaDeFlujo d) {
    final bool hasRates = d.tasasDeInteres.isNotEmpty;

    final bool anyMovOrValWithNullPeriodAndNotNullValue =
        d.movimientos.any((m) => m.periodo == null && m.valor != null) ||
            d.valores.any((v) => v.periodo == null && v.valor != null);

    final valoresConValorNull =
        d.valores.where((v) => v.valor == null).toList();

    final bool hasUnknownValue = d.movimientos.any((m) => m.valor is String) ||
        d.valores.any((v) => v.valor is String);

    if (hasRates && hasUnknownValue) {
      return 'Valor desconocido (X)';
    }
    if (hasRates && anyMovOrValWithNullPeriodAndNotNullValue) {
      return 'Periodos (n)';
    }
    if (hasRates && valoresConValorNull.length == 1) {
      return 'VP / VF';
    }
    if (hasRates) {
      return 'IRR con periodo focal';
    }
    return 'IRR simple';
  }

  /* ──────────────────── Ejecución de análisis ────────────────── */

  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    // <<< 🔥 DEBUG
    debugPrintDiagramaDeFlujo(d);

    final bool hasRates = d.tasasDeInteres.isNotEmpty;

    final bool anyMovOrValWithNullPeriodAndNotNullValue =
        d.movimientos.any((m) => m.periodo == null && m.valor != null) ||
            d.valores.any((v) => v.periodo == null && v.valor != null);

    final valoresConValorNull =
        d.valores.where((v) => v.valor == null).toList();

    final bool hasUnknownValue = d.movimientos.any((m) => m.valor is String) ||
        d.valores.any((v) => v.valor is String);

    if (hasRates && hasUnknownValue) {
      return FinancialAnalysisUnknown.analyze(d);
    }
    if (hasRates && anyMovOrValWithNullPeriodAndNotNullValue) {
      return FinancialAnalysis.analyze(d);
    }
    if (hasRates && valoresConValorNull.length == 1) {
      return FinancialAnalysisPVFV.analyze(d);
    }
    return FinancialAnalysisIRR.analyze(d);
  }
}
