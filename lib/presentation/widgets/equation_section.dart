import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_event.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_state.dart';
import 'package:inge_app/infrastructure/utils/financial_analyzer.dart';

class AnalysisSection extends StatelessWidget {
  const AnalysisSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlowDiagramBloc, FlowDiagramState>(
      builder: (context, state) {
        String? branch;
        if (state is FlowDiagramLoaded) {
          branch = FinancialAnalyzer.branch(state.diagrama);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (branch != null) ...[
              Text('Rama a usar: $branch',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
            ],

            /// pedimos el análisis al BLoC
            ElevatedButton(
              onPressed: () =>
                  context.read<FlowDiagramBloc>().add(AnalyzeDiagramEvent()),
              child: const Text('Analizar Proceso'),
            ),
            const SizedBox(height: 12),

            if (state is AnalysisInProgress)
              const Center(child: CircularProgressIndicator()),

            if (state is AnalysisFailure)
              Text('Error: ${state.error}',
                  style: const TextStyle(color: Colors.red)),

            if (state is AnalysisSuccess) ...[
              // ecuación
              Math.tex(r'\text{' + state.analysis.equation + '}',
                  textStyle: const TextStyle(fontSize: 16)),
              const Divider(height: 24),
              const Text('Pasos:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...state.analysis.steps.map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $s', style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 12),

              // ‹i› o ‹n› según corresponda
              Builder(
                builder: (_) {
                  final eq = state.analysis.equation;
                  final isN = eq.contains(
                      '^n'); // si la ecuación tiene ^n → rama de períodos
                  return Text(
                    isN
                        ? 'Solución: n = ${state.analysis.solution.toStringAsFixed(2)} periodos'
                        : (state.analysis.equation.contains('(1+i)')
                            ? 'Solución: i = ${(state.analysis.solution * 100).toStringAsFixed(4)}%'
                            : 'Solución: X = \$${state.analysis.solution.toStringAsFixed(2)}'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
