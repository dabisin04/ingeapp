import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_bloc.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_event.dart';
import 'package:inge_app/application/blocs/diagrama_de_flujo/diagrama_de_flujo_state.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_bloc.dart';
import 'package:inge_app/application/blocs/unidad_de_tiempo/unidad_de_tiempo_state.dart';
import 'package:inge_app/presentation/widgets/period_input_widget.dart';
import 'package:inge_app/presentation/widgets/unit_dropdown_widget.dart';
import 'package:inge_app/presentation/widgets/rates_section.dart';
import 'package:inge_app/presentation/widgets/values_section.dart';
import 'package:inge_app/presentation/widgets/movements_section.dart';
import 'package:inge_app/presentation/widgets/flow_diagram_widget.dart';

class FlowScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final flowBloc = context.read<FlowDiagramBloc>();
    return Scaffold(
      appBar: AppBar(title: Text('Diagrama de Flujo Económico')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) Periodos + unidad
            PeriodInputWidget(
              onSubmit: (periods) {
                final unitState = context.read<UnidadDeTiempoBloc>().state;
                if (unitState is UnidadDeTiempoLoaded &&
                    unitState.seleccionada != null) {
                  flowBloc.add(
                    InitializeDiagramEvent(
                      periods: periods,
                      unit: unitState.seleccionada!,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Seleccione primero la unidad de tiempo'),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 16),

            // 2) Unidad de tiempo
            UnitDropdownWidget(),

            SizedBox(height: 24),

            // 3) Tasas, valores y movimientos
            RatesSection(),
            Divider(),
            ValuesSection(),
            Divider(),
            MovementsSection(),

            SizedBox(height: 24),

            // 4) Vista del diagrama
            BlocBuilder<FlowDiagramBloc, FlowDiagramState>(
              builder: (_, state) {
                if (state is FlowDiagramLoaded) {
                  return FlowDiagramWidget(diagram: state.diagrama);
                } else if (state is FlowDiagramLoading) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  return Text(
                    'Inicie un diagrama arriba',
                    textAlign: TextAlign.center,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
