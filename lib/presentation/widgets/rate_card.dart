import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_event.dart';
import 'rate_card_dialog.dart';

class RateCard extends StatelessWidget {
  final TasaDeInteres tasa;
  const RateCard({Key? key, required this.tasa}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determina si es anticipada según el campo 'tipo'
    final esAnticipada = tasa.tipo.toLowerCase() == 'anticipada';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        // Título con el valor (%) y abreviatura de tipo
        title: Text(
          '${tasa.valor.toStringAsFixed(2)}% (${esAnticipada ? "Ant." : "Ven."})',
        ),
        // Subtítulo con periodos y descripción de unidades
        subtitle: Text(
          'Período: ${tasa.periodoInicio} → ${tasa.periodoFin}\n'
          'Periodicidad: ${tasa.periodicidad.nombre}, '
          'Capitalización: ${tasa.capitalizacion.nombre}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón de edición
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed:
                  () => showDialog(
                    context: context,
                    builder: (_) => RateCardDialog(tasa: tasa),
                  ),
            ),
            // Botón de eliminación
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                context.read<TasaInteresBloc>().add(
                  EliminarTasaInteres(tasa.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
