// flow_diagram_state.dart

import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';

abstract class FlowDiagramState {}

class FlowDiagramInitial extends FlowDiagramState {}

class FlowDiagramLoading extends FlowDiagramState {}

class FlowDiagramLoaded extends FlowDiagramState {
  final DiagramaDeFlujo diagrama;

  FlowDiagramLoaded(this.diagrama);
}

class FlowDiagramError extends FlowDiagramState {
  final String message;

  FlowDiagramError(this.message);
}
