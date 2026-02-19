import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workly/core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({super.key, required this.onAnimationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start navigation after animation + buffer
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onAnimationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_rounded, // Better icon for work
                size: 64,
                color: AppColors.primary,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .then(delay: 200.ms)
            .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.5)),
            
            const SizedBox(height: 24),
            
            const Text(
              'Workly',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
            
            const SizedBox(height: 8),
             Text(
              'Team Tasks, Simplified.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
