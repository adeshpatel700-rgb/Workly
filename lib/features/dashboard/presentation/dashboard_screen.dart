import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workly/core/constants/app_colors.dart';
import 'package:workly/features/auth/data/auth_service.dart';
import 'dashboard_view_model.dart';
import '../../workplace/presentation/create_workplace_screen.dart';
import '../../tasks/presentation/add_task_screen.dart';
import '../../tasks/presentation/task_list.dart';
import '../../workplace/presentation/members_screen.dart';
import '../../auth/presentation/landing_screen.dart';
import '../../auth/presentation/join_workplace_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(
        Provider.of<AuthService>(context, listen: false),
      )..init(), // Create and init immediately
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DashboardViewModel>(context);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    // 1. Loading State
    if (vm.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading workplace...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    // 2. Error State
    if (vm.error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading dashboard', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(vm.error!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => vm.init(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. No Workplace State (Admin or User)
    if (vm.workplaceId == null) {
       if (vm.userRole == 'admin') {
         return Scaffold(
           appBar: AppBar(title: const Text('Welcome Admin')),
           body: Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const Icon(Icons.domain_add, size: 64, color: AppColors.primary),
                 const SizedBox(height: 24),
                 Text(
                   'No workplace found.',
                   style: Theme.of(context).textTheme.headlineSmall,
                 ),
                 const SizedBox(height: 32),
                 ElevatedButton.icon(
                   icon: const Icon(Icons.add),
                   label: const Text('Create New Workplace'),
                   onPressed: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (_) => const CreateWorkplaceScreen()),
                     );
                   },
                 ),
                 const SizedBox(height: 16),
                 TextButton(
                   onPressed: () => vm.signOut(),
                   child: const Text('Sign Out'),
                 ),
               ],
             ),
           ),
         );
       } else {
         // Should have joined via Join Screen, but if here...
         return Scaffold(
            appBar: AppBar(title: const Text('Join Team')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You need to join a workplace.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    child: const Text('Join a Workplace'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JoinWorkplaceScreen()),
                      );
                    },
                  ),
                   const SizedBox(height: 16),
                   TextButton(
                     onPressed: () => vm.signOut(),
                     child: const Text('Sign Out'),
                   ),
                ],
              ),
            ),
         );
       }
    }

    // 4. Main Dashboard (Has Workplace ID)
    final screens = [
      TaskList(workplaceId: vm.workplaceId!, filter: TaskFilter.all),
      TaskList(workplaceId: vm.workplaceId!, filter: TaskFilter.pending),
      TaskList(workplaceId: vm.workplaceId!, filter: TaskFilter.completed),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Workly Team', style: TextStyle(fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: vm.workplaceId!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workplace ID copied!')),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vm.workplaceId!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy, size: 12, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (vm.userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MembersScreen(workplaceId: vm.workplaceId!)),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirm == true) {
                vm.signOut();
              }
            },
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'All Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.pending_actions_outlined),
            label: 'Pending',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt),
            label: 'Completed',
          ),
        ],
      ),
      floatingActionButton: vm.userRole == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTaskScreen(workplaceId: vm.workplaceId!),
                  ),
                );
              },
              label: const Text('New Task'),
              icon: const Icon(Icons.add),
            ).animate().scale(delay: 500.ms)
          : null,
    );
  }
}
