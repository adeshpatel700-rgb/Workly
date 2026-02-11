import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workly/core/constants/app_colors.dart';
import 'package:workly/features/auth/data/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../workplace/presentation/create_workplace_screen.dart';
import '../../tasks/presentation/add_task_screen.dart';
import '../../tasks/presentation/task_list.dart';
import '../../workplace/presentation/members_screen.dart';
import '../../auth/presentation/landing_screen.dart';

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
          debugPrint('📥 Fetching user data for ${user.uid}...');
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          debugPrint('📄 User document exists: ${userDoc.exists}');

          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data()!;
            // Defensive casting: handle case where field might be List
            final wpIdRaw = data['workplaceId'];
            wpId = wpIdRaw is String
                ? wpIdRaw
                : (wpIdRaw is List && wpIdRaw.isNotEmpty ? wpIdRaw[0] : null);
            debugPrint('🏢 Workplace ID: $wpId');

            // Check role while here
            final roleRaw = data['role'];
            final role = roleRaw is String
                ? roleRaw
                : (roleRaw is List && roleRaw.isNotEmpty ? roleRaw[0] : null);
            debugPrint('👤 User role: $role');
            if (mounted) setState(() => _userRole = role);

            if (wpId != null) {
              await prefs.setString('workplaceId', wpId);
              if (mounted) setState(() => _workplaceId = wpId);
            } else if (role == 'admin') {
              debugPrint('✨ Admin has no workplace, redirecting to create...');
              // Admin has no workplace yet -> Go create one
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateWorkplaceScreen(),
                  ),
                );
                return;
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error fetching user data: $e');
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

  // Helper to create user document if it doesn't exist
  Future<void> _createUserDocument(String uid) async {
    try {
      debugPrint('\n🔧 === Creating user document ===');
      debugPrint('UID: $uid');

      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;

      if (user == null) {
        debugPrint('❌ User is null, cannot create document');
        return;
      }

      // Check if document already exists
      final existingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (existingDoc.exists) {
        debugPrint('ℹ️ Document already exists, skipping creation');
        return;
      }

      debugPrint('📝 Creating new document...');
      debugPrint('   Email: ${user.email}');
      debugPrint('   Is Anonymous: ${user.isAnonymous}');

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': user.email ?? '',
        'role': user.isAnonymous ? 'user' : 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use merge to avoid overwriting

      debugPrint('✅ User document created successfully!');
      debugPrint('=================================\n');
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating user document: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    debugPrint('\n\n========== DASHBOARD BUILD ==========');
    debugPrint('User: ${user?.uid}');
    debugPrint('User email: ${user?.email}');
    debugPrint('User is anonymous: ${user?.isAnonymous}');
    debugPrint('=====================================\n');

    if (user == null) {
      debugPrint('⚠️ User is NULL in dashboard - redirecting to auth...');
      // This shouldn't happen - AuthWrapper should prevent this
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LandingScreen()),
        );
      });

      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Redirecting...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        debugPrint('\n--- StreamBuilder Update ---');
        debugPrint('ConnectionState: ${snapshot.connectionState}');
        debugPrint('Has error: ${snapshot.hasError}');
        debugPrint('Has data: ${snapshot.hasData}');
        if (snapshot.hasData) {
          debugPrint('Data exists: ${snapshot.data?.exists}');
          if (snapshot.data?.exists == true) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            debugPrint('User data: $data');
          }
        }
        debugPrint('---------------------------\n');

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Error')),
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
                    'Error loading data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Provider.of<AuthService>(
                        context,
                        listen: false,
                      ).signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading only initially
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

        if (!snapshot.hasData || !snapshot.data!.exists) {
          debugPrint('⚠️ User document does not exist OR no data yet');
          debugPrint('ConnectionState: ${snapshot.connectionState}');

          // Only create document if we're sure it doesn't exist (not just waiting)
          if (snapshot.connectionState != ConnectionState.waiting) {
            debugPrint('🔧 Attempting to create user document...');
            // Create the user document asynchronously
            Future.microtask(() => _createUserDocument(user.uid));
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Setting Up'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    Provider.of<AuthService>(context, listen: false).signOut();
                  },
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text(
                    'Setting up your profile...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Creating your account data',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    user.uid.length > 10
                        ? 'User ID: ${user.uid.substring(0, 10)}...'
                        : 'User ID: ${user.uid}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          debugPrint('⚠️ User document exists but data is null!');
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text('Invalid user data'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<AuthService>(
                        context,
                        listen: false,
                      ).signOut();
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }

        // Defensive casting: handle case where field might be List
        final wpIdRaw = data['workplaceId'];
        final String? wpId = wpIdRaw is String
            ? wpIdRaw
            : (wpIdRaw is List && wpIdRaw.isNotEmpty ? wpIdRaw[0] : null);
        final roleRaw = data['role'];
        final String? role = roleRaw is String
            ? roleRaw
            : (roleRaw is List && roleRaw.isNotEmpty ? roleRaw[0] : null);

        debugPrint('📊 Final data check:');
        debugPrint('   Workplace ID: $wpId');
        debugPrint('   Role: $role');
        debugPrint('   Full data: $data');

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
                    const Icon(
                      Icons.domain_add,
                      size: 64,
                      color: AppColors.primary,
                    ),
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
                          MaterialPageRoute(
                            builder: (_) => const CreateWorkplaceScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Provider.of<AuthService>(
                        context,
                        listen: false,
                      ).signOut(),
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

  Widget _buildDashboardContent(
    BuildContext context,
    String workplaceId,
    String? role,
  ) {
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
            const Text(
              'Workly Team',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: workplaceId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Workplace ID copied!',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      workplaceId.length > 8
                          ? 'ID: ${workplaceId.substring(0, 8)}...'
                          : 'ID: $workplaceId',
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
            ),
          ],
        ),
        actions: [
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MembersScreen(workplaceId: workplaceId),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          height: 65,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(
                Icons.grid_view_rounded,
                color: AppColors.primary,
              ),
              label: 'All Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.pending_actions_outlined),
              selectedIcon: Icon(
                Icons.pending_actions,
                color: AppColors.primary,
              ),
              label: 'Pending',
            ),
            NavigationDestination(
              icon: Icon(Icons.task_alt),
              selectedIcon: Icon(Icons.task_alt, color: AppColors.primary),
              label: 'Completed',
            ),
          ],
        ),
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
              label: const Text(
                'New Task',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.add_rounded, size: 24),
              backgroundColor: AppColors.primary,
              elevation: 4,
              extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
            )
          : null,
    );
  }
}
