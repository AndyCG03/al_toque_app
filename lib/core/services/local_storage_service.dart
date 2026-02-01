// lib/core/services/local_storage_service.dart
import 'package:hive/hive.dart';
import 'package:tasas_eltoque/core/models/rate_model.dart';

const String _ratesBoxName = 'cached_rates';
const String _latestRateKey = 'latest_rate';

class LocalStorageService {
  late Box<RateModel> _box;

  Future<void> init() async {
    _box = await Hive.openBox<RateModel>(_ratesBoxName);
  }

  /// Guarda las tasas más recientes
  Future<void> saveRates(RateModel model) async {
    await _box.put(_latestRateKey, model);
  }

  /// Retorna las tasas guardadas localmente (null si no hay)
  RateModel? getLocalRates() {
    return _box.get(_latestRateKey);
  }

  /// Elimina el cache local
  Future<void> clearCache() async {
    await _box.delete(_latestRateKey);
  }
}
