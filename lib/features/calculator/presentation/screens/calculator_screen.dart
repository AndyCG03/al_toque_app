// lib/features/calculator/presentation/screens/calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasas_eltoque/core/cubit/rates_cubit.dart';
import 'package:tasas_eltoque/core/models/rate_model.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _sourceCurrency = 'USD';
  String _targetCurrency = 'CUP';
  double? _result;
  RateModel? _rates;
  List<String> _availableCurrencies = [];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateRates(RateModel data) {
    if (_rates == null || _rates!.date != data.date) {
      setState(() {
        _rates = data;
        _availableCurrencies = ['CUP', ...data.tasas.keys.toList()];
        // Validar que las monedas seleccionadas existan
        if (!_availableCurrencies.contains(_sourceCurrency)) {
          _sourceCurrency = _availableCurrencies.length > 1 ? _availableCurrencies[1] : 'CUP';
        }
        if (!_availableCurrencies.contains(_targetCurrency)) {
          _targetCurrency = 'CUP';
        }
        _calculate();
      });
    }
  }

  void _calculate() {
    if (_rates == null) {
      setState(() => _result = null);
      return;
    }
    final text = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() => _result = null);
      return;
    }

    double resultValue;

    if (_sourceCurrency == 'CUP' && _targetCurrency == 'CUP') {
      resultValue = amount;
    } else if (_sourceCurrency == 'CUP') {
      // CUP -> otra moneda: dividir por la tasa
      final rate = _rates!.tasas[_targetCurrency]!;
      resultValue = amount / rate;
    } else if (_targetCurrency == 'CUP') {
      // Otra moneda -> CUP: multiplicar por la tasa
      final rate = _rates!.tasas[_sourceCurrency]!;
      resultValue = amount * rate;
    } else {
      // Entre dos monedas extranjeras: convertir primero a CUP y luego a destino
      final rateSource = _rates!.tasas[_sourceCurrency]!;
      final rateTarget = _rates!.tasas[_targetCurrency]!;
      resultValue = (amount * rateSource) / rateTarget;
    }

    setState(() => _result = resultValue);
  }

  void _swap() {
    setState(() {
      final temp = _sourceCurrency;
      _sourceCurrency = _targetCurrency;
      _targetCurrency = temp;
      _calculate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<RatesCubit, RatesState>(
      listener: (context, state) {
        if (state is RatesLoaded) _updateRates(state.data);
        else if (state is RatesLoading && state.cachedData != null) _updateRates(state.cachedData!);
        else if (state is RatesError && state.cachedData != null) _updateRates(state.cachedData!);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text('Calculadora', style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              _rates != null ? 'Tasas del ${_rates!.date}' : 'Sin datos de tasas aún',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 28),

            // ─── Moneda origen ────────────────────────────────────
            _buildCurrencySelector(
              context,
              label: 'De',
              selected: _sourceCurrency,
              onChanged: (value) {
                setState(() => _sourceCurrency = value);
                _calculate();
              },
            ),
            const SizedBox(height: 12),

            // ─── Campo de monto ──────────────────────────────────
            _buildAmountField(context),
            const SizedBox(height: 16),

            // ─── Botón swap ───────────────────────────────────────
            Center(
              child: InkWell(
                onTap: _swap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.swap_vert_rounded,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Moneda destino ──────────────────────────────────
            _buildCurrencySelector(
              context,
              label: 'A',
              selected: _targetCurrency,
              onChanged: (value) {
                setState(() => _targetCurrency = value);
                _calculate();
              },
            ),
            const SizedBox(height: 28),

            // ─── Resultado ────────────────────────────────────────
            _buildResultCard(context),

            // ─── Info de la tasa utilizada ────────────────────────
            const SizedBox(height: 16),
            _buildRateInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector(
      BuildContext context, {
        required String label,
        required String selected,
        required ValueChanged<String> onChanged,
      }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showCurrencyPicker(context, selected, onChanged),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outline, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selected,
                  style: theme.textTheme.titleMedium,
                ),
                Icon(Icons.expand_more, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCurrencyPicker(BuildContext context, String current, ValueChanged<String> onChanged) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // ← IMPORTANTE: Permite scroll controlado
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6, // Altura inicial (60% de la pantalla)
          minChildSize: 0.4,    // Altura mínima (40% de la pantalla)
          maxChildSize: 0.9,    // Altura máxima (90% de la pantalla)
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header fijo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selecciona moneda',
                        style: theme.textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lista scrolleable
                  Expanded(
                    child: _availableCurrencies.isEmpty
                        ? Center(
                      child: Text(
                        'No hay monedas disponibles',
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                        : ListView.builder(
                      controller: scrollController, // Controlador para el scroll
                      shrinkWrap: true,
                      itemCount: _availableCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = _availableCurrencies[index];
                        return _CurrencyOption(
                          currency: currency,
                          isSelected: currency == current,
                          onTap: () {
                            onChanged(currency);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAmountField(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
      decoration: InputDecoration(
        labelText: 'Cantidad',
        prefixIcon: const Icon(Icons.attach_money_rounded),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final theme = Theme.of(context);
    final hasResult = _result != null && _amountController.text.isNotEmpty;

    // Manejo seguro para evitar null
    final resultValue = _result ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasResult
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: !hasResult
            ? Border.all(
          color: theme.colorScheme.outline,
          style: BorderStyle.solid,
          width: 1,
        )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultado',
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasResult ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          if (hasResult) ...[
            Text(
              _formatResult(resultValue),
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _targetCurrency,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Ingresa un monto para ver el resultado',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateInfo(BuildContext context) {
    if (_rates == null) return const SizedBox();
    final theme = Theme.of(context);

    String rateInfo = '';
    if (_sourceCurrency != 'CUP' && _rates!.tasas.containsKey(_sourceCurrency)) {
      rateInfo = '1 $_sourceCurrency = ${_rates!.tasas[_sourceCurrency]!.toStringAsFixed(2)} CUP';
    }
    if (_targetCurrency != 'CUP' && _rates!.tasas.containsKey(_targetCurrency)) {
      final extra = '1 $_targetCurrency = ${_rates!.tasas[_targetCurrency]!.toStringAsFixed(2)} CUP';
      rateInfo = rateInfo.isEmpty ? extra : '$rateInfo  |  $extra';
    }

    if (rateInfo.isEmpty) return const SizedBox();

    return Text(
      rateInfo,
      style: theme.textTheme.labelSmall,
      textAlign: TextAlign.center,
    );
  }

  String _formatResult(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(4)}M';
    if (value >= 1000) return value.toStringAsFixed(2);
    if (value < 0.0001) return value.toStringAsFixed(8);
    if (value < 1) return value.toStringAsFixed(6);
    return value.toStringAsFixed(2);
  }
}

// ─── CURRENCY OPTION WIDGET ─────────────────────────────────────────────────

class _CurrencyOption extends StatelessWidget {
  final String currency;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyOption({
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  static const Map<String, String> _names = {
    'CUP': 'Peso Cubano',
    'USD': 'Dólar Estadounidense',
    'MLC': 'Moneda Libre de Conversión',
    'USDT_TRC20': 'Tether (USDT) TRC-20',
    'TRX': 'TRON',
    'BTC': 'Bitcoin',
    'ECU': 'Euro',
    'BNB': 'Binance Coin',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    _names[currency] ?? currency,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              if (isSelected)
                Icon(Icons.check_rounded, color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}