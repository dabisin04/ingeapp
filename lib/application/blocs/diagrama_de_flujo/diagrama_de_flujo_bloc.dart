import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/repositories/diagrama_de_flujo_repository.dart';
import 'diagrama_de_flujo_event.dart';
import 'diagrama_de_flujo_state.dart';

class FlowDiagramBloc extends Bloc<FlowDiagramEvent, FlowDiagramState> {
  final FlowDiagramRepository repository;

  FlowDiagramBloc({required this.repository}) : super(FlowDiagramInitial()) {
    on<InitializeDiagramEvent>(_onInitializeDiagram);
    on<FetchDiagramEvent>(_onFetchDiagram);
    on<UpdatePeriodsEvent>(_onUpdatePeriods);
    on<ClearDiagramEvent>(_onClearDiagram);
    on<UpdateTasasEvent>(_onUpdateTasas);
    on<UpdateValoresEvent>(_onUpdateValores);
    on<UpdateMovimientosEvent>(_onUpdateMovimientos);
  }

  Future<void> _onInitializeDiagram(
    InitializeDiagramEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    print(
      '🔹 [FlowDiagramBloc] InitializeDiagramEvent recibido → periods: ${event.periods}, unit: ${event.unit}',
    );
    emit(FlowDiagramLoading());
    try {
      await repository.initializeDiagram(
        periods: event.periods,
        unit: event.unit,
      );
      final diagram = await repository.getDiagram();
      print('✔️ Diagrama inicializado: $diagram');
      emit(FlowDiagramLoaded(diagram));
    } catch (e, st) {
      print('❌ Error al inicializar: $e\n$st');
      emit(
        FlowDiagramError('Error al inicializar el diagrama: ${e.toString()}'),
      );
    }
  }

  Future<void> _onFetchDiagram(
    FetchDiagramEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    print('🔹 [FlowDiagramBloc] FetchDiagramEvent recibido');
    emit(FlowDiagramLoading());
    try {
      final diagram = await repository.getDiagram();
      print('✔️ Diagrama obtenido: $diagram');
      emit(FlowDiagramLoaded(diagram));
    } catch (e, st) {
      print('❌ Error al obtener el diagrama: $e\n$st');
      emit(FlowDiagramError('Error al obtener el diagrama: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePeriods(
    UpdatePeriodsEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    print(
      '🔹 [FlowDiagramBloc] UpdatePeriodsEvent recibido → periods: ${event.periods}',
    );
    emit(FlowDiagramLoading());
    try {
      await repository.updatePeriods(event.periods);
      final diagram = await repository.getDiagram();
      print('✔️ Periodos actualizados en diagrama: $diagram');
      emit(FlowDiagramLoaded(diagram));
    } catch (e, st) {
      print('❌ Error al actualizar periodos: $e\n$st');
      emit(
        FlowDiagramError('Error al actualizar los periodos: ${e.toString()}'),
      );
    }
  }

  Future<void> _onClearDiagram(
    ClearDiagramEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    print('🔹 [FlowDiagramBloc] ClearDiagramEvent recibido');
    emit(FlowDiagramLoading());
    try {
      await repository.clearDiagram();
      print('✔️ Diagrama limpiado');
      emit(FlowDiagramInitial());
    } catch (e, st) {
      print('❌ Error al limpiar el diagrama: $e\n$st');
      emit(FlowDiagramError('Error al limpiar el diagrama: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTasas(
    UpdateTasasEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    // Sólo actualizamos si ya tenemos el diagrama cargado
    if (state is FlowDiagramLoaded) {
      final current = (state as FlowDiagramLoaded).diagrama;
      // Reconstruimos una copia con las nuevas tasas
      final updated = DiagramaDeFlujo(
        id: current.id,
        unidadDeTiempo: current.unidadDeTiempo,
        cantidadDePeriodos: current.cantidadDePeriodos,
        tasasDeInteres: event.tasas,
        movimientos: current.movimientos,
        valores: current.valores,
      );
      // Emitimos de nuevo
      emit(FlowDiagramLoaded(updated));
    }
  }

  Future<void> _onUpdateValores(
    UpdateValoresEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    if (state is FlowDiagramLoaded) {
      final current = (state as FlowDiagramLoaded).diagrama;
      emit(
        FlowDiagramLoaded(
          DiagramaDeFlujo(
            id: current.id,
            unidadDeTiempo: current.unidadDeTiempo,
            cantidadDePeriodos: current.cantidadDePeriodos,
            tasasDeInteres: current.tasasDeInteres,
            movimientos: current.movimientos,
            valores: event.valores,
          ),
        ),
      );
    }
  }

  Future<void> _onUpdateMovimientos(
    UpdateMovimientosEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    if (state is FlowDiagramLoaded) {
      final current = (state as FlowDiagramLoaded).diagrama;
      emit(
        FlowDiagramLoaded(
          DiagramaDeFlujo(
            id: current.id,
            unidadDeTiempo: current.unidadDeTiempo,
            cantidadDePeriodos: current.cantidadDePeriodos,
            tasasDeInteres: current.tasasDeInteres,
            movimientos: event.movimientos,
            valores: current.valores,
          ),
        ),
      );
    }
  }
}
