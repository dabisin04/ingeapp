import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_event.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_state.dart';

class DescriptionSection extends StatefulWidget {
  const DescriptionSection({super.key});

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // 1) Disparamos el evento para actualizar la descripción
    context.read<FlowDiagramBloc>().add(UpdateDescriptionEvent(text));
    // 2) Limpiamos el TextField
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Descripción del Diagrama',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Campo de texto para nueva descripción
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Escribe la descripción aquí...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),

            // Botón "Aceptar"
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Aceptar'),
              ),
            ),

            const Divider(height: 24),

            // Área de texto que sólo se reconstruye al recibir FlowDiagramLoaded
            BlocBuilder<FlowDiagramBloc, FlowDiagramState>(
              buildWhen: (previous, current) => current is FlowDiagramLoaded,
              builder: (context, state) {
                final currentDesc = state is FlowDiagramLoaded
                    ? state.diagrama.descripcion ?? ''
                    : '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción actual:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        currentDesc.isNotEmpty
                            ? currentDesc
                            : 'Aún no hay descripción.',
                        style: TextStyle(
                          fontStyle: currentDesc.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: currentDesc.isEmpty
                              ? Colors.grey[600]
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
