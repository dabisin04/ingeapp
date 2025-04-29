import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_bloc.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_event.dart';

class MovementCardDialog extends StatefulWidget {
  final Movimiento? mov;
  const MovementCardDialog({Key? key, this.mov}) : super(key: key);

  @override
  _MovementCardDialogState createState() => _MovementCardDialogState();
}

class _MovementCardDialogState extends State<MovementCardDialog> {
  final _periodoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  String _tipo = 'Ingreso';

  @override
  void initState() {
    super.initState();
    if (widget.mov != null) {
      _periodoCtrl.text = widget.mov!.periodo?.toString() ?? '';

      // 🔥 Corregimos aquí:
      final val = widget.mov!.valor;
      if (val == null) {
        _valorCtrl.text = '';
      } else if (val is double) {
        _valorCtrl.text = val.toStringAsFixed(2); // formato bonito
      } else if (val is String) {
        _valorCtrl.text = val; // literal como está
      }

      _tipo = widget.mov!.tipo;
    }
  }

  void _onSave() {
    final periodoText = _periodoCtrl.text.trim();
    final valorText = _valorCtrl.text.trim();

    final int? periodo = periodoText.isEmpty ? null : int.tryParse(periodoText);

    dynamic valorFinal;
    if (valorText.isEmpty) {
      valorFinal = null;
    } else if (double.tryParse(valorText) != null) {
      valorFinal = double.parse(valorText);
    } else {
      valorFinal = valorText; // Guarda como string directamente
    }

    final nuevo = Movimiento(
      id: widget.mov?.id ?? DateTime.now().millisecondsSinceEpoch,
      periodo: periodo,
      valor: valorFinal,
      tipo: _tipo,
    );

    final bloc = context.read<MovimientoBloc>();
    if (widget.mov == null) {
      bloc.add(AgregarMovimiento(nuevo));
    } else {
      bloc.add(EditarMovimiento(nuevo));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.mov == null ? 'Añadir Movimiento' : 'Editar Movimiento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _tipo,
            items: ['Ingreso', 'Egreso']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            decoration: const InputDecoration(labelText: 'Tipo'),
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _periodoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Periodo (opcional)',
              hintText: 'Déjalo vacío si no aplica',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valorCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor (\$)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
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
