import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/repositories/diagrama_de_flujo_repository.dart';

class FlowDiagramAdapter implements FlowDiagramRepository {
  DiagramaDeFlujo? _diagram;

  @override
  Future<void> initializeDiagram({
    required int periods,
    required UnidadDeTiempo unit,
  }) async {
    if (_diagram != null) {
      throw Exception('El diagrama de flujo ya ha sido inicializado');
    }
    _diagram = DiagramaDeFlujo(
      id: 1,
      unidadDeTiempo: unit,
      cantidadDePeriodos: periods,
      tasasDeInteres: [],
      movimientos: [],
    );
  }

  @override
  Future<DiagramaDeFlujo> getDiagram() async {
    if (_diagram == null) {
      throw Exception('Diagrama de flujo no inicializado');
    }
    return _diagram!;
  }

  @override
  Future<void> updatePeriods(int periods) async {
    if (_diagram == null) {
      throw Exception('El diagrama de flujo no ha sido inicializado');
    }
    _diagram = DiagramaDeFlujo(
      id: _diagram!.id,
      unidadDeTiempo: _diagram!.unidadDeTiempo,
      cantidadDePeriodos: periods,
      tasasDeInteres: _diagram!.tasasDeInteres,
      movimientos: _diagram!.movimientos,
    );
  }

  @override
  Future<void> clearDiagram() async {
    _diagram = null;
  }
}
