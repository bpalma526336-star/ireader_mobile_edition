import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/theme.dart';

class AdminTopHeader extends StatelessWidget {
  final String pageTitle;
  final String? pageSubtitle;
  final Widget? trailing;

  const AdminTopHeader({
    super.key,
    required this.pageTitle,
    this.pageSubtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return RoleTopHeader(
      roleLabel: 'Admin',
      pageTitle: pageTitle,
      pageSubtitle: pageSubtitle,
      trailing: trailing,
    );
  }
}

/// Page header shared by the admin and reading-coordinator screens.
/// Shows a menu button automatically when the surrounding Scaffold has a
/// drawer (phones/tablets), which the old header was missing.
class RoleTopHeader extends StatefulWidget {
  final String roleLabel;
  final String pageTitle;
  final String? pageSubtitle;
  final Widget? trailing;

  const RoleTopHeader({
    super.key,
    required this.roleLabel,
    required this.pageTitle,
    this.pageSubtitle,
    this.trailing,
  });

  @override
  State<RoleTopHeader> createState() => _RoleTopHeaderState();
}

class _RoleTopHeaderState extends State<RoleTopHeader> {
  // Created once, not on every rebuild.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _latestYear =
      FirebaseFirestore.instance
          .collection('schoolyears')
          .orderBy('schoolyearstart', descending: true)
          .limit(1)
          .snapshots();

  String _initials(String? displayName, String? email) {
    final name = displayName ?? email ?? '';
    final parts = name.trim().split(RegExp(r'[\s@.]+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'A';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final initials = _initials(user?.displayName, user?.email);
    final isMobile = MediaQuery.sizeOf(context).width <= 600;
    final hasDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;

    final yearPill = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _latestYear,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.docs.first.data();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.mintColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wb_sunny_rounded,
                size: 14,
                color: Color(0xFF0F8A6A),
              ),
              const SizedBox(width: 5),
              Text(
                'SY ${data['schoolyearstart'] ?? ''}-${data['schoolyearend'] ?? ''}',
                style: const TextStyle(
                  color: Color(0xFF0F8A6A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );

    final avatar = Tooltip(
      message: user?.email ?? '',
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          gradient: AppTheme.heroGradient,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        hasDrawer ? 8 : 24,
        MediaQuery.paddingOf(context).top + (isMobile ? 10 : 16),
        isMobile ? 16 : 24,
        isMobile ? 14 : 18,
      ),
      decoration: AppTheme.pageHeaderDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasDrawer)
            IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded, size: 26),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'iReader ${widget.roleLabel}'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.pageTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 21 : 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimaryColor,
                    height: 1.15,
                  ),
                ),
                if (widget.pageSubtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    widget.pageSubtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
                if (isMobile) ...[const SizedBox(height: 8), yearPill],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!isMobile) ...[yearPill, const SizedBox(width: 12)],
          if (widget.trailing != null) ...[
            widget.trailing!,
            const SizedBox(width: 12),
          ],
          avatar,
        ],
      ),
    );
  }
}
