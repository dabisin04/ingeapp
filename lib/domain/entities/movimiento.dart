import 'dart:convert';

class Movimiento {
  final int id;
  final double? valor;
  final String tipo;
  final int? periodo; // ahora nullable

  Movimiento({
    required this.id,
    this.valor,
    required this.tipo,
    this.periodo, // opcional
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'valor': valor,
        'tipo': tipo,
        'periodo': periodo,
      };

  factory Movimiento.fromMap(Map<String, dynamic> map) => Movimiento(
        id: map['id'] as int,
        valor: (map['valor'] as num?)?.toDouble(),
        tipo: map['tipo'] as String,
        periodo: map['periodo'] != null ? map['periodo'] as int : null,
      );

  String encode() => jsonEncode(toMap());

  static Movimiento decode(String source) =>
      Movimiento.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
