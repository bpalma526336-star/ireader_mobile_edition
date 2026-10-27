import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/core/auth_service.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/admin/admin/manage_admin.dart';
import 'package:ireader_mobile_edition/views/admin/admindashboard.dart';
import 'package:ireader_mobile_edition/views/admin/division/manage_division.dart';
import 'package:ireader_mobile_edition/views/admin/parent/manage_parents.dart';
import 'package:ireader_mobile_edition/views/admin/readingcoordinator/manage_rc.dart';
import 'package:ireader_mobile_edition/views/admin/teacher/manage_teacher.dart';
import 'package:ireader_mobile_edition/widgets/fun_ui.dart';

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

  @override
  Widget build(BuildContext context) {
    return RoleSidebar(
      roleLabel: 'Admin',
      roleIcon: Icons.admin_panel_settings_rounded,
      items: [
        SidebarEntry(
          'Dashboard',
          Icons.space_dashboard_rounded,
          AppTheme.primaryColor,
          activeRoute == AdminRoute.dashboard,
          () => const AdminDashboard(),
        ),
        SidebarEntry(
          'Divisions',
          Icons.map_rounded,
          AppTheme.mintColor,
          activeRoute == AdminRoute.divisions,
          () => const ManageDivisionScreen(),
        ),
        SidebarEntry(
          'Admins',
          Icons.shield_rounded,
          AppTheme.grapeColor,
          activeRoute == AdminRoute.admins,
          () => const ManageAdminScreen(),
        ),
        SidebarEntry(
          'Reading Coords',
          Icons.groups_rounded,
          AppTheme.secondaryColor,
          activeRoute == AdminRoute.readingCoordinators,
          () => const ManageRcScreen(),
        ),
        SidebarEntry(
          'Teachers',
          Icons.school_rounded,
          AppTheme.sunColor,
          activeRoute == AdminRoute.teachers,
          () => const ManageTeacherScreen(),
        ),
        SidebarEntry(
          'Parents',
          Icons.family_restroom_rounded,
          AppTheme.coralColor,
          activeRoute == AdminRoute.parents,
          () => const ManageParents(),
        ),
      ],
    );
  }
}

class SidebarEntry {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final Widget Function() page;
  const SidebarEntry(this.label, this.icon, this.color, this.active, this.page);
}

/// Shared drawer/side panel used by every role.
class RoleSidebar extends StatelessWidget {
  final String roleLabel;
  final IconData roleIcon;
  final String? name;
  final List<SidebarEntry> items;

  const RoleSidebar({
    super.key,
    required this.roleLabel,
    required this.roleIcon,
    required this.items,
    this.name,
  });

  void _navigate(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 180),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fixed width so it also works when placed directly in a Row on tablets.
    return SizedBox(
      width: 290,
      child: Material(
        color: AppTheme.cardColor,
        child: Column(
          children: [
            DrawerHero(roleLabel: roleLabel, roleIcon: roleIcon, name: name),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in items)
                    DrawerNavItem(
                      label: item.label,
                      icon: item.icon,
                      color: item.color,
                      active: item.active,
                      onTap: () => _navigate(context, item.page()),
                    ),
                ],
              ),
            ),
            const Divider(indent: 20, endIndent: 20),
            SafeArea(
              top: false,
              child: DrawerNavItem(
                label: 'Log Out',
                icon: Icons.logout_rounded,
                color: AppTheme.coralColor,
                active: false,
                onTap: () async {
                  if (await confirmLogout(context) && context.mounted) {
                    await AuthService.logout(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
