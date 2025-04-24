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
    // Calculamos el texto del valor de forma segura
    final valorTexto =
        mov.valor != null ? '\$${mov.valor!.toStringAsFixed(2)}' : '—';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          mov.tipo == 'Ingreso' ? Icons.arrow_upward : Icons.arrow_downward,
          color: mov.tipo == 'Ingreso' ? Colors.green : Colors.red,
        ),
        title: Text('${mov.tipo} — Periodo ${mov.periodo}'),
        subtitle: Text(valorTexto),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed:
                  () => showDialog(
                    context: context,
                    builder: (_) => MovementCardDialog(mov: mov),
                  ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
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
