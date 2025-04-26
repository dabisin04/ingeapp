// lib/presentation/widgets/value_card_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/valor/valor_state.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/application/blocs/valor/valor_bloc.dart';
import 'package:inge_app/application/blocs/valor/valor_event.dart';

class ValueCardDialog extends StatefulWidget {
  final Valor? valor;
  const ValueCardDialog({Key? key, this.valor}) : super(key: key);

  @override
  _ValueCardDialogState createState() => _ValueCardDialogState();
}

class _ValueCardDialogState extends State<ValueCardDialog> {
  late TextEditingController _periodoCtrl;
  late TextEditingController _valorCtrl;
  String? _tipo;
  String _flujo = 'Ingreso';

  @override
  void initState() {
    super.initState();
    _periodoCtrl = TextEditingController(
      text: widget.valor?.periodo?.toString() ?? '', // usa ?.toString()
    );
    _valorCtrl = TextEditingController(
      text: widget.valor?.valor?.toString() ?? '',
    );
    _tipo = widget.valor?.tipo;
    _flujo = widget.valor?.flujo ?? 'Ingreso';
  }

  @override
  void dispose() {
    _periodoCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    final int? periodo = int.tryParse(_periodoCtrl.text.trim());
    final double? valorNum = double.tryParse(_valorCtrl.text.trim());

    if (_tipo == null) return; // tipo sigue siendo requerido

    final nueva = Valor(
      valor: valorNum,
      periodo: periodo, // puede quedar null
      tipo: _tipo!,
      flujo: _flujo,
    );

    final bloc = context.read<ValorBloc>();
    if (widget.valor == null) {
      bloc.add(AgregarValorEvent(nueva));
    } else {
      bloc.add(EditarValorEvent(nueva));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ValorBloc>().state;
    List<String> tiposDisponibles = ['Presente', 'Futuro'];
    if (state is ValorLoaded) {
      final usados = state.valores.map((v) => v.tipo).toSet();
      tiposDisponibles =
          tiposDisponibles.where((t) => !usados.contains(t)).toList();
      if (widget.valor != null &&
          !tiposDisponibles.contains(widget.valor!.tipo)) {
        tiposDisponibles.insert(0, widget.valor!.tipo);
      }
    }

    if (tiposDisponibles.isEmpty) {
      return AlertDialog(
        title: const Text('No hay tipos disponibles'),
        content: const Text(
          'Ya existe un valor Presente y un valor Futuro.\n'
          'Borra uno antes de añadir otro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    final tipoSeleccionado = (_tipo != null && tiposDisponibles.contains(_tipo))
        ? _tipo!
        : tiposDisponibles.first;
    _tipo = tipoSeleccionado;

    return AlertDialog(
      title: Text(widget.valor == null ? 'Añadir Valor' : 'Editar Valor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _periodoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Periodo (opcional)',
                hintText: 'Déjalo vacío si no aplica',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: tipoSeleccionado,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: tiposDisponibles
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _flujo,
              decoration: const InputDecoration(labelText: 'Flujo'),
              items: ['Ingreso', 'Egreso']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _flujo = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
