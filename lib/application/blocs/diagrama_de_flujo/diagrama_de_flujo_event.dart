// flow_diagram_event.dart

import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

abstract class FlowDiagramEvent {}

class InitializeDiagramEvent extends FlowDiagramEvent {
  final int periods;
  final UnidadDeTiempo unit;

  InitializeDiagramEvent({required this.periods, required this.unit});
}

class FetchDiagramEvent extends FlowDiagramEvent {}

class UpdatePeriodsEvent extends FlowDiagramEvent {
  final int periods;

  UpdatePeriodsEvent({required this.periods});
}

class ClearDiagramEvent extends FlowDiagramEvent {}
