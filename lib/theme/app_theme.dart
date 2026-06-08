import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.warmAmber,
          secondary: AppColors.softPurple,
          surface: AppColors.bgWhite,
          error: AppColors.dustyRose,
        ),
        scaffoldBackgroundColor: AppColors.bgGray,
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        dividerColor: AppColors.divider,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      );
}
