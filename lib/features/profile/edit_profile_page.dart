import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import 'profile_repository.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _cityController = TextEditingController();
  final _localityController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _bioController = TextEditingController();
  String _mode = 'open_to_both';
  String _workStyle = 'hybrid';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = ref.read(bootstrapControllerProvider).valueOrNull?.profile;
    if (profile != null && _cityController.text.isEmpty) {
      _cityController.text = profile.city ?? '';
      _localityController.text = profile.locality ?? '';
      _budgetMinController.text = profile.budgetMin?.toStringAsFixed(0) ?? '';
      _budgetMaxController.text = profile.budgetMax?.toStringAsFixed(0) ?? '';
      _bioController.text = profile.bio ?? '';
      _mode = profile.mode ?? _mode;
      _workStyle = profile.workStyle ?? _workStyle;
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _localityController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    String? nullableText(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    return Scaffold(
      appBar: AppBar(title: Text(locale.editProfileCta)),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              key: const Key('profile_mode_input'),
              initialValue: _mode,
              decoration: InputDecoration(labelText: locale.modeTitle),
              items: const [
                DropdownMenuItem(
                  value: 'room_poster',
                  child: Text('Room Poster'),
                ),
                DropdownMenuItem(value: 'seeker', child: Text('Seeker')),
                DropdownMenuItem(value: 'co_hunter', child: Text('Co-Hunter')),
                DropdownMenuItem(
                  value: 'open_to_both',
                  child: Text('Open To Both'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _mode = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('profile_city_input'),
              controller: _cityController,
              decoration: InputDecoration(labelText: locale.cityLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('profile_locality_input'),
              controller: _localityController,
              decoration: InputDecoration(labelText: locale.localityLabel),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('profile_budget_min_input'),
                    controller: _budgetMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: locale.budgetMinLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const Key('profile_budget_max_input'),
                    controller: _budgetMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: locale.budgetMaxLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('profile_work_style_input'),
              initialValue: _workStyle,
              decoration: InputDecoration(labelText: locale.workStyleTitle),
              items: const [
                DropdownMenuItem(value: 'office', child: Text('Office')),
                DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                DropdownMenuItem(value: 'wfh', child: Text('WFH')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _workStyle = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('profile_bio_input'),
              controller: _bioController,
              maxLines: 4,
              decoration: InputDecoration(labelText: locale.bioLabel),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('profile_save_button'),
              onPressed: () async {
                try {
                  await ref
                      .read(profileRepositoryProvider)
                      .updateProfile(
                        payload: {
                          'mode': _mode,
                          'city': nullableText(_cityController),
                          'locality': nullableText(_localityController),
                          'budget_min': double.tryParse(
                            _budgetMinController.text.trim(),
                          ),
                          'budget_max': double.tryParse(
                            _budgetMaxController.text.trim(),
                          ),
                          'work_style': _workStyle,
                          'bio': nullableText(_bioController),
                          'onboarding_completed': true,
                        },
                      );
                  await ref.read(bootstrapControllerProvider.notifier).load();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e is DioException
                              ? e.error.toString()
                              : 'Failed to save profile. Please try again.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(locale.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
