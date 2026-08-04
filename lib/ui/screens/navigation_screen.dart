import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/design_system.dart';
import '../widgets/glassmorphism_card.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  String _destination = '';
  bool _isNavigating = false;

  final List<Map<String, dynamic>> _savedPlaces = [
    {'name': 'Dom', 'address': 'ul. Floriańska 15, Kraków', 'icon': Icons.home},
    {'name': 'Praca', 'address': 'ul. Wielicka 10, Kraków', 'icon': Icons.work},
    {'name': 'Siłownia', 'address': 'ul. Dietla 25, Kraków', 'icon': Icons.fitness_center},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nawigacja'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: AppSpacing.xl),
            _buildSavedPlaces(),
            const SizedBox(height: AppSpacing.xl),
            _buildMapPlaceholder(),
            const SizedBox(height: AppSpacing.xl),
            if (_isNavigating) _buildNavigationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dokąd chcesz jechać?',
            style: AppTypography.h3.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            onChanged: (value) {
              setState(() {
                _destination = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Wpisz adres lub miejsce...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.glass,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_destination.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isNavigating = true;
                  });
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Rozpocznij nawigację'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSavedPlaces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.md,
          ),
          child: Text(
            'Zapisane miejsca',
            style: AppTypography.h3.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        ..._savedPlaces.map((place) => _buildPlaceCard(place)).toList(),
      ],
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassmorphismCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                place['icon'] as IconData,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['name'] as String,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place['address'] as String,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.navigation, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _destination = place['name'] as String;
                  _isNavigating = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return GlassmorphismCard(
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Mapa Mapbox',
                    style: AppTypography.body,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Wymaga konfiguracji API key',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationInfo() {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.navigation,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nawigacja do: $_destination',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Szacowany czas: 15 min',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () {
                  setState(() {
                    _isNavigating = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildNavStat(
                  icon: Icons.straighten,
                  label: '12.4 km',
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildNavStat(
                  icon: Icons.timer,
                  label: '15 min',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildNavStat(
                  icon: Icons.speed,
                  label: '50 km/h',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavStat({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
