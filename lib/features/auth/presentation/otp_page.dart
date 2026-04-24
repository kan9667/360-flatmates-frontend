import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import '../../../l10n/gen/app_localizations.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({required this.phone, super.key});

  final String phone;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
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
              locale.otpTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(locale.otpSubtitle(widget.phone)),
            const SizedBox(height: 24),
            TextField(
              key: const Key('otp_input'),
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: locale.otpCodeLabel),
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
              key: const Key('otp_submit_button'),
              onPressed: auth.status == AuthStatus.submitting
                  ? null
                  : () {
                      ref
                          .read(authControllerProvider.notifier)
                          .verifyOtp(
                            phone: widget.phone,
                            otp: _otpController.text.trim(),
                          );
                    },
              child: Text(locale.verifyOtpCta),
            ),
          ],
        ),
      ),
    );
  }
}
