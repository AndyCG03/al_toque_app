// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasas_eltoque/core/cubit/rates_cubit.dart';
import 'package:tasas_eltoque/core/services/api_service.dart';
import 'package:tasas_eltoque/core/services/local_storage_service.dart';
import 'package:tasas_eltoque/core/theme/app_theme.dart';
import 'package:tasas_eltoque/core/theme/theme_cubit.dart';
import 'package:tasas_eltoque/features/calculator/presentation/screens/calculator_screen.dart';
import 'package:tasas_eltoque/features/rates/presentation/screens/rates_screen.dart';
import 'package:tasas_eltoque/features/settings/presentation/screens/settings_screen.dart';

class TasasApp extends StatelessWidget {
  final ThemeCubit themeCubit;
  final LocalStorageService localStorage;

  const TasasApp({
    super.key,
    required this.themeCubit,
    required this.localStorage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<RatesCubit>(
          create: (_) => RatesCubit(
            apiService: ApiService(),
            localStorage: localStorage,
          ),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Tasas elTOQUE',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            home: const _HomeScreen(),
          );
        },
      ),
    );
  }
}

// ─── HOME SCREEN con NavigationBar ───────────────────────────────────────────

class _HomeScreen extends StatefulWidget {
  const _HomeScreen({super.key});

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  int _selectedIndex = 0;

  // Usar IndexedStack para mantener el estado de cada pantalla
  static final List<Widget> _screens = const [
    RatesScreen(),
    CalculatorScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeCubit = context.read<ThemeCubit>();

    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(context, themeCubit),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange_rounded),
            label: 'Tasas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate_rounded),
            label: 'Calculadora',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Opciones',
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeCubit themeCubit) {
    final theme = Theme.of(context);
    final isDark = themeCubit.isDark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo / Título con iconos de Flutter
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.currency_exchange_rounded,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'alTOQUE',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Toggle oscuro/claro (parte superior derecha)
              InkWell(
                onTap: () => themeCubit.toggle(),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: Tween<double>(begin: 0.25, end: 0.0).animate(animation),
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        key: ValueKey(isDark),
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}