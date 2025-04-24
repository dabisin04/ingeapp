import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_bloc.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_event.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_state.dart';

class UnitDropdownWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnidadDeTiempoBloc, UnidadDeTiempoState>(
      builder: (_, state) {
        if (state is UnidadDeTiempoLoaded) {
          return DropdownButtonFormField(
            decoration: InputDecoration(
              labelText: 'Unidad de Tiempo',
              border: OutlineInputBorder(),
            ),
            items:
                state.unidades
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text('${u.nombre} (${u.valor})'),
                      ),
                    )
                    .toList(),
            value: state.seleccionada,
            onChanged: (e) {
              if (e != null) {
                context.read<UnidadDeTiempoBloc>().add(
                  SeleccionarUnidadDeTiempo(unidad: e),
                );
              }
            },
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
