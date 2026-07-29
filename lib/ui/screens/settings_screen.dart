import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/design_system.dart';
import '../widgets/glassmorphism_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ustawienia'),
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
            _buildSection(
              title: 'Detekcja',
              children: [
                _buildSliderSetting(
                  title: 'Czułość detekcji',
                  subtitle: 'Minimalna pewność detekcji',
                  value: 0.6,
                  min: 0.3,
                  max: 0.9,
                  onChanged: (value) {},
                ),
                _buildToggleSetting(
                  title: 'Detekcja pieszych',
                  subtitle: 'Wykrywaj pieszych na drodze',
                  value: true,
                  onChanged: (value) {},
                ),
                _buildToggleSetting(
                  title: 'Detekcja pojazdów',
                  subtitle: 'Wykrywaj samochody, ciężarówki, motocykle',
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildSection(
              title: 'Alerty',
              children: [
                _buildToggleSetting(
                  title: 'Alerty dźwiękowe',
                  subtitle: 'Odtwarzaj dźwięk przy zagrożeniu',
                  value: true,
                  onChanged: (value) {},
                ),
                _buildToggleSetting(
                  title: 'Wibracje',
                  subtitle: 'Wibruj przy krytycznych alertach',
                  value: true,
                  onChanged: (value) {},
                ),
                _buildSliderSetting(
                  title: 'Głośność alertów',
                  subtitle: 'Poziom głośności dźwięków',
                  value: 0.8,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildSection(
              title: 'Bezpieczeństwo',
              children: [
                _buildInfoTile(
                  icon: Icons.shield_outlined,
                  title: 'Prywatność',
                  subtitle: 'Wszystkie dane przetwarzane lokalnie',
                  color: AppColors.success,
                ),
                _buildInfoTile(
                  icon: Icons.videocam_outlined,
                  title: 'Kamera',
                  subtitle: 'Nagrywanie wyłączone',
                  color: AppColors.primary,
                ),
                _buildInfoTile(
                  icon: Icons.location_on_outlined,
                  title: 'Lokalizacja',
                  subtitle: 'Używana do nawigacji i alertów',
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildSection(
              title: 'O aplikacji',
              children: [
                _buildInfoTile(
                  icon: Icons.info_outline,
                  title: 'Wersja',
                  subtitle: '1.0.0 (build 1)',
                  color: AppColors.textSecondary,
                ),
                _buildInfoTile(
                  icon: Icons.code,
                  title: 'Licencja',
                  subtitle: 'MIT License',
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.md,
          ),
          child: Text(
            title,
            style: AppTypography.h3.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        GlassmorphismCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: children.map((child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border,
                      width: 0.5,
                    ),
                  ),
                ),
                child: child,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.surfaceLight,
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
