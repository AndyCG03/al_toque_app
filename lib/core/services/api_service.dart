// lib/core/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importar dotenv
import 'package:tasas_eltoque/core/models/rate_model.dart';

// ⚠️  REMOVER o COMENTAR esta línea:
// const String _API_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

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
  late final String _apiToken;

  ApiService() {
    // Obtener token del archivo .env
    _apiToken = _getApiToken();

    _dio = Dio(
      BaseOptions(
        baseUrl: _BASE_URL,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Authorization': 'Bearer $_apiToken',  // Usar token obtenido
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

  /// Método privado para obtener el token API del archivo .env
  String _getApiToken() {
    try {
      // Intentar obtener del archivo .env
      final token = dotenv.get('ELTOQUE_API_TOKEN');

      // Validaciones de seguridad
      if (token.isEmpty) {
        throw Exception('ELTOQUE_API_TOKEN no está configurada en el archivo .env');
      }

      if (token == 'tu_token_aqui' || token.contains('eyJhbGciOiJ')) {
        // Solo mostrar un warning en consola, no bloquear
        print('⚠️  ADVERTENCIA: Parece que estás usando un token de ejemplo');
        print('   Obtén tu token real en: https://tasas.eltoque.com/docs/');
      }

      return token;
    } catch (e) {
      // Si hay error cargando .env, mostrar mensaje útil
      print('❌ ERROR cargando API token: $e');
      print('   Asegúrate de que:');
      print('   1. Tienes un archivo .env en la raíz del proyecto');
      print('   2. El archivo contiene: ELTOQUE_API_TOKEN=tu_token_real');
      print('   3. En pubspec.yaml está agregado en assets:');
      print('      assets:');
      print('        - .env');

      // Para desarrollo, puedes devolver un token por defecto o lanzar error
      throw Exception(
          'No se pudo cargar ELTOQUE_API_TOKEN.\n'
              'Solución:\n'
              '1. Crea un archivo .env en la raíz del proyecto\n'
              '2. Agrega: ELTOQUE_API_TOKEN=tu_token_real\n'
              '3. Obtén tu token en: https://tasas.eltoque.com/docs/\n'
              '4. Asegúrate de que pubspec.yaml incluye ".env" en assets'
      );
    }
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