import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import '../../shared/presentation/flatmates_header.dart';
import '../../shared/presentation/flatmates_toast.dart';
import '../application/payments_controller.dart';
import '../data/payment_method_dto.dart';

/// Placeholder form for adding a new payment method.
///
/// Real Razorpay integration requires capturing the card via Razorpay.js
/// (web) or the `razorpay_flutter` plugin (mobile), which then yields a
/// `razorpay_token`. This screen is the API surface only: it accepts a
/// token + last4 + brand and forwards them to `POST /payments/methods`.
///
/// Replace the form fields with the real SDK callbacks once the platform
/// channel is in place.
class AddPaymentMethodPage extends ConsumerStatefulWidget {
  const AddPaymentMethodPage({super.key});

  @override
  ConsumerState<AddPaymentMethodPage> createState() =>
      _AddPaymentMethodPageState();
}

class _AddPaymentMethodPageState extends ConsumerState<AddPaymentMethodPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _last4Controller = TextEditingController();
  final _tokenController = TextEditingController();
  final _paymentIdController = TextEditingController();
  String _brand = 'card';
  bool _isDefault = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _last4Controller.dispose();
    _tokenController.dispose();
    _paymentIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final locale = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      await ref.read(paymentMethodsControllerProvider.notifier).add(
            PaymentMethodCreateDto(
              methodType: 'card',
              brand: _brand,
              last4: _last4Controller.text.trim(),
              razorpayToken: _tokenController.text.trim(),
              razorpayPaymentId: _paymentIdController.text.trim().isEmpty
                  ? null
                  : _paymentIdController.text.trim(),
              nickname: _nicknameController.text.trim().isEmpty
                  ? null
                  : _nicknameController.text.trim(),
              isDefault: _isDefault,
            ),
          );
      if (!mounted) return;
      FlatmatesToast.success(context, locale.addPaymentMethodCta);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.paymentMethodsAddFailed;
      FlatmatesToast.error(context, msg);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return Scaffold(
      appBar: FlatmatesHeader.backTitle(
        title: locale.addPaymentMethodCta,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: locale.paymentMethodNicknameLabel,
                    hintText: locale.paymentMethodNicknameHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _brand,
                  decoration: InputDecoration(
                    labelText: locale.paymentMethodBrandCard,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(
                      value: 'netbanking',
                      child: Text('Net banking'),
                    ),
                    DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _brand = value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _last4Controller,
                  decoration: const InputDecoration(
                    labelText: 'Last 4 digits',
                    hintText: '1234',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    if (value.trim().length != 4 ||
                        int.tryParse(value.trim()) == null) {
                      return 'Must be 4 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Razorpay token',
                    hintText: 'tok_…',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _paymentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Razorpay payment id (optional)',
                    hintText: 'pay_…',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile.adaptive(
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                  title: Text(locale.paymentMethodSetDefaultCta),
                ),
                const SizedBox(height: AppSpacing.xl),
                FlatmatesButton(
                  label: locale.commonSave,
                  onPressed: _submitting ? null : _submit,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
