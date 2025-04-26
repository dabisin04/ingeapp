import 'dart:convert';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';

const String kAplicaTodos = 'Todos';
const String kAplicaIngresos = 'Ingresos';
const String kAplicaEgresos = 'Egresos';

class TasaDeInteres {
  final int id;
  final double valor;
  final UnidadDeTiempo periodicidad;
  final UnidadDeTiempo capitalizacion;
  final String tipo;
  final int periodoInicio;
  final int periodoFin;
  final String aplicaA;

  TasaDeInteres({
    required this.id,
    required this.valor,
    required this.periodicidad,
    required this.capitalizacion,
    required this.tipo,
    required this.periodoInicio,
    required this.periodoFin,
    this.aplicaA = kAplicaTodos,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'valor': valor,
        'periodicidad': periodicidad.toMap(),
        'capitalizacion': capitalizacion.toMap(),
        'tipo': tipo,
        'periodoInicio': periodoInicio,
        'periodoFin': periodoFin,
        'aplicaA': aplicaA,
      };

  factory TasaDeInteres.fromMap(Map<String, dynamic> map) => TasaDeInteres(
        id: map['id'] as int,
        valor: (map['valor'] as num).toDouble(),
        periodicidad:
            UnidadDeTiempo.fromMap(map['periodicidad'] as Map<String, dynamic>),
        capitalizacion: UnidadDeTiempo.fromMap(
            map['capitalizacion'] as Map<String, dynamic>),
        tipo: map['tipo'] as String,
        periodoInicio: map['periodoInicio'] as int,
        periodoFin: map['periodoFin'] as int,
        aplicaA: (map['aplicaA'] as String?) ?? kAplicaTodos,
      );

  String encode() => jsonEncode(toMap());

  static TasaDeInteres decode(String source) =>
      TasaDeInteres.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
