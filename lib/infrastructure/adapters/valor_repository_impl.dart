import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/domain/repositories/valor_repository.dart';

class ValorAdapter implements ValorRepository {
  final List<Valor> _valores = [];

  @override
  Future<void> addValor(Valor valor) async {
    _valores.add(valor);
  }

  @override
  Future<List<Valor>> getValores() async {
    return _valores;
  }

  @override
  Future<void> updateValor(Valor valor) async {
    final index = _valores.indexWhere(
      (v) => v.periodo == valor.periodo && v.tipo == valor.tipo,
    );
    if (index != -1) {
      _valores[index] = valor;
    } else {
      throw Exception(
        'Valor no encontrado para periodo ${valor.periodo} y tipo ${valor.tipo}',
      );
    }
  }

  @override
  Future<void> deleteValor(int periodo, String tipo) async {
    _valores.removeWhere((v) => v.periodo == periodo && v.tipo == tipo);
  }

  @override
  Future<Valor> getValorPorPeriodo(int periodo) async {
    try {
      final valor = _valores.firstWhere((v) => v.periodo == periodo);
      return valor;
    } catch (e) {
      throw Exception('Valor no encontrado para el periodo $periodo');
    }
  }
}
