import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/schoolyear.dart';
import 'package:ireader_mobile_edition/model/teacher.dart';
import 'package:ireader_mobile_edition/theme.dart';

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
    final teacherName = '${teacher.firstname} ${teacher.lastname}'.trim();
    final initial = teacher.firstname.isNotEmpty
        ? teacher.firstname[0].toUpperCase()
        : 'T';

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu),
            tooltip: 'Open navigation',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'iReader',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  'SY ${schoolyear.schoolyearstart}-${schoolyear.schoolyearend}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: teacherName,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
