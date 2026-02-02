// lib/features/rates/presentation/screens/rates_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasas_eltoque/core/cubit/rates_cubit.dart';
import 'package:tasas_eltoque/core/models/rate_model.dart';
import 'package:tasas_eltoque/core/theme/app_theme.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RatesCubit>().fetchRates();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RatesCubit, RatesState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<RatesCubit>().fetchRates(),
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(context, state),
                    const SizedBox(height: 16),
                    _buildContent(context, state),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, RatesState state) {
    final theme = Theme.of(context);
    RateModel? data;
    bool fromCache = false;

    if (state is RatesLoaded) {
      data = state.data;
      fromCache = state.isFromCache;
    } else if (state is RatesLoading && state.cachedData != null) {
      data = state.cachedData;
      fromCache = true;
    } else if (state is RatesError && state.cachedData != null) {
      data = state.cachedData;
      fromCache = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasas de Cambio',
          style: theme.textTheme.displaySmall,
        ),
        if (data != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '${data.date} ${data.timeFormatted}',
                style: theme.textTheme.labelMedium,
              ),
              if (fromCache) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Caché',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warningColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (state is RatesError) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.negativeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              state.message,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.negativeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context, RatesState state) {
    if (state is RatesLoading && state.cachedData == null) {
      return _buildLoadingShimmer(context);
    }

    RateModel? data;
    if (state is RatesLoaded) data = state.data;
    else if (state is RatesLoading) data = state.cachedData;
    else if (state is RatesError) data = state.cachedData;

    if (data == null) {
      return _buildEmptyState(context);
    }

    return _buildRatesList(context, data);
  }

  Widget _buildRatesList(BuildContext context, RateModel data) {
    final theme = Theme.of(context);

    // Definir el orden de las monedas
    final fiatOrder = ['USD', 'ECU', 'MLC'];
    final cryptoOrder = ['USDT_TRC20', 'TRX', 'BNB'];

    // Separar monedas fiat y crypto (excluir BTC)
    final fiatEntries = <MapEntry<String, double>>[];
    final cryptoEntries = <MapEntry<String, double>>[];

    for (final entry in data.tasas.entries) {
      if (entry.key == 'BTC') continue; // Excluir Bitcoin

      if (fiatOrder.contains(entry.key)) {
        fiatEntries.add(entry);
      } else if (cryptoOrder.contains(entry.key)) {
        cryptoEntries.add(entry);
      }
    }

    // Ordenar según el orden definido
    fiatEntries.sort((a, b) => fiatOrder.indexOf(a.key).compareTo(fiatOrder.indexOf(b.key)));
    cryptoEntries.sort((a, b) => cryptoOrder.indexOf(a.key).compareTo(cryptoOrder.indexOf(b.key)));

    return Column(
      children: [
        // Monedas Fiat
        ...fiatEntries.mapIndexed((index, entry) {
          return AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 300 + (index * 60)),
            child: _RateCard(
              currency: entry.key,
              rate: entry.value,
            ),
          );
        }).toList(),

        // Separador si hay criptomonedas
        if (cryptoEntries.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(child: Divider(color: theme.colorScheme.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'CRIPTOMONEDAS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Criptomonedas
        ...cryptoEntries.mapIndexed((index, entry) {
          return AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 300 + ((fiatEntries.length + index) * 60)),
            child: _RateCard(
              currency: entry.key,
              rate: entry.value,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(5, (index) => _ShimmerCard(theme: theme)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.currency_exchange_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay datos disponibles',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Conecta a internet y desliza hacia arriba para actualizar',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── RATE CARD ───────────────────────────────────────────────────────────────

class _RateCard extends StatelessWidget {
  final String currency;
  final double rate;

  const _RateCard({required this.currency, required this.rate});

  static const Map<String, String> _currencyNames = {
    'USD': 'Dólar Estadounidense',
    'EUR': 'Euro',
    'MLC': 'Moneda Libre Convertible',
    'USDT_TRC20': 'Tether (USDT) TRC-20',
    'TRX': 'TRON',
    'BNB': 'Binance Coin',
  };

  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'MLC': 'MLC',
    'USDT_TRC20': 'USDT',
    'TRX': 'TRX',
    'BNB': 'BNB',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _currencyNames[currency] ?? currency;
    final symbol = _currencySymbols[currency] ?? currency;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _currencyIcon(currency, theme),
                      const SizedBox(width: 10),
                      Text(
                        currency,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${rate.toStringAsFixed(2)} CUP',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'por 1 $symbol',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currencyIcon(String currency, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.colorScheme.primaryContainer;
    final textColor = theme.colorScheme.primary;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _currencySymbols[currency]?.take(2) ?? currency.take(2),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ─── SHIMMER CARD (Loading placeholder) ─────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  final ThemeData theme;
  const _ShimmerCard({required this.theme});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final baseColor = theme.colorScheme.surfaceVariant;
    final highlightColor = theme.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _shimmerBox(34, 34, baseColor, highlightColor, borderRadius: 10),
                          const SizedBox(width: 10),
                          _shimmerBox(60, 16, baseColor, highlightColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _shimmerBox(110, 12, baseColor, highlightColor),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _shimmerBox(80, 18, baseColor, highlightColor),
                      const SizedBox(height: 4),
                      _shimmerBox(50, 12, baseColor, highlightColor),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h, Color base, Color highlight, {double borderRadius = 6}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (ctx, child) {
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Color.lerp(base, highlight, (_animation.value + 1) / 3.0)!,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }
}

// Utility extension
extension IterableIndexed<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T element) f) {
    var index = 0;
    return map((element) => f(index++, element));
  }
}

extension StringTake on String {
  String take(int n) => length <= n ? this : substring(0, n);
}