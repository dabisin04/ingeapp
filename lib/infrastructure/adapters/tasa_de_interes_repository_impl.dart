import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/repositories/tasa_de_interes_repository.dart';

class TasaInteresAdapter implements TasaInteresRepository {
  final List<TasaDeInteres> _tasas = [];

  @override
  Future<void> agregarTasaInteres(TasaDeInteres tasa) async {
    _tasas.add(tasa);
  }

  @override
  Future<void> editarTasaInteres(int id, TasaDeInteres tasaActualizada) async {
    final index = _tasas.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasas[index] = tasaActualizada;
    } else {
      throw Exception('Tasa de interés con ID $id no encontrada');
    }
  }

  @override
  Future<void> eliminarTasaInteres(int id) async {
    _tasas.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<TasaDeInteres>> obtenerTasasInteres() async {
    return _tasas;
  }

  @override
  Future<TasaDeInteres?> obtenerTasaPorPeriodo(int periodo) async {
    // Devuelve la primera tasa que incluya el periodo especificado.
    try {
      return _tasas.firstWhere(
        (t) => periodo >= t.periodoInicio && periodo <= t.periodoFin,
      );
    } catch (_) {
      return null;
    }
  }
}
