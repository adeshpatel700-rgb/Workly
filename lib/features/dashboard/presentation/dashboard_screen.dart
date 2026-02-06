import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workly/core/constants/app_colors.dart';
import 'package:workly/features/auth/data/auth_service.dart';
import '../../workplace/data/workplace_service.dart';
import '../../workplace/data/models.dart';
import '../../tasks/presentation/add_task_screen.dart';
import '../../tasks/presentation/task_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _workplaceId;
  String? _userRole;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workplaceId = prefs.getString('workplaceId');
    });
    
    // Fallback if prefs empty (e.g. existing admin login)
    if (_workplaceId == null) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final role = await auth.getUserRole(); // Helper needed?
      // For now assume if not in prefs, we might need to fetch from Firestore user doc
      // Simplification: User must have triggered write to prefs joined/created
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    final role = await auth.getUserRole();
    setState(() => _userRole = role);
  }

  void _copyId() {
    if (_workplaceId != null) {
      Clipboard.setData(ClipboardData(text: _workplaceId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workplace ID copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_workplaceId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      TaskList(workplaceId: _workplaceId!, filter: TaskFilter.all),
      TaskList(workplaceId: _workplaceId!, filter: TaskFilter.pending),
      TaskList(workplaceId: _workplaceId!, filter: TaskFilter.completed),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Workly Team'),
            GestureDetector(
              onTap: _copyId,
              child: Text(
                'ID: $_workplaceId 📋',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
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
            icon: Icon(Icons.list_alt),
            label: 'All Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.timelapse),
            label: 'Pending',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            label: 'Completed',
          ),
        ],
      ),
      floatingActionButton: _userRole == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTaskScreen(workplaceId: _workplaceId!),
                  ),
                );
              },
              label: const Text('New Task'),
              icon: const Icon(Icons.add),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }
}
