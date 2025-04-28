import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_bloc.dart';
import 'package:inge_app/application/blocs/movimiento/movimiento_event.dart';
import 'package:inge_app/presentation/widgets/movement_card_dialog.dart';

class MovementCard extends StatelessWidget {
  final Movimiento mov;
  const MovementCard({Key? key, required this.mov}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final valorTexto = mov.valor == null
        ? '—'
        : (mov.valor is double
            ? '\$${(mov.valor as double).toStringAsFixed(2)}'
            : mov.valor.toString()); // si es String, mostrar tal cual

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          mov.tipo == 'Ingreso' ? Icons.arrow_downward : Icons.arrow_upward,
          color: mov.tipo == 'Ingreso' ? Colors.red : Colors.green,
        ),
        title: Text('${mov.tipo} — Periodo ${mov.periodo ?? "—"}'),
        subtitle: Text(valorTexto),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => MovementCardDialog(mov: mov),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                context.read<MovimientoBloc>().add(EliminarMovimiento(mov));
              },
            ),
          ],
        ),
      ),
    );
  }
}
