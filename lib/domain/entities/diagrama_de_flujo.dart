import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

class DiagramaDeFlujo {
  final int id; // Identificador único del diagrama
  final UnidadDeTiempo unidadDeTiempo;
  final int cantidadDePeriodos; // Cantidad total de periodos en el diagrama
  final List<TasaDeInteres> tasasDeInteres;
  final List<Movimiento> movimientos;

  DiagramaDeFlujo({
    required this.id,
    required this.unidadDeTiempo,
    required this.cantidadDePeriodos,
    required this.tasasDeInteres,
    required this.movimientos,
  });
}
