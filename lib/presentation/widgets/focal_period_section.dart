import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_event.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_state.dart';

class FocalPeriodSection extends StatefulWidget {
  const FocalPeriodSection({Key? key}) : super(key: key);
  @override
  State<FocalPeriodSection> createState() => _FocalPeriodSectionState();
}

class _FocalPeriodSectionState extends State<FocalPeriodSection> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlowDiagramBloc, FlowDiagramState>(
      buildWhen: (prev, cur) => cur is FlowDiagramLoaded,
      builder: (context, state) {
        // periodFocal ahora es int? y empieza null
        final int? currentFocal =
            (state is FlowDiagramLoaded) ? state.diagrama.periodoFocal : null;
        // Si es null, dejamos el campo vacío
        _ctrl.text = currentFocal?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Periodo Focal (opcional)',
                      border: OutlineInputBorder(),
                      hintText: 'Deja vacío para resolver n',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final txt = _ctrl.text.trim();
                    // Si el campo está vacío → val = null
                    final int? val = txt.isEmpty ? null : int.tryParse(txt);
                    // Disparar con int? en lugar de forzar a int
                    context
                        .read<FlowDiagramBloc>()
                        .add(UpdateFocalPeriodEvent(val));
                  },
                  child: const Text('Fijar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
