import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/entities/valor.dart';

class DiagramaDeFlujo {
  final int id;
  final UnidadDeTiempo unidadDeTiempo;
  final int cantidadDePeriodos;
  final List<TasaDeInteres> tasasDeInteres;
  final List<Movimiento> movimientos;
  final List<Valor> valores;

  DiagramaDeFlujo({
    required this.id,
    required this.unidadDeTiempo,
    required this.cantidadDePeriodos,
    required this.tasasDeInteres,
    required this.movimientos,
    required this.valores,
  });

  DiagramaDeFlujo copyWith({
    int? cantidadDePeriodos,
    List<TasaDeInteres>? tasasDeInteres,
    List<Movimiento>? movimientos,
    List<Valor>? valores,
  }) {
    return DiagramaDeFlujo(
      id: id,
      unidadDeTiempo: unidadDeTiempo,
      cantidadDePeriodos: cantidadDePeriodos ?? this.cantidadDePeriodos,
      tasasDeInteres: tasasDeInteres ?? this.tasasDeInteres,
      movimientos: movimientos ?? this.movimientos,
      valores: valores ?? this.valores,
    );
  }
}
