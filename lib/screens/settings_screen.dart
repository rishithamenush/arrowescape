import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/game_state.dart';
import '../widgets/app_background.dart';
import '../widgets/hud.dart';

/// Sound / music / vibration toggles plus store and legal links.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    final p = state.progress;

    return Scaffold(
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      'Settings',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _Group(
                        children: [
                          _ToggleRow(
                            icon: Icons.volume_up_rounded,
                            label: 'Sound effects',
                            value: p.soundOn,
                            onChanged: (_) => state.toggleSound(),
                          ),
                          _ToggleRow(
                            icon: Icons.music_note_rounded,
                            label: 'Music',
                            value: p.musicOn,
                            onChanged: (_) => state.toggleMusic(),
                          ),
                          _ToggleRow(
                            icon: Icons.vibration_rounded,
                            label: 'Vibration',
                            value: p.vibrationOn,
                            onChanged: (_) => state.toggleVibration(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _Group(
                        children: [
                          _LinkRow(
                            icon: Icons.language_rounded,
                            label: 'Language',
                            trailing: 'English',
                            onTap: () {},
                          ),
                          _LinkRow(
                            icon: Icons.restore_rounded,
                            label: 'Restore purchases',
                            onTap: () {},
                          ),
                          _LinkRow(
                            icon: Icons.privacy_tip_rounded,
                            label: 'Privacy policy',
                            onTap: () {},
                          ),
                          _LinkRow(
                            icon: Icons.star_rate_rounded,
                            label: 'Rate us',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Center(
                child: Text(
                  'Arrow Escape v1.0.0',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.card(),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
