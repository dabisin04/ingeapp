import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_event.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/repositories/unidad_de_tiempo_repository.dart';

class RateCardDialog extends StatefulWidget {
  final TasaDeInteres? tasa;
  final UnidadDeTiempoRepository unidadDeTiempoRepository;

  const RateCardDialog({
    Key? key,
    this.tasa,
    required this.unidadDeTiempoRepository,
  }) : super(key: key);

  @override
  _RateCardDialogState createState() => _RateCardDialogState();
}

class _RateCardDialogState extends State<RateCardDialog> {
  final _valorCtrl = TextEditingController();
  final _iniCtrl = TextEditingController();
  final _finCtrl = TextEditingController();

  int _periodicidadId = 1;
  int _capitalizacionId = 1;
  bool _isAnticipada = false;

  List<UnidadDeTiempo> _unidadesDeTiempo = [];

  @override
  void initState() {
    super.initState();
    _loadUnidadesDeTiempo();
    if (widget.tasa != null) {
      _valorCtrl.text = widget.tasa!.valor.toString();
      _iniCtrl.text = widget.tasa!.periodoInicio.toString();
      _finCtrl.text = widget.tasa!.periodoFin.toString();
      _periodicidadId = widget.tasa!.periodicidad.id;
      _capitalizacionId = widget.tasa!.capitalizacion.id;
      _isAnticipada = widget.tasa!.tipo.toLowerCase() == 'anticipada';
    }
  }

  Future<void> _loadUnidadesDeTiempo() async {
    _unidadesDeTiempo =
        await widget.unidadDeTiempoRepository.obtenerUnidadesDeTiempo();
    setState(() {});
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

    final periodicidad = _unidadesDeTiempo.firstWhere(
      (u) => u.id == _periodicidadId,
    );
    final capitalizacion = _unidadesDeTiempo.firstWhere(
      (u) => u.id == _capitalizacionId,
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
    if (_unidadesDeTiempo.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final unidadPeriodicidad = _unidadesDeTiempo.firstWhere(
      (u) => u.id == _periodicidadId,
    );
    final capitalizables =
        _unidadesDeTiempo
            .where((u) => u.valor >= unidadPeriodicidad.valor)
            .toList();

    return AlertDialog(
      title: Text(widget.tasa == null ? 'Añadir Tasa' : 'Editar Tasa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Valor (%)'),
            ),
            TextField(
              controller: _iniCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Periodo Inicio'),
            ),
            TextField(
              controller: _finCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Periodo Fin'),
            ),
            DropdownButtonFormField<int>(
              value: _periodicidadId,
              items:
                  _unidadesDeTiempo
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.nombre),
                        ),
                      )
                      .toList(),
              onChanged:
                  (v) => setState(() {
                    _periodicidadId = v!;
                    final nuevaPer = _unidadesDeTiempo.firstWhere(
                      (u) => u.id == _periodicidadId,
                    );
                    final nuevaCaps =
                        _unidadesDeTiempo
                            .where((u) => u.valor >= nuevaPer.valor)
                            .toList();
                    if (!nuevaCaps.any((c) => c.id == _capitalizacionId)) {
                      _capitalizacionId = nuevaCaps.first.id;
                    }
                  }),
              decoration: const InputDecoration(labelText: 'Periodicidad'),
            ),
            DropdownButtonFormField<int>(
              value: _capitalizacionId,
              items:
                  capitalizables
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.nombre),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _capitalizacionId = v!),
              decoration: const InputDecoration(labelText: 'Capitalización'),
            ),
            SwitchListTile(
              title: const Text('Anticipada'),
              value: _isAnticipada,
              onChanged: (v) => setState(() => _isAnticipada = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _onSave, child: const Text('Guardar')),
      ],
    );
  }
}
