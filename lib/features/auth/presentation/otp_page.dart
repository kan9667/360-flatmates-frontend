import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../auth_controller.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import 'widgets/resend_countdown.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({this.phone = '', this.email, super.key});

  final String phone;

  /// When set, this is an **email** OTP screen (6-digit `OtpType.email`).
  final String? email;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage>
    with CodeAutoFill, ResendCountdownMixin {
  final _otpKey = GlobalKey<FlatmatesOtpInputState>();
  bool _isListening = false;

  bool get _isEmail => widget.email != null && widget.email!.trim().isNotEmpty;

  String get _email => widget.email?.trim() ?? '';

  String get _phone => widget.phone.isNotEmpty
      ? widget.phone
      : (ref.read(pendingPhoneProvider) ?? '');

  String _watchedPhone(WidgetRef ref) => widget.phone.isNotEmpty
      ? widget.phone
      : (ref.watch(pendingPhoneProvider) ?? '');

  @override
  void initState() {
    super.initState();
    if (!_isEmail) {
      _startListeningForSms();
    }
    startResendCountdown();
  }

  @override
  void dispose() {
    cancelResendCountdown();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      _fillOtp(code!);
    }
  }

  Future<void> _startListeningForSms() async {
    try {
      await SmsAutoFill().listenForCode();
      if (mounted) {
        setState(() => _isListening = true);
      }
    } catch (e) {
      debugPrint(
        'OtpPage._startListeningForSms: SMS auto-fill unavailable: $e',
      );
    }
  }

  void _fillOtp(String otp) {
    _otpKey.currentState?.fillOtp(otp);
  }

  void _submitOtp() {
    final auth = ref.read(authControllerProvider);
    if (auth.status == AuthStatus.submitting) return;
    final notifier = ref.read(authControllerProvider.notifier);
    if (_isEmail) {
      notifier.verifyEmailOtp(email: _email, otp: _otpKey.currentState?.otp ?? '');
    } else {
      notifier.verifyOtp(phone: _phone, otp: _otpKey.currentState?.otp ?? '');
    }
  }

  Future<void> _resendOtp() async {
    if (!canResend) return;
    final notifier = ref.read(authControllerProvider.notifier);
    if (_isEmail) {
      await notifier.sendEmailOtp(_email, isSignup: false);
    } else {
      await notifier.requestOtp(_phone);
    }
    if (mounted) {
      final auth = ref.read(authControllerProvider);
      if (auth.status != AuthStatus.error) {
        startResendCountdown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isSuccess = auth.status == AuthStatus.authenticated;

    return FlatmatesScreen(
      appBar: AppBar(),
      scrollable: true,
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.otpTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(locale.otpSubtitle(_isEmail ? _email : _watchedPhone(ref))),
            if (_isListening) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                locale.otpAutoReadHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
            ],
            if (isSuccess) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: FlatmatesTrustBadge(
                  label: locale.phoneVerifiedLabel,
                  compact: true,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.screen),
            FlatmatesOtpInput(
              key: _otpKey,
              onCompleted: (_) => _submitOtp(),
            ),
            if (auth.status == AuthStatus.error &&
                auth.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                resolveAuthError(auth.errorMessage, locale),
                style: const TextStyle(color: AppSemanticColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.screen),
            Center(
              child: !canResend
                  ? Text(
                      locale.resendOtpCountdown(resendSecondsRemaining),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                    )
                  : FlatmatesButton.tertiary(
                      label: locale.resendOtpCta,
                      onPressed: auth.status == AuthStatus.submitting
                          ? null
                          : _resendOtp,
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FlatmatesButton(
              key: const Key('otp_submit_button'),
              label: locale.verifyOtpCta,
              fullWidth: true,
              onPressed: auth.status == AuthStatus.submitting
                  ? null
                  : _submitOtp,
            ),
          ],
        ),
      ),
    );
  }
}
