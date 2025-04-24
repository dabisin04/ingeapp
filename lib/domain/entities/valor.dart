class Valor {
  final double? valor; // Ahora opcional
  final String tipo; // "Presente" o "Futuro"
  final int periodo;
  final String flujo; // "Ingreso" o "Egreso"

  Valor({
    this.valor,
    required this.tipo,
    required this.periodo,
    required this.flujo,
  });
}
