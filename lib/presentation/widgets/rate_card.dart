import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_bloc.dart';
import 'package:inge_app/application/blocs/tasa_de_interes/tasa_de_interes_event.dart';
import 'rate_card_dialog.dart';
import 'package:inge_app/domain/repositories/unidad_de_tiempo_repository.dart';

class RateCard extends StatelessWidget {
  final TasaDeInteres tasa;
  const RateCard({Key? key, required this.tasa}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final esAnticipada = tasa.tipo.toLowerCase() == 'anticipada';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          '${(tasa.valor * 100).toStringAsFixed(2)}% (${esAnticipada ? "Ant." : "Ven."})',
        ),
        subtitle: Text(
          'Período: ${tasa.periodoInicio} → ${tasa.periodoFin}\n'
          'Periodicidad: ${tasa.periodicidad.nombre}, '
          'Capitalización: ${tasa.capitalizacion.nombre}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                final unidadDeTiempoRepository =
                    context.read<UnidadDeTiempoRepository>();
                showDialog(
                  context: context,
                  builder:
                      (_) => RateCardDialog(
                        tasa: tasa,
                        unidadDeTiempoRepository: unidadDeTiempoRepository,
                      ),
                );
              },
            ),
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
