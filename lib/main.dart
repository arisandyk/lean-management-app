import 'package:flutter/material.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';
import 'package:lean_health_apps/features/dashboard/presentation/dashboard_screen.dart';
import 'package:lean_health_apps/features/home/presentation/home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lean_health_apps/features/patient_log/models/patient_log.model.dart';
import 'package:lean_health_apps/features/debug/presentation/debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PatientLogAdapter());
  await Hive.openBox<PatientLog>('patientLogs');

  runApp(const LeanHealthApp());
}

class LeanHealthApp extends StatelessWidget {
  const LeanHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = AppColors.primaryBlue;
    const Color lightGrey = AppColors.lightGreyBackground;

    return MaterialApp(
      title: 'Lean Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: lightGrey,
        colorScheme: ColorScheme.light(
          primary: primaryBlue,
          secondary: AppColors.accentTeal,
          surface: AppColors.cardSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: AppColors.cardSurface,
          elevation: 0,
          titleTextStyle: AppStyles.headline2,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: AppColors.cardSurface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/input': (context) => const HomeScreen(),
        '/debug': (context) => const DebugScreen(),
      },
    );
  }
}
