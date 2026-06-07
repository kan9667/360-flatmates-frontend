import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class FlatmatesOtpInput extends StatefulWidget {
  const FlatmatesOtpInput({
    required this.onCompleted,
    this.digitCount = 6,
    this.keyPrefix = 'otp',
    super.key,
  });

  final int digitCount;
  final String keyPrefix;
  final void Function(String otp) onCompleted;

  @override
  FlatmatesOtpInputState createState() => FlatmatesOtpInputState();
}

class FlatmatesOtpInputState extends State<FlatmatesOtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.digitCount,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.digitCount,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get otp =>
      _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
      value = _controllers[index].text;
    }

    if (value.isNotEmpty && index < widget.digitCount - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (otp.length == widget.digitCount) {
      _focusNodes[widget.digitCount - 1].unfocus();
      widget.onCompleted(otp);
    }
  }

  void _onDigitDeleted(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  void fillOtp(String otp) {
    for (var i = 0; i < widget.digitCount; i++) {
      if (i < otp.length) {
        _controllers[i].text = otp[i];
      } else {
        _controllers[i].clear();
      }
    }
    if (otp.length == widget.digitCount) {
      _focusNodes[widget.digitCount - 1].unfocus();
      widget.onCompleted(otp);
    } else if (otp.length < widget.digitCount && otp.isNotEmpty) {
      _focusNodes[otp.length].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gapCount = widget.digitCount - 1;
        const gap = AppSpacing.sm;
        const maxBoxWidth = AppSpacing.screen + AppSpacing.section;
        final boxWidth = ((constraints.maxWidth - gap * gapCount) / widget.digitCount)
            .clamp(0, maxBoxWidth)
            .toDouble();
        final fontSize = boxWidth >= AppSpacing.screen + AppSpacing.xl
            ? AppTypography.h2Size
            : AppTypography.h3SizeLarge;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.digitCount, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index < gapCount ? gap : 0,
              ),
              child: SizedBox(
                width: boxWidth,
                height: boxWidth + AppSpacing.sm,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event.logicalKey.keyLabel == 'Backspace' ||
                        event.logicalKey.keyLabel == 'Delete') {
                      _onDigitDeleted(index);
                    }
                  },
                  child: TextField(
                    key: Key('${widget.keyPrefix}_digit_$index'),
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    autofillHints: index == 0
                        ? const [AutofillHints.oneTimeCode]
                        : null,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: fontSize,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBorder,
                        borderSide: BorderSide(
                          color: AppSemanticColors.line,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBorder,
                        borderSide: BorderSide(
                          color: AppSemanticColors.accent,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBorder,
                        borderSide: BorderSide(
                          color: AppSemanticColors.error,
                        ),
                      ),
                    ),
                    onChanged: (value) => _onDigitChanged(index, value),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
