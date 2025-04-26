import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/infrastructure/utils/financial_utils.dart';

class FinancialAnalysis {
  /// Resolución de n con tasa fija, detectando movimiento o valor
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];

    print('DEBUG: Analyzing Diagram id=${d.id}, focal=${d.periodoFocal}');
    steps.add(
        'Datos: periodoFocal=${d.periodoFocal}, tasas=${d.tasasDeInteres.length}, '
        'movimientos=${d.movimientos.length}, valores=${d.valores.length}');

    // Solo entra aquí si no hay focal y sí hay al menos una tasa
    if (d.periodoFocal == null && d.tasasDeInteres.isNotEmpty) {
      steps.add('→ Calcular número de periodos n');

      final rate = d.tasasDeInteres.single.valor;
      steps.add('Tasa periódica: ${(rate * 100).toStringAsFixed(2)}%');

      // 1) calcular PV de TODOS los flujos CON periodo definido
      double pv = 0.0;
      for (var m in d.movimientos.where((m) => m.periodo != null)) {
        final t = m.periodo!;
        final c = m.valor! * PeriodUtils.discountFactor(rate, t);
        final sign = m.tipo == 'Ingreso' ? 1 : -1;
        pv += sign * c;
        steps.add(
          'Movimiento ${m.tipo} \$${m.valor} en t=$t → PV contrib = '
          '${(sign * c).toStringAsFixed(2)}',
        );
      }
      for (var v in d.valores.where((v) => v.periodo != null)) {
        final t = v.periodo!;
        final c = v.valor! * PeriodUtils.discountFactor(rate, t);
        // aquí asumimos que "tipo" enumúa Ingreso/Egreso
        final sign = v.flujo == 'Ingreso' ? 1 : -1;
        pv += sign * c;
        steps.add(
          'Valor ${v.tipo} \$${v.valor} en t=$t → PV contrib = '
          '${(sign * c).toStringAsFixed(2)}',
        );
      }
      steps.add('Sumatoria de PV = ${pv.toStringAsFixed(2)}');

      // 2) localizar el flujo objetivo (FV) con periodo == null
      final movNulls = d.movimientos.where((m) => m.periodo == null).toList();
      final valNulls = d.valores.where((v) => v.periodo == null).toList();

      if (movNulls.isEmpty && valNulls.isEmpty) {
        throw StateError('No hay ningún movimiento ni valor con periodo=null');
      }

      // si hay movimiento nulo, lo tomamos; si no, tomamos valor nulo
      final Movimiento? mTarget = movNulls.isNotEmpty ? movNulls.first : null;
      final Valor? vTarget = mTarget == null ? valNulls.first : null;

      final double fv = (mTarget?.valor ?? vTarget!.valor)!;
      final String fuente = mTarget != null ? 'Movimiento' : 'Valor';
      steps.add('Flujo objetivo (FV): $fuente de \$${fv.toStringAsFixed(2)}');

      // 3) armar ecuación PV*(1+rate)^n = FV
      final eq = '${pv.toStringAsFixed(2)}*(1+${rate.toStringAsFixed(4)})^n = '
          '${fv.toStringAsFixed(2)}';
      steps.add('Ecuación períodos: $eq');

      // 4) despejar n
      final n = PeriodUtils.solvePeriodsForFutureValue(
        presentValue: pv,
        futureValue: fv,
        rate: rate,
      );
      steps.add(
        'n = ln(${fv.toStringAsFixed(2)}/${pv.toStringAsFixed(2)}) '
        '/ ln(${(1 + rate).toStringAsFixed(4)}) = ${n.toStringAsFixed(2)}',
      );

      return EquationAnalysis(equation: eq, steps: steps, solution: n);
    }
    throw StateError('Condición no soportada para análisis');
  }
}
