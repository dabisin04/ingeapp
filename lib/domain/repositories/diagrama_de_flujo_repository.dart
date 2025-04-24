import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

abstract class FlowDiagramRepository {
  Future<DiagramaDeFlujo> getDiagram();
  Future<void> initializeDiagram({
    required int periods,
    required UnidadDeTiempo unit,
  });
  Future<void> updatePeriods(int periods);
  Future<void> clearDiagram();
}
