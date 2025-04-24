import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

class TasaDeInteres {
  final int id; // Identificador único de la tasa
  final double valor; // Parte numérica de la tasa
  final UnidadDeTiempo periodicidad; // Unidad de tiempo (diario, mensual, etc.)
  final UnidadDeTiempo
  capitalizacion; // Unidad de tiempo para la capitalización
  final String tipo; // Vencida o anticipada
  final int periodoInicio; // Periodo de inicio de la tasa
  final int periodoFin; // Periodo de fin de la tasa

  TasaDeInteres({
    required this.id,
    required this.valor,
    required this.periodicidad,
    required this.capitalizacion,
    required this.tipo,
    required this.periodoInicio,
    required this.periodoFin,
  });
}
