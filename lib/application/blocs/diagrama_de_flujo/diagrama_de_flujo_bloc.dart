import 'package:flutter_bloc/flutter_bloc.dart';
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
  }

  Future<void> _onInitializeDiagram(
    InitializeDiagramEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    emit(FlowDiagramLoading());
    try {
      await repository.initializeDiagram(
        periods: event.periods,
        unit: event.unit,
      );
      // Una vez inicializado, cargamos el diagrama
      final diagram = await repository.getDiagram();
      emit(FlowDiagramLoaded(diagram));
    } catch (e) {
      emit(
        FlowDiagramError('Error al inicializar el diagrama: ${e.toString()}'),
      );
    }
  }

  Future<void> _onFetchDiagram(
    FetchDiagramEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    emit(FlowDiagramLoading());
    try {
      final diagram = await repository.getDiagram();
      emit(FlowDiagramLoaded(diagram));
    } catch (e) {
      emit(FlowDiagramError('Error al obtener el diagrama: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePeriods(
    UpdatePeriodsEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    emit(FlowDiagramLoading());
    try {
      await repository.updatePeriods(event.periods);
      // Tras actualizar periodos, recargamos el diagrama
      final diagram = await repository.getDiagram();
      emit(FlowDiagramLoaded(diagram));
    } catch (e) {
      emit(
        FlowDiagramError('Error al actualizar los periodos: ${e.toString()}'),
      );
    }
  }

  Future<void> _onClearDiagram(
    ClearDiagramEvent event,
    Emitter<FlowDiagramState> emit,
  ) async {
    emit(FlowDiagramLoading());
    try {
      await repository.clearDiagram();
      emit(FlowDiagramInitial());
    } catch (e) {
      emit(FlowDiagramError('Error al limpiar el diagrama: ${e.toString()}'));
    }
  }
}
