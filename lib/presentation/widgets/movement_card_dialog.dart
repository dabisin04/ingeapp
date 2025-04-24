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
      _periodoCtrl.text = widget.mov!.periodo.toString();
      _valorCtrl.text = widget.mov!.valor.toString();
      _tipo = widget.mov!.tipo;
    }
  }

  @override
  void dispose() {
    _periodoCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    final periodo = int.tryParse(_periodoCtrl.text);
    final valorNum = double.tryParse(_valorCtrl.text);
    if (periodo == null || valorNum == null) return;

    final bloc = BlocProvider.of<MovimientoBloc>(context);
    final nuevo = Movimiento(
      id: widget.mov?.id ?? DateTime.now().millisecondsSinceEpoch,
      periodo: periodo,
      valor: valorNum,
      tipo: _tipo,
    );
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
      title: Text(
        widget.mov == null ? 'Añadir Movimiento' : 'Editar Movimiento',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _tipo,
              items:
                  ['Ingreso', 'Egreso']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
              onChanged: (v) => setState(() => _tipo = v!),
              decoration: InputDecoration(labelText: 'Tipo'),
            ),
            TextField(
              controller: _periodoCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Periodo'),
            ),
            TextField(
              controller: _valorCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Valor (\$)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _onSave, child: Text('Guardar')),
      ],
    );
  }
}
