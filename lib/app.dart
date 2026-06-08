import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/providers/classification_provider.dart';
import 'core/providers/forum_provider.dart';
import 'core/providers/booking_provider.dart';
import 'core/providers/mood_provider.dart';
import 'core/providers/journal_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/utils/constant/app_colors.dart';
import 'features/auth/onboarding/providers/onboarding_provider.dart';
import 'core/utils/widgets/auth_gate.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ClassificationProvider()),
        ChangeNotifierProvider(create: (_) => ForumProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'UBMentalCare',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: AppColors.netralLight,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.netralLight,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textHeading),
            titleTextStyle: TextStyle(
              color: AppColors.textHeading,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
