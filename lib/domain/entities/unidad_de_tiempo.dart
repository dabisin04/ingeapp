class UnidadDeTiempo {
  final int id; // ID de la unidad de tiempo
  final String nombre; // Ej. "Diario", "Mensual", "Anual"
  final int valor; // Ej. 360 para diario, 12 para mensual, 1 para anual

  UnidadDeTiempo({required this.id, required this.nombre, required this.valor});
}
