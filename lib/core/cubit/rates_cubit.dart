// lib/core/cubit/rates_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:tasas_eltoque/core/models/rate_model.dart';
import 'package:tasas_eltoque/core/services/api_service.dart';
import 'package:tasas_eltoque/core/services/local_storage_service.dart';

abstract class RatesState {}

class RatesInitial extends RatesState {}

class RatesLoading extends RatesState {
  final RateModel? cachedData;
  RatesLoading({this.cachedData});
}

class RatesLoaded extends RatesState {
  final RateModel data;
  final bool isFromCache;
  RatesLoaded({required this.data, this.isFromCache = false});
}

class RatesError extends RatesState {
  final String message;
  final RateModel? cachedData;
  RatesError({required this.message, this.cachedData});
}

class RatesCubit extends Cubit<RatesState> {
  final ApiService _apiService;
  final LocalStorageService _localStorage;

  RatesCubit({
    required ApiService apiService,
    required LocalStorageService localStorage,
  })  : _apiService = apiService,
        _localStorage = localStorage,
        super(RatesInitial());

  Future<void> fetchRates() async {
    final cached = _localStorage.getLocalRates();
    emit(RatesLoading(cachedData: cached));

    try {
      final data = await _apiService.fetchRates();
      await _localStorage.saveRates(data);
      emit(RatesLoaded(data: data, isFromCache: false));
    } on ApiException catch (e) {
      String message;

      // Si el error es de conexión
      if (e.statusCode == 0 &&
          (e.message.contains('conexión') || e.message.contains('Tiempo de conexión'))) {
        message =
        'No se pudo conectar a la API. Revisa tu conexión a internet o activa un VPN.';
      } else {
        message = e.message; // cualquier otro error de API
      }

      if (cached != null) {
        emit(RatesError(message: message, cachedData: cached));
      } else {
        emit(RatesError(message: message));
      }
    } catch (e) {
      final msg =
          'Error inesperado. ${cached == null ? 'Si no tienes conexión, intenta activar un VPN.' : ''}';
      if (cached != null) {
        emit(RatesError(message: msg, cachedData: cached));
      } else {
        emit(RatesError(message: msg));
      }
    }
  }

  void loadFromCache() {
    final cached = _localStorage.getLocalRates();
    if (cached != null) {
      emit(RatesLoaded(data: cached, isFromCache: true));
    } else {
      emit(RatesError(
        message:
        'No hay datos en caché. Conecta a internet para descargar las tasas o activa un VPN.',
      ));
    }
  }
}
