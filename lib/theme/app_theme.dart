import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CoinNest design system tokens.
class AppTheme {
  AppTheme._();

  // Brand colors
  static const Color primary = Color(0xFF00668A);
  static const Color primaryContainer = Color(0xFF29ABE2);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF003B53);

  // Income / positive
  static const Color secondary = Color(0xFF006E1C);
  static const Color secondaryContainer = Color(0xFF91F78E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF00731E);

  // Expense / negative
  static const Color tertiary = Color(0xFFBB1614);
  static const Color tertiaryContainer = Color(0xFFFF7666);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF750003);

  // Surfaces
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceDim = Color(0xFFDADADA);

  // On-surface
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF3E484F);

  // Outline
  static const Color outline = Color(0xFF6E7880);
  static const Color outlineVariant = Color(0xFFBDC8D0);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Inverse
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);
  static const Color inversePrimary = Color(0xFF7BD0FF);

  // Semantic aliases
  static const Color incomeColor = secondary;
  static const Color expenseColor = tertiary;
  static const Color transferColor = primary;
  static const Color loanColor = Color(0xFF8A5100);
  static const Color warningColor = Color(0xFF750003);

  static CoinNestColors colors(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<CoinNestColors>() ??
        (theme.brightness == Brightness.dark
            ? CoinNestColors.dark
            : CoinNestColors.light);
  }

  // Spacing
  static const double spacing2 = 4;
  static const double spacing4 = 8;
  static const double spacing6 = 12;
  static const double spacing8 = 16;
  static const double spacing10 = 20;
  static const double spacing12 = 24;
  static const double spacing16 = 32;
  static const double spacing20 = 40;
  static const double spacing24 = 48;

  // Radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  static ThemeData get lightTheme {
    final textTheme = _textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimary: onPrimary,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        onSecondary: onSecondary,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiary: onTertiary,
        onTertiaryContainer: onTertiaryContainer,
        surface: surface,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        error: error,
        errorContainer: errorContainer,
        onError: onError,
        onErrorContainer: onErrorContainer,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: inverseSurface,
        onInverseSurface: inverseOnSurface,
        inversePrimary: inversePrimary,
      ),
      scaffoldBackgroundColor: surface,
      cardColor: surfaceContainerLowest,
      canvasColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        selectedItemColor: primary,
        unselectedItemColor: outline,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: outlineVariant.withAlpha(38)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: outline.withAlpha(153)),
        labelStyle: const TextStyle(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLow,
        selectedColor: primaryContainer.withAlpha(51),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: outlineVariant.withAlpha(51),
        thickness: 1,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: inverseOnSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? onPrimary : outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : surfaceContainerHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : outlineVariant,
        ),
      ),
      extensions: const [CoinNestColors.light],
      textTheme: textTheme,
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _textTheme.apply(
      bodyColor: CoinNestColors.darkTextPrimary,
      displayColor: CoinNestColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: CoinNestColors.darkPrimary,
        primaryContainer: CoinNestColors.darkTransferBg,
        onPrimary: CoinNestColors.darkTextPrimary,
        onPrimaryContainer: CoinNestColors.darkTransferText,
        secondary: CoinNestColors.darkIncomeText,
        secondaryContainer: CoinNestColors.darkIncomeBg,
        onSecondary: CoinNestColors.darkBgApp,
        onSecondaryContainer: CoinNestColors.darkIncomeText,
        tertiary: CoinNestColors.darkExpenseText,
        tertiaryContainer: CoinNestColors.darkExpenseBg,
        onTertiary: CoinNestColors.darkBgApp,
        onTertiaryContainer: CoinNestColors.darkExpenseText,
        surface: CoinNestColors.darkBgApp,
        surfaceContainerLowest: CoinNestColors.darkBgCard,
        surfaceContainerLow: CoinNestColors.darkBgCard,
        surfaceContainer: CoinNestColors.darkBgInput,
        surfaceContainerHigh: CoinNestColors.darkBgBorder,
        surfaceContainerHighest: CoinNestColors.darkBgInput,
        onSurface: CoinNestColors.darkTextPrimary,
        onSurfaceVariant: CoinNestColors.darkTextSecondary,
        error: CoinNestColors.darkExpenseText,
        errorContainer: CoinNestColors.darkExpenseBg,
        onError: CoinNestColors.darkBgApp,
        onErrorContainer: CoinNestColors.darkExpenseText,
        outline: CoinNestColors.darkTextSecondary,
        outlineVariant: CoinNestColors.darkBgBorder,
        inverseSurface: CoinNestColors.darkTextPrimary,
        onInverseSurface: CoinNestColors.darkBgApp,
        inversePrimary: CoinNestColors.darkTransferText,
      ),
      scaffoldBackgroundColor: CoinNestColors.darkBgApp,
      cardColor: CoinNestColors.darkBgCard,
      canvasColor: CoinNestColors.darkBgApp,
      appBarTheme: AppBarTheme(
        backgroundColor: CoinNestColors.darkBgApp,
        foregroundColor: CoinNestColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: CoinNestColors.darkTransferText,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CoinNestColors.darkBgCard,
        selectedItemColor: CoinNestColors.darkTransferText,
        unselectedItemColor: CoinNestColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: CoinNestColors.darkBgCard,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CoinNestColors.darkTransferBg,
          foregroundColor: CoinNestColors.darkTextPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CoinNestColors.darkTransferText,
          side: const BorderSide(color: CoinNestColors.darkBgBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CoinNestColors.darkTransferText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CoinNestColors.darkBgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: CoinNestColors.darkTransferText,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: CoinNestColors.darkExpenseText,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: CoinNestColors.darkExpenseText,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: CoinNestColors.darkTextDisabled),
        labelStyle: const TextStyle(
          color: CoinNestColors.darkTextSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CoinNestColors.darkTransferBg,
        foregroundColor: CoinNestColors.darkTextPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CoinNestColors.darkBgInput,
        selectedColor: CoinNestColors.darkTransferBg,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: CoinNestColors.darkBgBorder,
        thickness: 0.5,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: CoinNestColors.darkBgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CoinNestColors.darkBgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CoinNestColors.darkBgInput,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: CoinNestColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? CoinNestColors.darkTextPrimary
              : CoinNestColors.darkTextSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? CoinNestColors.darkTransferBg
              : CoinNestColors.darkBgBorder,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : CoinNestColors.darkTextSecondary,
        ),
      ),
      extensions: const [CoinNestColors.dark],
      textTheme: textTheme,
    );
  }

  static TextTheme get _textTheme {
    return GoogleFonts.beVietnamProTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: onSurface,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: onSurface,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: onSurface,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: onSurfaceVariant,
        ),
      ),
    );
  }
}

@immutable
class CoinNestColors extends ThemeExtension<CoinNestColors> {
  const CoinNestColors({
    required this.surface,
    required this.card,
    required this.input,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.primary,
    required this.income,
    required this.incomeBg,
    required this.expense,
    required this.expenseBg,
    required this.transfer,
    required this.transferBg,
    required this.warning,
    required this.warningBg,
    required this.overdue,
    required this.overdueBg,
  });

  static const Color darkBgApp = Color(0xFF1A1A1E);
  static const Color darkBgCard = Color(0xFF252529);
  static const Color darkBgInput = Color(0xFF2E2E33);
  static const Color darkBgBorder = Color(0xFF3A3A40);
  static const Color darkTextPrimary = Color(0xFFE8E8EA);
  static const Color darkTextSecondary = Color(0xFFA0A0A8);
  static const Color darkTextDisabled = Color(0xFF606068);
  static const Color darkPrimary = Color(0xFF79BBF5);
  static const Color darkIncomeText = Color(0xFF7EC99A);
  static const Color darkIncomeBg = Color(0xFF1D6B3F);
  static const Color darkExpenseText = Color(0xFFF08080);
  static const Color darkExpenseBg = Color(0xFF7A2020);
  static const Color darkTransferText = Color(0xFF79BBF5);
  static const Color darkTransferBg = Color(0xFF1A4A7A);
  static const Color darkWarningText = Color(0xFFF5C469);
  static const Color darkWarningBg = Color(0xFF6B4A0E);
  static const Color darkOverdueText = Color(0xFFFF9999);
  static const Color darkOverdueBg = Color(0xFF6B1A1A);

  static const light = CoinNestColors(
    surface: AppTheme.surface,
    card: AppTheme.surfaceContainerLowest,
    input: AppTheme.surfaceContainerHighest,
    border: AppTheme.outlineVariant,
    textPrimary: AppTheme.onSurface,
    textSecondary: AppTheme.onSurfaceVariant,
    textDisabled: AppTheme.outline,
    primary: AppTheme.primary,
    income: AppTheme.secondary,
    incomeBg: AppTheme.secondaryContainer,
    expense: AppTheme.tertiary,
    expenseBg: AppTheme.tertiaryContainer,
    transfer: AppTheme.primary,
    transferBg: AppTheme.primaryContainer,
    warning: AppTheme.warningColor,
    warningBg: AppTheme.tertiaryContainer,
    overdue: AppTheme.error,
    overdueBg: AppTheme.errorContainer,
  );

  static const dark = CoinNestColors(
    surface: darkBgApp,
    card: darkBgCard,
    input: darkBgInput,
    border: darkBgBorder,
    textPrimary: darkTextPrimary,
    textSecondary: darkTextSecondary,
    textDisabled: darkTextDisabled,
    primary: darkPrimary,
    income: darkIncomeText,
    incomeBg: darkIncomeBg,
    expense: darkExpenseText,
    expenseBg: darkExpenseBg,
    transfer: darkTransferText,
    transferBg: darkTransferBg,
    warning: darkWarningText,
    warningBg: darkWarningBg,
    overdue: darkOverdueText,
    overdueBg: darkOverdueBg,
  );

  final Color surface;
  final Color card;
  final Color input;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color primary;
  final Color income;
  final Color incomeBg;
  final Color expense;
  final Color expenseBg;
  final Color transfer;
  final Color transferBg;
  final Color warning;
  final Color warningBg;
  final Color overdue;
  final Color overdueBg;

  @override
  CoinNestColors copyWith({
    Color? surface,
    Color? card,
    Color? input,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? primary,
    Color? income,
    Color? incomeBg,
    Color? expense,
    Color? expenseBg,
    Color? transfer,
    Color? transferBg,
    Color? warning,
    Color? warningBg,
    Color? overdue,
    Color? overdueBg,
  }) {
    return CoinNestColors(
      surface: surface ?? this.surface,
      card: card ?? this.card,
      input: input ?? this.input,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      primary: primary ?? this.primary,
      income: income ?? this.income,
      incomeBg: incomeBg ?? this.incomeBg,
      expense: expense ?? this.expense,
      expenseBg: expenseBg ?? this.expenseBg,
      transfer: transfer ?? this.transfer,
      transferBg: transferBg ?? this.transferBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      overdue: overdue ?? this.overdue,
      overdueBg: overdueBg ?? this.overdueBg,
    );
  }

  @override
  CoinNestColors lerp(ThemeExtension<CoinNestColors>? other, double t) {
    if (other is! CoinNestColors) return this;

    return CoinNestColors(
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      input: Color.lerp(input, other.input, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeBg: Color.lerp(incomeBg, other.incomeBg, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseBg: Color.lerp(expenseBg, other.expenseBg, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      transferBg: Color.lerp(transferBg, other.transferBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      overdueBg: Color.lerp(overdueBg, other.overdueBg, t)!,
    );
  }
}
