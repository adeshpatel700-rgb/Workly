import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/data/auth_service.dart';
import 'features/workplace/data/workplace_service.dart';
import 'features/auth/presentation/landing_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'core/constants/app_routes.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized successfully");
  } catch (e) {
    debugPrint("❌ Firebase initialization error: $e");
    // Continue anyway - the app will show error state if Firebase is needed
  }

  runApp(const WorklyApp());
}


class WorklyApp extends StatelessWidget {
  const WorklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<WorkplaceService>(create: (_) => WorkplaceService()),
      ],
      child: MaterialApp(
        title: 'Workly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Define routes
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => SplashScreen(
            onAnimationComplete: () {
              Navigator.of(context).pushReplacementNamed(AppRoutes.authWrapper);
            },
          ),
          AppRoutes.authWrapper: (context) => const AuthWrapper(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder(
      stream: authService.userStream,
      builder: (context, snapshot) {
        // Show error if something went wrong
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        // Handle all connection states properly
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        // Active connection - check if user is logged in
        final user = snapshot.data;
        if (user == null) {
          return const LandingScreen();
        } else {
          return const DashboardScreen();
        }
      },
    );
  }
}
