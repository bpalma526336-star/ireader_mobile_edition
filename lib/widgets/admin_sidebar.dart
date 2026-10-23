import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ireader_mobile_edition/auth/login.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/admin/admin/manage_admin.dart';
import 'package:ireader_mobile_edition/views/admin/admindashboard.dart';
import 'package:ireader_mobile_edition/views/admin/division/manage_division.dart';
import 'package:ireader_mobile_edition/views/admin/parent/manage_parents.dart';
import 'package:ireader_mobile_edition/views/admin/readingcoordinator/manage_rc.dart';
import 'package:ireader_mobile_edition/views/admin/teacher/manage_teacher.dart';

enum AdminRoute {
  dashboard,
  schoolYears,
  divisions,
  schools,
  admins,
  readingCoordinators,
  teachers,
  parents,
}

class AdminSidebar extends StatelessWidget {
  final AdminRoute activeRoute;

  const AdminSidebar({super.key, required this.activeRoute});

  void _navigate(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (_) => false,
    );
  }

  Future<void> _logout(BuildContext context) async {
    // await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: AppTheme.backgroundColor),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Image.asset(
                  'assets/images/Department-of-Education-DepEd-Seal-300x300.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'iReader',
                style: TextStyle(
                  fontSize: 20,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _navItem(
          context,
          'Dashboard',
          Icons.dashboard,
          AdminRoute.dashboard,
          const AdminDashboard(),
        ),
        const SizedBox(height: 12),
        _navItem(
          context,
          'Divisions',
          Icons.business,
          AdminRoute.divisions,
          const ManageDivisionScreen(),
        ),
        const SizedBox(height: 12),
        _navItem(
          context,
          'Admins',
          Icons.admin_panel_settings,
          AdminRoute.admins,
          const ManageAdminScreen(),
        ),
        const SizedBox(height: 12),
        _navItem(
          context,
          'Reading Coords',
          Icons.groups,
          AdminRoute.readingCoordinators,
          const ManageRcScreen(),
        ),
        const SizedBox(height: 12),
        _navItem(
          context,
          'Teachers',
          Icons.school,
          AdminRoute.teachers,
          const ManageTeacherScreen(),
        ),
        const SizedBox(height: 12),
        _navItem(
          context,
          'Parents',
          Icons.people,
          AdminRoute.parents,
          const ManageParents(),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text(
            'Log Out',
            style: TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Widget _navItem(
    BuildContext context,
    String label,
    IconData icon,
    AdminRoute route,
    Widget page,
  ) {
    final isActive = activeRoute == route;
    final color = isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(fontSize: 18, color: color)),
      selected: isActive,
      selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      onTap: isActive ? null : () => _navigate(context, page),
    );
  }
}
