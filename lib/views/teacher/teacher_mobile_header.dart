import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/schoolyear.dart';
import 'package:ireader_mobile_edition/model/teacher.dart';
import 'package:ireader_mobile_edition/widgets/teacher_top_header.dart';

/// Phone header for teacher screens.
class TeacherMobileHeader extends StatelessWidget {
  final Teacher teacher;
  final SchoolYear schoolyear;
  final VoidCallback onMenuPressed;

  const TeacherMobileHeader({
    super.key,
    required this.teacher,
    required this.schoolyear,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TeacherHeader(
      teacher: teacher,
      schoolyear: schoolyear,
      onMenuPressed: onMenuPressed,
      compact: true,
    );
  }
}
