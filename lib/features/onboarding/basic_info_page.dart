import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class BasicInfoPage extends ConsumerStatefulWidget {
  const BasicInfoPage({required this.onNext, super.key});

  final void Function(Map<String, dynamic> data) onNext;

  @override
  ConsumerState<BasicInfoPage> createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends ConsumerState<BasicInfoPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _professionController = TextEditingController();
  final _cityController = TextEditingController();
  final _localityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _professionController.dispose();
    _cityController.dispose();
    _localityController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _nameController.text.trim().isNotEmpty &&
        _ageController.text.trim().isNotEmpty &&
        int.tryParse(_ageController.text.trim()) != null &&
        int.parse(_ageController.text.trim()) >= 18 &&
        _professionController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty;
  }

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
              locale.basicInfoTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              locale.basicInfoSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              key: const Key('onboarding_name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: locale.fullNameLabel,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('onboarding_age'),
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: locale.ageLabel,
                prefixIcon: const Icon(Icons.cake_outlined),
                helperText: locale.ageHelperText,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('onboarding_profession'),
              controller: _professionController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: locale.professionLabel,
                prefixIcon: const Icon(Icons.work_outline),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('onboarding_city'),
              controller: _cityController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: locale.cityLabel,
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('onboarding_locality'),
              controller: _localityController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: locale.localityLabel,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 32),
            GradientActionButton(
              key: const Key('onboarding_basic_info_next'),
              label: locale.onboardingNext,
              onPressed: _isValid
                  ? () => widget.onNext({
                        'full_name': _nameController.text.trim(),
                        'age': int.parse(_ageController.text.trim()),
                        'profession': _professionController.text.trim(),
                        'city': _cityController.text.trim(),
                        'locality': _localityController.text.trim().isEmpty
                            ? null
                            : _localityController.text.trim(),
                      })
                  : null,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
