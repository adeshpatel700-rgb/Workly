import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workly/core/constants/app_colors.dart';
import 'package:workly/features/auth/data/auth_service.dart';
import '../../workplace/data/workplace_service.dart';
import '../../workplace/data/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../workplace/presentation/create_workplace_screen.dart';
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
    String? wpId = prefs.getString('workplaceId');

    if (wpId == null) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;
      
      if (user != null) {
         // Fetch from Firestore
         try {
           final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
           if (userDoc.exists && userDoc.data() != null) {
             final data = userDoc.data()!;
             wpId = data['workplaceId'];
             
             // Check role while here
             final role = data['role'];
             if (mounted) setState(() => _userRole = role);

             if (wpId != null) {
               await prefs.setString('workplaceId', wpId);
               if (mounted) setState(() => _workplaceId = wpId); 
             } else if (role == 'admin') {
               // Admin has no workplace yet -> Go create one
               if (mounted) {
                 Navigator.pushReplacement(
                   context,
                   MaterialPageRoute(builder: (_) => const CreateWorkplaceScreen()),
                 );
                 return;
               }
             }
           }
         } catch (e) {
           debugPrint('Error fetching user data: $e');
         }
      }
    }

    if (mounted) {
      setState(() {
        _workplaceId = wpId;
      });
      // Update role if not set
      if (_userRole == null) {
        final auth = Provider.of<AuthService>(context, listen: false);
        final role = await auth.getUserRole();
        setState(() => _userRole = role);
      }
    }
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
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
           // Show loading only initially
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
           return Scaffold(
             appBar: AppBar(title: const Text('Welcome')),
             body: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text('Profile setting up...'),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: _loadData, // Retry manual sync if needed
                     child: const Text('Retry'),
                   )
                 ],
               ),
             ),
           );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final String? wpId = data?['workplaceId'];
        final String? role = data?['role'];
        
        // Decide what to show
        if (wpId == null || wpId.isEmpty) {
          // If Admin -> Go Create
          if (role == 'admin') {
            // We can't navigate easily in build, so we show a tailored UI or use Future.microtask
            // Better: Show the "Create Workplace" button right here.
            return Scaffold(
              appBar: AppBar(title: const Text('Welcome Admin')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.domain_add, size: 64, color: AppColors.primary),
                    const SizedBox(height: 24),
                    Text('No workplace found.', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Workplace'),
                      onPressed: () {
                         Navigator.push(
                           context, 
                           MaterialPageRoute(builder: (_) => const CreateWorkplaceScreen())
                         );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
          } else {
             // Normal user without workplace? Should have joined via Join Screen.
             // Offer to Join
             return Scaffold(
               appBar: AppBar(title: const Text('Join Team')),
               body: Center(
                 child: ElevatedButton(
                   child: const Text('Join a Workplace'),
                     onPressed: () {
                         // Navigate to join (if we had a direct route, but Join is usually pre-auth for this app? 
                         // No, user joins via ID. 
                         // We don't have a JoinScreen accessible from here easily without refactor.
                         // For now, sign out.)
                         Provider.of<AuthService>(context, listen: false).signOut();
                     },
                 ),
               ),
             );
          }
        }

        // We have a workplace ID! Render Dashboard.
        // Update local state for child widgets if needed, or pass directly.
        // The original architecture used setState, but passing params is cleaner.
        
        return _buildDashboardContent(context, wpId, role);
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, String workplaceId, String? role) {
    // ... (Original Scaffold code shifted here)
    final userRole = role; // Use explicit role from snapshot
    
    // Calculate screens on the fly
    final screens = [
      TaskList(workplaceId: workplaceId, filter: TaskFilter.all),
      TaskList(workplaceId: workplaceId, filter: TaskFilter.pending),
      TaskList(workplaceId: workplaceId, filter: TaskFilter.completed),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Workly Team'),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: workplaceId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workplace ID copied to clipboard')),
                );
              },
              child: Text(
                'ID: $workplaceId 📋',
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
      floatingActionButton: userRole == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTaskScreen(workplaceId: workplaceId),
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
