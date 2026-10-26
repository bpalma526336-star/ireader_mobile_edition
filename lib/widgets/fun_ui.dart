import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ireader_mobile_edition/theme.dart';

/// Paper-coloured backdrop with a few soft, colourful shapes. Painted once
/// (no images) so it costs almost nothing to draw.
class StorybookBackground extends StatelessWidget {
  final Widget child;
  const StorybookBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: CustomPaint(painter: const _BlobPainter(), child: child),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset c, double r, Color color) =>
        canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.14));

    final w = size.width, h = size.height;
    blob(Offset(w * 0.05, h * 0.08), 120, AppTheme.sunColor);
    blob(Offset(w * 0.95, h * 0.18), 90, AppTheme.secondaryColor);
    blob(Offset(w * 0.9, h * 0.92), 140, AppTheme.mintColor);
    blob(Offset(w * 0.1, h * 0.85), 70, AppTheme.coralColor);
    blob(Offset(w * 0.55, h * 0.02), 40, AppTheme.grapeColor);

    // A few tiny stars sprinkled around.
    final star = Paint()..color = AppTheme.sunColor.withValues(alpha: 0.45);
    for (final p in [
      Offset(w * 0.2, h * 0.3),
      Offset(w * 0.82, h * 0.42),
      Offset(w * 0.32, h * 0.72),
      Offset(w * 0.7, h * 0.78),
    ]) {
      canvas.drawPath(_starPath(p, 7), star);
    }
  }

  Path _starPath(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Friendly loading indicator: a bouncing book with an optional caption.
class BouncyLoader extends StatelessWidget {
  final String? label;
  const BouncyLoader({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 32,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -10, duration: 500.ms, curve: Curves.easeOut),
        if (label != null) ...[
          const SizedBox(height: 16),
          Text(
            label!,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// Small rounded pill with an icon, used for highlights and labels.
class FunTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const FunTag({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Color.lerp(color, Colors.black, 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coloured badge for a reading level (Independent / Instructional /
/// Frustration) with a matching icon.
class LevelBadge extends StatelessWidget {
  final String level;
  final bool compact;
  const LevelBadge({super.key, required this.level, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.levelColor(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: AppTheme.statusBadgeDecoration(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppTheme.levelIcon(level),
            size: compact ? 13 : 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            level.isEmpty ? 'Not yet' : level,
            style: TextStyle(
              fontSize: compact ? 11.5 : 13,
              fontWeight: FontWeight.w800,
              color: Color.lerp(color, Colors.black, 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty / error state with a big friendly icon bubble.
class FunEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Color color;
  final Widget? action;

  const FunEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.color = AppTheme.primaryColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 46, color: color),
            ).animate().scale(
              begin: const Offset(0.7, 0.7),
              curve: Curves.easeOutBack,
              duration: 450.ms,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// Header block used at the top of the navigation drawers.
class DrawerHero extends StatelessWidget {
  final String roleLabel;
  final String? name;
  final IconData roleIcon;

  const DrawerHero({
    super.key,
    required this.roleLabel,
    required this.roleIcon,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: AppTheme.radiusL,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/Department-of-Education-DepEd-Seal-300x300.png',
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'iReader',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleIcon, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (name != null && name!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                name!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rounded navigation row for drawers.
class DrawerNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback? onTap;

  const DrawerNavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    this.color = AppTheme.primaryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: AppTheme.radiusM,
        child: InkWell(
          borderRadius: AppTheme.radiusM,
          onTap: active ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: active ? color : color.withValues(alpha: 0.12),
                    borderRadius: AppTheme.radiusS,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: active ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                      color: active ? color : AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks the user to confirm before signing out.
Future<bool> confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.waving_hand_rounded,
        color: AppTheme.sunColor,
        size: 40,
      ),
      title: const Text('Log out?'),
      content: const Text('You can sign back in any time with Google.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Stay'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralColor),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Shared confirmation for destructive actions.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.delete_forever_rounded,
        color: AppTheme.coralColor,
        size: 40,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralColor),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
