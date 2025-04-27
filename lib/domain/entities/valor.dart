import 'dart:convert';

class Valor {
  final double? valor;
  final String tipo;
  final int? periodo;
  final String flujo;

  Valor({
    this.valor,
    required this.tipo,
    this.periodo,
    required this.flujo,
  });

  Map<String, dynamic> toMap() => {
        'valor': valor,
        'tipo': tipo,
        'periodo': periodo,
        'flujo': flujo,
      };

  factory Valor.fromMap(Map<String, dynamic> map) => Valor(
        valor: (map['valor'] as num?)?.toDouble(),
        tipo: map['tipo'] as String,
        periodo: map['periodo'] != null ? map['periodo'] as int : null,
        flujo: map['flujo'] as String,
      );

  String encode() => jsonEncode(toMap());

  static Valor decode(String source) =>
      Valor.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
