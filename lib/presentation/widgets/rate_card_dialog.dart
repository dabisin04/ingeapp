import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_event.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

class RateCardDialog extends StatefulWidget {
  final TasaDeInteres? tasa;
  const RateCardDialog({Key? key, this.tasa}) : super(key: key);

  @override
  _RateCardDialogState createState() => _RateCardDialogState();
}

class _RateCardDialogState extends State<RateCardDialog> {
  final _valorCtrl = TextEditingController();
  final _iniCtrl = TextEditingController();
  final _finCtrl = TextEditingController();

  // Para almacenar sólo el id de la unidad
  int _periodicidadId = 1;
  int _capitalizacionId = 1;
  bool _isAnticipada = false;

  @override
  void initState() {
    super.initState();
    if (widget.tasa != null) {
      // valor numérico
      _valorCtrl.text = widget.tasa!.valor.toString();
      // periodos
      _iniCtrl.text = widget.tasa!.periodoInicio.toString();
      _finCtrl.text = widget.tasa!.periodoFin.toString();
      // ids de unidad de tiempo
      _periodicidadId = widget.tasa!.periodicidad.id;
      _capitalizacionId = widget.tasa!.capitalizacion.id;
      // tipo
      _isAnticipada = widget.tasa!.tipo.toLowerCase() == 'anticipada';
    }
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _iniCtrl.dispose();
    _finCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    final p = double.tryParse(_valorCtrl.text);
    final i = int.tryParse(_iniCtrl.text);
    final f = int.tryParse(_finCtrl.text);
    if (p == null || i == null || f == null) return;

    // Construye instancias de UnidadDeTiempo únicamente con el ID.
    // Idealmente aquí deberías recuperar el objeto completo desde tu UnidadDeTiempoBloc
    final periodicidad = UnidadDeTiempo(
      id: _periodicidadId,
      nombre: '',
      valor: 0,
    );
    final capitalizacion = UnidadDeTiempo(
      id: _capitalizacionId,
      nombre: '',
      valor: 0,
    );
    final tipoStr = _isAnticipada ? 'Anticipada' : 'Vencida';

    final nueva = TasaDeInteres(
      id: widget.tasa?.id ?? DateTime.now().millisecondsSinceEpoch,
      valor: p,
      periodicidad: periodicidad,
      capitalizacion: capitalizacion,
      tipo: tipoStr,
      periodoInicio: i,
      periodoFin: f,
    );

    final bloc = context.read<TasaInteresBloc>();
    if (widget.tasa == null) {
      bloc.add(AgregarTasaInteres(nueva));
    } else {
      bloc.add(EditarTasaInteres(nueva.id, nueva));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Lista estática de ids válidos; idealmente iría de tu UnidadDeTiempoBloc
    const unidadesIds = [1, 2, 3, 4, 6, 12, 26, 52, 360];

    return AlertDialog(
      title: Text(widget.tasa == null ? 'Añadir Tasa' : 'Editar Tasa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _valorCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Valor (%)'),
            ),
            TextField(
              controller: _iniCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Periodo Inicio'),
            ),
            TextField(
              controller: _finCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Periodo Fin'),
            ),
            DropdownButtonFormField<int>(
              value: _periodicidadId,
              items:
                  unidadesIds
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
              onChanged: (v) => setState(() => _periodicidadId = v!),
              decoration: InputDecoration(labelText: 'Periodicidad (ID)'),
            ),
            DropdownButtonFormField<int>(
              value: _capitalizacionId,
              items:
                  unidadesIds
                      .where((v) => v <= _periodicidadId)
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
              onChanged: (v) => setState(() => _capitalizacionId = v!),
              decoration: InputDecoration(labelText: 'Capitalización (ID)'),
            ),
            SwitchListTile(
              title: Text('Anticipada'),
              value: _isAnticipada,
              onChanged: (v) => setState(() => _isAnticipada = v),
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
