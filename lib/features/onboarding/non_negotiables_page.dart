import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class NonNegotiablesPage extends ConsumerStatefulWidget {
  const NonNegotiablesPage({required this.onComplete, super.key});

  final void Function(List<String> nonNegotiables) onComplete;

  @override
  ConsumerState<NonNegotiablesPage> createState() => _NonNegotiablesPageState();
}

class _NonNegotiablesPageState extends ConsumerState<NonNegotiablesPage> {
  final _selected = <String>{};

  static const _options = [
    _NonNegOption(key: 'food_veg_only', icon: Icons.restaurant_outlined),
    _NonNegOption(key: 'food_vegan_only', icon: Icons.eco_outlined),
    _NonNegOption(key: 'no_smoking', icon: Icons.smoke_free_outlined),
    _NonNegOption(key: 'no_drinking', icon: Icons.no_drinks_outlined),
    _NonNegOption(key: 'no_overnight_guests', icon: Icons.bed_outlined),
    _NonNegOption(key: 'no_pets', icon: Icons.pets_outlined),
    _NonNegOption(key: 'gender_female_only', icon: Icons.female_outlined),
    _NonNegOption(key: 'gender_male_only', icon: Icons.male_outlined),
    _NonNegOption(key: 'no_parties', icon: Icons.music_off_outlined),
    _NonNegOption(key: 'min_tidy', icon: Icons.cleaning_services_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              locale.nonNegotiablesTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              locale.nonNegotiablesSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            InfoPill(
              icon: Icons.info_outline,
              label: locale.nonNegotiablesLimit,
              highlighted: true,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _options.map((opt) {
                final isSelected = _selected.contains(opt.key);
                return FilterChip(
                  key: Key('non_neg_${opt.key}'),
                  avatar: Icon(opt.icon, size: 18),
                  label: Text(_label(locale, opt.key)),
                  selected: isSelected,
                  onSelected: isSelected
                      ? (_) => setState(() => _selected.remove(opt.key))
                      : _selected.length < 3
                          ? (_) => setState(() => _selected.add(opt.key))
                          : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            GradientActionButton(
              key: const Key('onboarding_non_neg_done'),
              label: locale.onboardingComplete,
              onPressed: () => widget.onComplete(_selected.toList()),
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }

  String _label(AppLocalizations locale, String key) {
    switch (key) {
      case 'food_veg_only':
        return locale.nonNegVegOnly;
      case 'food_vegan_only':
        return locale.nonNegVeganOnly;
      case 'no_smoking':
        return locale.nonNegNoSmoking;
      case 'no_drinking':
        return locale.nonNegNoDrinking;
      case 'no_overnight_guests':
        return locale.nonNegNoGuests;
      case 'no_pets':
        return locale.nonNegNoPets;
      case 'gender_female_only':
        return locale.nonNegFemaleOnly;
      case 'gender_male_only':
        return locale.nonNegMaleOnly;
      case 'no_parties':
        return locale.nonNegNoParties;
      case 'min_tidy':
        return locale.nonNegMinTidy;
      default:
        return key;
    }
  }
}

class _NonNegOption {
  const _NonNegOption({required this.key, required this.icon});

  final String key;
  final IconData icon;
}
