import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/readingcoordinator.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/readingcoordinator/rcdashboard.dart';
import 'package:ireader_mobile_edition/views/readingcoordinator/schoolyears/manage_schoolyear.dart';
import 'package:ireader_mobile_edition/widgets/admin_sidebar.dart';

enum RCRoute { dashboard, schoolYears }

class RCSidebar extends StatelessWidget {
  final RCRoute activeRoute;
  final RC rc;

  const RCSidebar({super.key, required this.activeRoute, required this.rc});

  @override
  Widget build(BuildContext context) {
    return RoleSidebar(
      roleLabel: 'Reading Coordinator',
      roleIcon: Icons.auto_stories_rounded,
      items: [
        SidebarEntry(
          'Dashboard',
          Icons.space_dashboard_rounded,
          AppTheme.primaryColor,
          activeRoute == RCRoute.dashboard,
          () => RCDashboard(readingcoordinator: rc),
        ),
        SidebarEntry(
          'School Years',
          Icons.calendar_month_rounded,
          AppTheme.mintColor,
          activeRoute == RCRoute.schoolYears,
          () => RCManageSchoolyearScreen(readingcoordinator: rc),
        ),
      ],
    );
  }
}
