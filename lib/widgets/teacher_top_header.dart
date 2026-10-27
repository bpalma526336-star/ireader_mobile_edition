import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/schoolyear.dart';
import 'package:ireader_mobile_edition/model/teacher.dart';
import 'package:ireader_mobile_edition/theme.dart';

class TeacherHeader extends StatelessWidget {
  final Teacher teacher;
  final SchoolYear schoolyear;
  final VoidCallback? onMenuPressed;
  final bool compact;

  const TeacherHeader({
    super.key,
    required this.teacher,
    required this.schoolyear,
    this.onMenuPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final teacherName = '${teacher.firstname} ${teacher.lastname}'.trim();
    final initial = teacher.firstname.isNotEmpty
        ? teacher.firstname[0].toUpperCase()
        : 'T';

    return Container(
      padding: EdgeInsets.fromLTRB(
        onMenuPressed != null ? 6 : 24,
        MediaQuery.paddingOf(context).top + 8,
        compact ? 14 : 24,
        8,
      ),
      decoration: AppTheme.pageHeaderDecoration,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            if (onMenuPressed != null)
              IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu_rounded, size: 26),
                tooltip: 'Menu',
              ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: AppTheme.radiusS,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'iReader',
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    'SY ${schoolyear.schoolyearstart}-${schoolyear.schoolyearend}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              Text(
                teacherName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Tooltip(
              message: teacherName,
              child: CircleAvatar(
                radius: 19,
                backgroundColor: AppTheme.sunColor,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
