import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/repositories/valor_repository.dart';
import 'valor_event.dart';
import 'valor_state.dart';

class ValorBloc extends Bloc<ValorEvent, ValorState> {
  final ValorRepository repository;

  ValorBloc({required this.repository}) : super(ValorInitial()) {
    on<CargarValoresEvent>(_onCargarValores);
    on<AgregarValorEvent>(_onAgregarValor);
    on<EditarValorEvent>(_onEditarValor);
    on<EliminarValorEvent>(_onEliminarValor);
    on<ObtenerValorPorPeriodoEvent>(_onObtenerValorPorPeriodo);
  }

  // Handler para cargar los valores
  Future<void> _onCargarValores(
    CargarValoresEvent event,
    Emitter<ValorState> emit,
  ) async {
    emit(ValorLoading());
    try {
      final valores = await repository.getValores();
      emit(ValorLoaded(valores));
    } catch (e) {
      emit(ValorError('Error al cargar los valores: ${e.toString()}'));
    }
  }

  // Handler para agregar un valor
  Future<void> _onAgregarValor(
    AgregarValorEvent event,
    Emitter<ValorState> emit,
  ) async {
    try {
      await repository.addValor(event.valor);
      add(CargarValoresEvent()); // Recargar lista de valores después de agregar
    } catch (e) {
      emit(ValorError('Error al agregar el valor: ${e.toString()}'));
    }
  }

  // Handler para editar un valor
  Future<void> _onEditarValor(
    EditarValorEvent event,
    Emitter<ValorState> emit,
  ) async {
    try {
      await repository.updateValor(event.valorActualizado);
      add(CargarValoresEvent()); // Recargar lista de valores después de editar
    } catch (e) {
      emit(ValorError('Error al editar el valor: ${e.toString()}'));
    }
  }

  // Handler para eliminar un valor
  Future<void> _onEliminarValor(
    EliminarValorEvent event,
    Emitter<ValorState> emit,
  ) async {
    try {
      await repository.deleteValor(event.periodo, event.tipo);
      add(
        CargarValoresEvent(),
      ); // Recargar lista de valores después de eliminar
    } catch (e) {
      emit(ValorError('Error al eliminar el valor: ${e.toString()}'));
    }
  }

  // Handler para obtener un valor por periodo
  Future<void> _onObtenerValorPorPeriodo(
    ObtenerValorPorPeriodoEvent event,
    Emitter<ValorState> emit,
  ) async {
    try {
      final valor = await repository.getValorPorPeriodo(event.periodo);
      if (valor != null) {
        emit(ValorPorPeriodoLoaded(valor));
      } else {
        emit(
          ValorError('Valor no encontrado para el periodo ${event.periodo}.'),
        );
      }
    } catch (e) {
      emit(
        ValorError('Error al obtener el valor por periodo: ${e.toString()}'),
      );
    }
  }
}
