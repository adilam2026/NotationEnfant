import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Six-box numeric code input. Implemented as a single, normally-editable
/// (but invisible) [TextField] skinned with six boxes drawn on top — this
/// gets native cursor/backspace/paste behavior for free instead of
/// juggling focus across six separate fields.
class OtpCodeField extends StatefulWidget {
  static const length = 6;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String> onCompleted;
  final String? errorText;

  const OtpCodeField({
    super.key,
    this.onChanged,
    required this.onCompleted,
    this.errorText,
  });

  @override
  State<OtpCodeField> createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChange);
  }

  void _handleChange() {
    setState(() {}); // repaint the digit boxes to match the controller text
    final value = _controller.text;
    widget.onChanged?.call(value);
    if (value.length == OtpCodeField.length) {
      widget.onCompleted(value);
    }
  }

  /// Clears the code and refocuses — used after a failed attempt.
  void clear() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text;
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: SizedBox(
        height: 56,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(OtpCodeField.length, (i) {
                    final char = i < value.length ? value[i] : '';
                    final isCursor = i == value.length;
                    return _digitBox(char, isCursor);
                  }),
                ),
              ),
            ),
            Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: OtpCodeField.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _digitBox(String char, bool isCursor) {
    final hasError = widget.errorText != null;
    return Container(
      width: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? AppColors.softRedDark
              : (isCursor ? AppColors.mintDark : const Color(0xFFEDEBE6)),
          width: isCursor || hasError ? 2 : 1,
        ),
      ),
      child: Text(
        char,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
