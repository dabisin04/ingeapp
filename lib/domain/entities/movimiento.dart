class Movimiento {
  final int id;
  final double?
  valor; // Valor del ingreso o egreso (puede ser nulo si es opcional)
  final String tipo; // Tipo: "Ingreso" o "Egreso"
  final int periodo; // Periodo en el que ocurre el movimiento

  Movimiento({
    required this.id,
    this.valor, // Puede ser nulo si es un ingreso o egreso posterior
    required this.tipo,
    required this.periodo,
  });
}
