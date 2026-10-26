import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/schoolyear.dart';
import 'package:ireader_mobile_edition/model/teacher.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/teacher/parent/manage_parents.dart';
import 'package:ireader_mobile_edition/views/teacher/sections/teacher_manage_section.dart';
import 'package:ireader_mobile_edition/widgets/admin_sidebar.dart';

enum TeacherRoute { sections, parents }

class TeacherSidebar extends StatelessWidget {
  final TeacherRoute activeRoute;
  final Teacher teacher;
  final SchoolYear schoolyear;

  const TeacherSidebar({
    super.key,
    required this.activeRoute,
    required this.teacher,
    required this.schoolyear,
  });

  @override
  Widget build(BuildContext context) {
    return RoleSidebar(
      roleLabel: 'Teacher',
      roleIcon: Icons.school_rounded,
      name: 'Hi, ${teacher.firstname}!',
      items: [
        SidebarEntry(
          'My Sections',
          Icons.class_rounded,
          AppTheme.primaryColor,
          activeRoute == TeacherRoute.sections,
          () => TeacherManageSection(teacher: teacher, schoolyear: schoolyear),
        ),
        SidebarEntry(
          'Parents',
          Icons.family_restroom_rounded,
          AppTheme.coralColor,
          activeRoute == TeacherRoute.parents,
          () => ManageParents(teacher: teacher, schoolyear: schoolyear),
        ),
      ],
    );
  }
}
