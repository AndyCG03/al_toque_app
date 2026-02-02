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

  // ─── Modo de edición manual ───────────────────────────────
  bool _useCustomRates = false;
  Map<String, double> _customRates = {}; // Tasas personalizadas por el usuario

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

  void _updateRates(RateModel? data) {
    // Si no hay datos o las tasas están vacías
    if (data == null || data.tasas == null || data.tasas.isEmpty) {
      setState(() {
        _rates = null;
        _availableCurrencies = ['CUP']; // Al menos CUP disponible
        _result = null;
      });
      return;
    }

    if (_rates == null || _rates!.date != data.date) {
      setState(() {
        _rates = data;
        _availableCurrencies = ['CUP', ...data.tasas.keys.toList()];

        // Inicializar tasas personalizadas con los valores actuales
        if (_customRates.isEmpty && data.tasas.isNotEmpty) {
          _customRates = Map.from(data.tasas);
        }

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
    // Si no hay tasas, limpiar resultado
    if (_rates == null) {
      setState(() => _result = null);
      return;
    }

    // Obtener tasas activas con validación
    final activeTasas = _useCustomRates
        ? _customRates
        : (_rates?.tasas ?? {});

    // Si no hay tasas disponibles, limpiar resultado
    if (activeTasas.isEmpty) {
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
      // Validar que exista la tasa destino
      final rate = activeTasas[_targetCurrency];
      if (rate == null || rate <= 0) {
        setState(() => _result = null);
        return;
      }
      resultValue = amount / rate;
    } else if (_targetCurrency == 'CUP') {
      // Validar que exista la tasa origen
      final rate = activeTasas[_sourceCurrency];
      if (rate == null || rate <= 0) {
        setState(() => _result = null);
        return;
      }
      resultValue = amount * rate;
    } else {
      // Validar que existan ambas tasas
      final rateSource = activeTasas[_sourceCurrency];
      final rateTarget = activeTasas[_targetCurrency];
      if (rateSource == null || rateTarget == null || rateSource <= 0 || rateTarget <= 0) {
        setState(() => _result = null);
        return;
      }
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
        if (state is RatesLoaded) {
          _updateRates(state.data);
        } else if (state is RatesLoading) {
          // Solo actualizar si hay caché disponible
          if (state.cachedData != null) {
            _updateRates(state.cachedData);
          } else {
            // Si no hay caché, mostrar estado vacío
            setState(() {
              _rates = null;
              _availableCurrencies = ['CUP']; // Al menos CUP disponible
              _result = null;
            });
          }
        } else if (state is RatesError) {
          // Solo actualizar si hay caché disponible
          if (state.cachedData != null) {
            _updateRates(state.cachedData);
          } else {
            // Si no hay caché, mostrar estado vacío
            setState(() {
              _rates = null;
              _availableCurrencies = ['CUP']; // Al menos CUP disponible
              _result = null;
            });
          }
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text('Calculadora', style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _rates != null ? 'Tasas del ${_rates!.date}' : 'Sin datos de tasas aún',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (_rates != null && _rates!.tasas != null && _rates!.tasas!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildCustomRateToggle(context),
                ],
              ],
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
                Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant),
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
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selecciona moneda', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              ...(_availableCurrencies.isEmpty
                  ? [Text('No hay monedas disponibles', style: theme.textTheme.bodySmall)]
                  : _availableCurrencies.map((c) => _CurrencyOption(
                currency: c,
                isSelected: c == current,
                onTap: () {
                  onChanged(c);
                  Navigator.pop(ctx);
                },
              ))),
            ],
          ),
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

    return AnimatedCrossFade(
      firstChild: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultado', style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            )),
            const SizedBox(height: 6),
            Text(
              _formatResult(_result!),
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
          ],
        ),
      ),
      secondChild: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'Ingresa un monto para ver el resultado',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ),
      crossFadeState: hasResult ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildRateInfo(BuildContext context) {
    if (_rates == null || _rates!.tasas == null || _rates!.tasas!.isEmpty) {
      return const SizedBox();
    }

    final theme = Theme.of(context);
    final activeTasas = _useCustomRates ? _customRates : _rates!.tasas!;

    String rateInfo = '';
    if (_sourceCurrency != 'CUP' && activeTasas.containsKey(_sourceCurrency)) {
      final rate = activeTasas[_sourceCurrency];
      if (rate != null && rate > 0) {
        rateInfo = '1 $_sourceCurrency = ${rate.toStringAsFixed(2)} CUP';
      }
    }
    if (_targetCurrency != 'CUP' && activeTasas.containsKey(_targetCurrency)) {
      final rate = activeTasas[_targetCurrency];
      if (rate != null && rate > 0) {
        final extra = '1 $_targetCurrency = ${rate.toStringAsFixed(2)} CUP';
        rateInfo = rateInfo.isEmpty ? extra : '$rateInfo  |  $extra';
      }
    }

    if (rateInfo.isEmpty && !_useCustomRates) return const SizedBox();

    return Column(
      children: [
        if (rateInfo.isNotEmpty)
          Text(
            rateInfo,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _useCustomRates ? theme.colorScheme.primary : null,
            ),
            textAlign: TextAlign.center,
          ),
        if (_useCustomRates) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showRateEditor(context),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Editar tasas personalizadas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ],
    );
  }

  String _formatResult(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(4)}M';
    if (value >= 1000) return value.toStringAsFixed(2);
    if (value < 0.0001) return value.toStringAsFixed(8);
    if (value < 1) return value.toStringAsFixed(6);
    return value.toStringAsFixed(2);
  }

  // ─── CUSTOM RATE CONTROLS ─────────────────────────────────────────────────

  Widget _buildCustomRateToggle(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        if (_rates == null || _rates!.tasas == null || _rates!.tasas!.isEmpty) {
          return; // No hacer nada si no hay tasas
        }

        setState(() {
          _useCustomRates = !_useCustomRates;
          if (!_useCustomRates && _rates != null && _rates!.tasas != null) {
            // Al desactivar, resetear las tasas personalizadas
            _customRates = Map.from(_rates!.tasas!);
          }
          _calculate();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _useCustomRates
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _useCustomRates ? theme.colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _useCustomRates ? Icons.edit_rounded : Icons.edit_outlined,
              size: 16,
              color: _useCustomRates ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              _useCustomRates ? 'Personalizado' : 'Oficial',
              style: theme.textTheme.labelSmall?.copyWith(
                color: _useCustomRates ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRateEditor(BuildContext context) {
    if (_rates == null || _rates!.tasas == null || _rates!.tasas!.isEmpty) {
      return; // No mostrar editor si no hay tasas
    }

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => _RateEditorSheet(
          customRates: _customRates,
          originalRates: _rates!.tasas!,
          onSave: (updatedRates) {
            setState(() {
              _customRates = updatedRates;
              _calculate();
            });
            Navigator.pop(ctx);
          },
          onReset: () {
            setState(() {
              if (_rates != null && _rates!.tasas != null) {
                _customRates = Map.from(_rates!.tasas!);
              }
              _calculate();
            });
            Navigator.pop(ctx);
          },
          scrollController: scrollController,
        ),
      ),
    );
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

// ─── RATE EDITOR SHEET ──────────────────────────────────────────────────────

class _RateEditorSheet extends StatefulWidget {
  final Map<String, double> customRates;
  final Map<String, double> originalRates;
  final Function(Map<String, double>) onSave;
  final VoidCallback onReset;
  final ScrollController scrollController;

  const _RateEditorSheet({
    required this.customRates,
    required this.originalRates,
    required this.onSave,
    required this.onReset,
    required this.scrollController,
  });

  @override
  State<_RateEditorSheet> createState() => _RateEditorSheetState();
}

class _RateEditorSheetState extends State<_RateEditorSheet> {
  late Map<String, TextEditingController> _controllers;
  late Map<String, double> _tempRates;

  static const Map<String, String> _names = {
    'USD': 'Dólar Estadounidense',
    'MLC': 'Moneda Libre de Conversión',
    'USDT_TRC20': 'Tether (USDT) TRC-20',
    'TRX': 'TRON',
    'BTC': 'Bitcoin',
    'ECU': 'Euro',
    'BNB': 'Binance Coin',
  };

  @override
  void initState() {
    super.initState();
    _tempRates = Map.from(widget.customRates);
    _controllers = {};
    for (final entry in _tempRates.entries) {
      _controllers[entry.key] = TextEditingController(
        text: entry.value.toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateRate(String currency, String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed != null && parsed > 0) {
      _tempRates[currency] = parsed;
    }
  }

  bool get _hasChanges {
    for (final entry in _tempRates.entries) {
      if (entry.value != widget.customRates[entry.key]) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _tempRates.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Editar Tasas', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Modifica los valores de cambio para tus cálculos. Estos cambios no afectan las tasas oficiales.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),

          // Lista de tasas editables
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final currency = entry.key;
                final originalRate = widget.originalRates[currency]!;
                final controller = _controllers[currency]!;
                final hasChanged = _tempRates[currency] != widget.customRates[currency];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hasChanged
                          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasChanged ? theme.colorScheme.primary : theme.colorScheme.outline,
                        width: hasChanged ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency,
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  _names[currency] ?? currency,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'Oficial: ${originalRate.toStringAsFixed(2)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (hasChanged) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                                ],
                                style: theme.textTheme.titleMedium,
                                decoration: InputDecoration(
                                  labelText: 'Tasa (CUP)',
                                  isDense: true,
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: theme.colorScheme.outline),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: theme.colorScheme.outline),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() => _updateRate(currency, value));
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Restaurar valor oficial',
                              onPressed: () {
                                setState(() {
                                  _tempRates[currency] = originalRate;
                                  controller.text = originalRate.toStringAsFixed(2);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: theme.colorScheme.error),
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('Restaurar todo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _hasChanges ? () => widget.onSave(_tempRates) : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}