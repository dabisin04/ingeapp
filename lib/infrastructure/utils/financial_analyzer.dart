// lib/infrastructure/utils/financial_analyzer.dart
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';

import 'financial_analysis.dart';
import 'financial_analysis_irr.dart';

class FinancialAnalyzer {
  // --- Qué rama se utilizará  ------------------------------------------------
  static String branch(DiagramaDeFlujo d) {
    final hasRates = d.tasasDeInteres.isNotEmpty;
    final hasUnknownPeriod = d.movimientos.any((m) => m.periodo == null) ||
        d.valores.any((v) => v.periodo == null);

    if (hasRates && hasUnknownPeriod) return 'Periodos (n)';
    if (hasRates) return 'IRR con periodo focal';
    return 'IRR simple';
  }

  // --- Ejecución -------------------------------------------------------------
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final hasRates = d.tasasDeInteres.isNotEmpty;
    final hasUnknownPeriod = d.movimientos.any((m) => m.periodo == null) ||
        d.valores.any((v) => v.periodo == null);

    // Rama “n”
    if (hasRates && hasUnknownPeriod) {
      return FinancialAnalysis.analyze(d);
    }

    // Ambas variantes IRR (con/sin periodo focal)
    return FinancialAnalysisIRR.analyze(d);
  }
}
