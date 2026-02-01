// lib/core/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:tasas_eltoque/core/models/rate_model.dart';

// ⚠️  Reemplaza con tu token real obtenido en https://tasas.eltoque.com/docs/
const String _API_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc2NzcxNDA2OCwianRpIjoiY2Q3MTMwODktNzE3My00YzIzLWFlMTktOGIxMmM4YmU0MGE3IiwidHlwZSI6ImFjY2VzcyIsInN1YiI6IjY5NGVlMDkyZTkyYmU3N2VhM2Y4NmY4OSIsIm5iZiI6MTc2NzcxNDA2OCwiZXhwIjoxNzk5MjUwMDY4fQ.i52HYyExOVihHqurMLkiVRr1u1n1Fsw77EcJFH7oVQI';
const String _BASE_URL = 'https://tasas.eltoque.com';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException [$statusCode]: $message';
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _BASE_URL,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Authorization': 'Bearer $_API_TOKEN',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor para logging en debug
    _dio.interceptors.add(
      LogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Obtiene las tasas de cambio actuales (últimas 24h)
  Future<RateModel> fetchRates({DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final queryParams = <String, String>{};
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String();
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String();
      }

      final response = await _dio.get(
        '/v1/trmi',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return RateModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw ApiException(
            statusCode: 0,
            message: 'Tiempo de conexión agotado. Revisa tu conexión a internet.',
          );
        case DioExceptionType.connectionError:
          throw ApiException(
            statusCode: 0,
            message: 'Sin conexión a internet.',
          );
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode ?? 0;
          final msg = switch (statusCode) {
            400 => 'Rango de tiempo inválido (debe ser menor a 24h).',
            401 => 'Token de autorización incorrecto o expirado.',
            422 => 'Token no procesable. Revisa tu clave API.',
            429 => 'Límite de peticiones alcanzado. Espera un momento.',
            _ => 'Error del servidor: $statusCode',
          };
          throw ApiException(statusCode: statusCode, message: msg);
        default:
          throw ApiException(statusCode: 0, message: 'Error inesperado: ${e.message}');
      }
    }
  }
}
