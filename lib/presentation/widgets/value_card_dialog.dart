import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  String _tipo = 'Presente';

  @override
  void initState() {
    super.initState();
    _periodoCtrl = TextEditingController(
      text: widget.valor?.periodo.toString() ?? '',
    );
    _valorCtrl = TextEditingController(
      text: widget.valor?.valor.toString() ?? '',
    );
    _tipo = widget.valor?.tipo ?? 'Presente';
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
    final bloc = context.read<ValorBloc>();

    if (widget.valor == null) {
      // Añadir
      bloc.add(
        AgregarValorEvent(
          Valor(valor: valorNum, periodo: periodo, tipo: _tipo),
        ),
      );
    } else {
      // Editar
      bloc.add(
        EditarValorEvent(Valor(valor: valorNum, periodo: periodo, tipo: _tipo)),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.valor == null ? 'Añadir Valor' : 'Editar Valor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            DropdownButtonFormField<String>(
              value: _tipo,
              items:
                  ['Presente', 'Futuro']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
              onChanged: (v) => setState(() => _tipo = v!),
              decoration: InputDecoration(labelText: 'Tipo'),
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
