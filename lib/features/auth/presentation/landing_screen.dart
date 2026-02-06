import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workly/core/constants/app_colors.dart';
import 'admin_login_screen.dart';
import 'join_workplace_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF8B85FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                const Icon(
                  Icons.work_outline_rounded,
                  size: 64,
                  color: Colors.white,
                ).animate().fade().scale(duration: 600.ms),
                const SizedBox(height: 24),
                Text(
                  'Workly',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.3, end: 0),
                Text(
                  'Manage your team tasks\neffortlessly.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                ).animate().fade(delay: 400.ms).slideY(begin: 0.3, end: 0),
                const Spacer(flex: 3),
                _AuthButton(
                  title: 'Join a Workplace',
                  icon: Icons.login_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JoinWorkplaceScreen()),
                  ),
                  isPrimary: true,
                )
                    .animate()
                    .fade(delay: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 16),
                _AuthButton(
                  title: 'Admin Sign In',
                  icon: Icons.admin_panel_settings_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  ),
                  isPrimary: false,
                )
                    .animate()
                    .fade(delay: 700.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _AuthButton({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? Colors.white : Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          width: double.infinity,
          child: Row(
            children: [
              Icon(
                icon,
                color: isPrimary ? AppColors.primary : Colors.white,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppColors.primary : Colors.white,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isPrimary ? AppColors.primary : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
