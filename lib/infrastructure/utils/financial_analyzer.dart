import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';

import 'financial_analysis.dart';
import 'financial_analysis_irr.dart';

class FinancialAnalyzer {
  static String branch(DiagramaDeFlujo d) {
    final hasRates = d.tasasDeInteres.isNotEmpty;
    final hasFocal = d.periodoFocal != null;

    if (hasRates && hasFocal) return 'IRR con periodo focal';
    if (hasRates && !hasFocal) return 'Periodos (n)';
    return 'IRR simple';
  }

  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final hasRates = d.tasasDeInteres.isNotEmpty;
    final hasFocal = d.periodoFocal != null;
    print('FinancialAnalyzer → hasRates=$hasRates, hasFocal=$hasFocal');

    // Rama “n”
    if (hasRates && !hasFocal) {
      return FinancialAnalysis.analyze(d);
    }

    // Ambas variantes IRR (con o sin periodo focal)
    return FinancialAnalysisIRR.analyze(d);
  }
}
