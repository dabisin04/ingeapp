import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/infrastructure/utils/irr_utils.dart';

class FinancialAnalysisIRR {
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[], terms = <String>[];
    final focal = d.periodoFocal ?? 0;

    // IRR con focal definido
    if (d.periodoFocal != null && d.tasasDeInteres.isNotEmpty) {
      steps.add('→ Calcular IRR trasladando flujos a t=$focal');
      final movs = d.movimientos.where((m) => m.periodo != null).toList();
      final vals = d.valores.where((v) => v.periodo != null).toList();

      for (var m in movs) {
        final n = m.periodo! - focal;
        terms.add('${m.valor!.toStringAsFixed(2)}*(1+i)^${n.abs()}');
      }
      for (var v in vals) {
        final n = v.periodo! - focal;
        terms.add('${v.valor!.toStringAsFixed(2)}*(1+i)^${n.abs()}');
      }
      final eq = '${terms.join(' + ')} = 0';
      steps.add('Ecuación IRR t=$focal: $eq');

      final rate = IRRUtils.solveRateSimple(
        movimientos: movs,
        valores: vals,
        focalPeriod: focal,
        step: 0.0001,
        steps: steps,
      );
      steps.add('IRR → i ≈ ${(rate * 100).toStringAsFixed(4)}%');

      return EquationAnalysis(equation: eq, steps: steps, solution: rate);
    }

    steps.add('→ Calcular IRR simple trasladando a t=0');
    final movs = d.movimientos.where((m) => m.periodo != null).toList();
    final vals = d.valores.where((v) => v.periodo != null).toList();
    for (var m in movs) {
      terms.add('${m.valor!.toStringAsFixed(2)}*(1+i)^${m.periodo!}');
    }
    for (var v in vals) {
      terms.add('${v.valor!.toStringAsFixed(2)}*(1+i)^${v.periodo!}');
    }
    final eq = '${terms.join(' + ')} = 0';
    steps.add('Ecuación IRR t=0: $eq');

    final rate = IRRUtils.solveRateSimple(
      movimientos: movs,
      valores: vals,
      focalPeriod: 0,
      step: 0.0001,
      steps: steps,
    );
    steps.add('IRR → i ≈ ${(rate * 100).toStringAsFixed(4)}%');

    return EquationAnalysis(equation: eq, steps: steps, solution: rate);
  }
}
