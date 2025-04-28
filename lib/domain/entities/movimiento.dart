import 'dart:convert';

class Movimiento {
  final int id;
  final dynamic valor; // ← puede ser double o String
  final String tipo;
  final int? periodo;

  Movimiento({
    required this.id,
    this.valor,
    required this.tipo,
    this.periodo,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'valor': valor, // ← guarda tal cual
        'tipo': tipo,
        'periodo': periodo,
      };

  factory Movimiento.fromMap(Map<String, dynamic> map) => Movimiento(
        id: map['id'] as int,
        valor: map['valor'], // ← sin convertir
        tipo: map['tipo'] as String,
        periodo: map['periodo'] != null ? map['periodo'] as int : null,
      );

  String encode() => jsonEncode(toMap());

  static Movimiento decode(String source) =>
      Movimiento.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
