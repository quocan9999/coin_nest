import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MoneyAmountInput {
  MoneyAmountInput._();

  static String formatAmount(num amount) {
    final digits = amount.round().toString();
    return formatDigits(digits);
  }

  static String formatDigits(String digits) {
    final cleaned = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return '';

    final buffer = StringBuffer();
    for (var i = 0; i < cleaned.length; i++) {
      final remaining = cleaned.length - i;
      buffer.write(cleaned[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  static bool needsEvaluation(String text) {
    final expression = rawExpression(text);
    return expression.isNotEmpty && _containsOperator(expression);
  }

  static bool finalizeExpression({
    required BuildContext context,
    required TextEditingController controller,
    required VoidCallback refresh,
    required bool showError,
  }) {
    final expression = rawExpression(controller.text);
    if (expression.isEmpty || !_containsOperator(expression)) {
      controller.text = formatDigits(expression);
      refresh();
      return true;
    }

    final amount = _evaluateExpression(expression);
    if (amount == null || amount <= 0) {
      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biểu thức số tiền không hợp lệ')),
        );
      }
      return false;
    }

    controller.text = formatAmount(amount);
    refresh();
    return true;
  }

  static void handleKey({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required MoneyAmountKeyboardKey key,
    required VoidCallback refresh,
  }) {
    switch (key.type) {
      case MoneyAmountKeyboardKeyType.digit:
        _appendToken(controller, key.value, refresh);
        break;
      case MoneyAmountKeyboardKeyType.operator:
        _appendOperator(controller, key.value, refresh);
        break;
      case MoneyAmountKeyboardKeyType.clear:
        controller.clear();
        refresh();
        break;
      case MoneyAmountKeyboardKeyType.backspace:
        _deleteToken(controller, refresh);
        break;
      case MoneyAmountKeyboardKeyType.done:
        if (needsEvaluation(controller.text)) {
          finalizeExpression(
            context: context,
            controller: controller,
            refresh: refresh,
            showError: true,
          );
        } else {
          focusNode.unfocus();
        }
        break;
      case MoneyAmountKeyboardKeyType.spacer:
        break;
    }
  }

  static String rawExpression(String text) {
    return text
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('đ', '')
        .replaceAll('₫', '');
  }

  static void _appendToken(
    TextEditingController controller,
    String token,
    VoidCallback refresh,
  ) {
    final expression = rawExpression(controller.text);
    final nextExpression = expression == '0' ? token : '$expression$token';
    _setExpression(controller, nextExpression, refresh);
  }

  static void _appendOperator(
    TextEditingController controller,
    String operator,
    VoidCallback refresh,
  ) {
    final expression = rawExpression(controller.text);
    if (expression.isEmpty) return;

    final nextExpression = _endsWithOperator(expression)
        ? '${expression.substring(0, expression.length - 1)}$operator'
        : '$expression$operator';
    _setExpression(controller, nextExpression, refresh);
  }

  static void _deleteToken(
    TextEditingController controller,
    VoidCallback refresh,
  ) {
    final expression = rawExpression(controller.text);
    if (expression.isEmpty) return;

    _setExpression(
      controller,
      expression.substring(0, expression.length - 1),
      refresh,
    );
  }

  static void _setExpression(
    TextEditingController controller,
    String expression,
    VoidCallback refresh,
  ) {
    controller.text = _formatExpression(expression);
    refresh();
  }

  static bool _containsOperator(String expression) {
    return RegExp(r'[+\-*/]').hasMatch(expression);
  }

  static bool _endsWithOperator(String expression) {
    return expression.isNotEmpty && RegExp(r'[+\-*/]$').hasMatch(expression);
  }

  static String _formatExpression(String expression) {
    final buffer = StringBuffer();
    final currentNumber = StringBuffer();

    void flushNumber() {
      if (currentNumber.isEmpty) return;
      buffer.write(formatDigits(currentNumber.toString()));
      currentNumber.clear();
    }

    for (final char in expression.split('')) {
      if (RegExp(r'\d').hasMatch(char)) {
        currentNumber.write(char);
      } else {
        flushNumber();
        buffer.write(_displayOperator(char));
      }
    }

    flushNumber();
    return buffer.toString();
  }

  static String _displayOperator(String operator) {
    switch (operator) {
      case '*':
        return ' × ';
      case '/':
        return ' ÷ ';
      case '+':
      case '-':
        return ' $operator ';
      default:
        return operator;
    }
  }

  static int? _evaluateExpression(String expression) {
    if (_endsWithOperator(expression)) return null;

    final tokens = RegExp(
      r'\d+|[+\-*/]',
    ).allMatches(expression).map((match) => match.group(0)!).toList();

    if (tokens.isEmpty || tokens.length.isEven) return null;

    final values = <double>[double.parse(tokens.first)];
    final operators = <String>[];

    for (var i = 1; i < tokens.length; i += 2) {
      final operator = tokens[i];
      final value = double.tryParse(tokens[i + 1]);
      if (value == null) return null;

      if (operator == '*' || operator == '/') {
        if (operator == '/' && value == 0) return null;
        final previous = values.removeLast();
        values.add(operator == '*' ? previous * value : previous / value);
      } else {
        operators.add(operator);
        values.add(value);
      }
    }

    var result = values.first;
    for (var i = 0; i < operators.length; i++) {
      result = operators[i] == '+'
          ? result + values[i + 1]
          : result - values[i + 1];
    }

    if (!result.isFinite || result <= 0) return null;
    return result.round();
  }
}

class MoneyAmountField extends StatelessWidget {
  const MoneyAmountField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.validator,
    this.textStyle,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.none,
      showCursor: true,
      validator: validator,
      style: textStyle,
      decoration: const InputDecoration(hintText: '0', suffixText: ''),
    );
  }
}

class MoneyAmountKeyboardPanel extends StatelessWidget {
  const MoneyAmountKeyboardPanel({
    super.key,
    required this.isVisible,
    required this.onKeyPressed,
    required this.shouldEvaluate,
    this.onScanReceipt,
  });

  final bool isVisible;
  final ValueChanged<MoneyAmountKeyboardKey> onKeyPressed;
  final bool shouldEvaluate;
  final VoidCallback? onScanReceipt;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return SafeArea(
      child: MoneyAmountKeyboard(
        onScanReceipt: onScanReceipt,
        onKeyPressed: onKeyPressed,
        shouldEvaluate: shouldEvaluate,
      ),
    );
  }
}

class MoneyAmountKeyboard extends StatelessWidget {
  static const double _keyHeight = AppTheme.spacing24;
  static const double _keyGap = AppTheme.spacing4;

  const MoneyAmountKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.shouldEvaluate,
    this.onScanReceipt,
  });

  final VoidCallback? onScanReceipt;
  final ValueChanged<MoneyAmountKeyboardKey> onKeyPressed;
  final bool shouldEvaluate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing8,
        AppTheme.spacing6,
        AppTheme.spacing8,
        AppTheme.spacing8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onScanReceipt != null) ...[
            Align(
              alignment: Alignment.center,
              child: FilledButton.tonalIcon(
                onPressed: onScanReceipt,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Scan ho\u00e1 \u0111\u01a1n'),
              ),
            ),
            const SizedBox(height: AppTheme.spacing6),
          ],
          _keyboardRow(context, [
            MoneyAmountKeyboardKey.clear(),
            MoneyAmountKeyboardKey.operator('*', '\u00d7'),
            MoneyAmountKeyboardKey.operator('/', '\u00f7'),
            MoneyAmountKeyboardKey.backspace(),
          ]),
          _keyboardRow(context, [
            MoneyAmountKeyboardKey.digit('7'),
            MoneyAmountKeyboardKey.digit('8'),
            MoneyAmountKeyboardKey.digit('9'),
            MoneyAmountKeyboardKey.operator('-', '-'),
          ]),
          _keyboardRow(context, [
            MoneyAmountKeyboardKey.digit('4'),
            MoneyAmountKeyboardKey.digit('5'),
            MoneyAmountKeyboardKey.digit('6'),
            MoneyAmountKeyboardKey.operator('+', '+'),
          ]),
          _keyboardRow(context, [
            MoneyAmountKeyboardKey.digit('1'),
            MoneyAmountKeyboardKey.digit('2'),
            MoneyAmountKeyboardKey.digit('3'),
            MoneyAmountKeyboardKey.spacer(),
          ]),
          _keyboardRow(context, [
            MoneyAmountKeyboardKey.digit('0'),
            MoneyAmountKeyboardKey.digit('000'),
            MoneyAmountKeyboardKey.backspace(),
            MoneyAmountKeyboardKey.done(shouldEvaluate ? '=' : 'Xong'),
          ], addBottomGap: false),
        ],
      ),
    );
  }

  Widget _keyboardRow(
    BuildContext context,
    List<MoneyAmountKeyboardKey> keys, {
    bool addBottomGap = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: addBottomGap ? _keyGap : 0),
      child: Row(
        children: [
          for (var index = 0; index < keys.length; index++) ...[
            Expanded(
              child: keys[index].type == MoneyAmountKeyboardKeyType.spacer
                  ? const SizedBox(height: _keyHeight)
                  : _keyboardButton(context, keys[index]),
            ),
            if (index != keys.length - 1) const SizedBox(width: _keyGap),
          ],
        ],
      ),
    );
  }

  Widget _keyboardButton(
    BuildContext context,
    MoneyAmountKeyboardKey key, {
    double height = _keyHeight,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = key.type == MoneyAmountKeyboardKeyType.done;

    return Material(
      color: isDone ? colorScheme.primary : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => onKeyPressed(key),
        child: SizedBox(
          height: height,
          child: Center(
            child: key.icon == null
                ? Text(
                    key.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDone
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Icon(
                    key.icon,
                    color: isDone
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }
}

class MoneyAmountKeyboardKey {
  const MoneyAmountKeyboardKey._({
    required this.type,
    required this.value,
    required this.label,
    this.icon,
  });

  final MoneyAmountKeyboardKeyType type;
  final String value;
  final String label;
  final IconData? icon;

  factory MoneyAmountKeyboardKey.digit(String value) {
    return MoneyAmountKeyboardKey._(
      type: MoneyAmountKeyboardKeyType.digit,
      value: value,
      label: value,
    );
  }

  factory MoneyAmountKeyboardKey.operator(String value, String label) {
    return MoneyAmountKeyboardKey._(
      type: MoneyAmountKeyboardKeyType.operator,
      value: value,
      label: label,
    );
  }

  factory MoneyAmountKeyboardKey.clear() {
    return const MoneyAmountKeyboardKey._(
      type: MoneyAmountKeyboardKeyType.clear,
      value: '',
      label: 'C',
    );
  }

  factory MoneyAmountKeyboardKey.backspace() {
    return const MoneyAmountKeyboardKey._(
      type: MoneyAmountKeyboardKeyType.backspace,
      value: '',
      label: '',
      icon: Icons.backspace_outlined,
    );
  }

  factory MoneyAmountKeyboardKey.done(String label) {
    return MoneyAmountKeyboardKey._(
      type: MoneyAmountKeyboardKeyType.done,
      value: '',
      label: label,
    );
  }

  factory MoneyAmountKeyboardKey.spacer() {
    return const MoneyAmountKeyboardKey._(
      type: MoneyAmountKeyboardKeyType.spacer,
      value: '',
      label: '',
    );
  }
}

enum MoneyAmountKeyboardKeyType {
  digit,
  operator,
  clear,
  backspace,
  done,
  spacer,
}
