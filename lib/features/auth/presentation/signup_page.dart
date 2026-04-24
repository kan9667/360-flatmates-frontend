import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import '../../../l10n/gen/app_localizations.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({required this.phone, super.key});

  final String? phone;

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone ?? '+91');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final locale = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.signupTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('signup_name_input'),
              controller: _nameController,
              decoration: InputDecoration(labelText: locale.fullNameLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('signup_email_input'),
              controller: _emailController,
              decoration: InputDecoration(labelText: locale.emailLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('signup_phone_input'),
              controller: _phoneController,
              decoration: InputDecoration(labelText: locale.phoneNumberLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('signup_password_input'),
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: locale.passwordLabel),
            ),
            if (auth.status == AuthStatus.error &&
                auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            FilledButton(
              key: const Key('signup_submit_button'),
              onPressed: auth.status == AuthStatus.submitting
                  ? null
                  : () {
                      ref
                          .read(authControllerProvider.notifier)
                          .signUpWithPassword(
                            fullName: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            password: _passwordController.text,
                            email: _emailController.text.trim(),
                          );
                    },
              child: Text(locale.createAccountCta),
            ),
          ],
        ),
      ),
    );
  }
}
