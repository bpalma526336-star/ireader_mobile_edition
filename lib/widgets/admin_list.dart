import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/theme.dart';

/// Below this width the admin list pages switch from a table to a stacked,
/// phone-friendly layout (the table columns overflow on phones).
const double kAdminListCompactWidth = 700;

bool isCompactAdminList(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kAdminListCompactWidth;

/// Search + filter tabs + action buttons. One row on wide screens; on phones
/// the search, filters and actions each get their own line.
class AdminListToolbar extends StatelessWidget {
  final Widget search;
  final List<Widget> filters;
  final List<Widget> actions;

  const AdminListToolbar({
    super.key,
    required this.search,
    required this.filters,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCompactAdminList(context)) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            ...filters,
            for (final action in actions) ...[
              const SizedBox(width: 12),
              action,
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: filters),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Column header row of the table. Hidden on phones, where rows are stacked.
class AdminListHeader extends StatelessWidget {
  /// Column labels with their flex; the last column is the fixed-width
  /// actions column.
  final List<(String, int)> columns;
  final double actionsWidth;

  const AdminListHeader({
    super.key,
    required this.columns,
    required this.actionsWidth,
  });

  static const _style = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppTheme.textSecondaryColor,
    letterSpacing: 0.8,
  );

  @override
  Widget build(BuildContext context) {
    if (isCompactAdminList(context)) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          for (final (label, flex) in columns)
            Expanded(
              flex: flex,
              child: Text(label, style: _style),
            ),
          SizedBox(
            width: actionsWidth,
            child: const Text('ACTIONS', style: _style),
          ),
        ],
      ),
    );
  }
}

/// One record in an admin list. Table row on wide screens; on phones the
/// detail and status move under the title so nothing gets squeezed.
class AdminListRow extends StatelessWidget {
  final Widget avatar;
  final String title;

  /// Extra line under the title in both layouts (e.g. a school's address).
  final String? subtitle;

  /// Second table column (email, access code, division...). Optional.
  final String? detail;
  final bool isActive;
  final List<Widget> actions;
  final int titleFlex;
  final int detailFlex;
  final int statusFlex;
  final double actionsWidth;

  const AdminListRow({
    super.key,
    required this.avatar,
    required this.title,
    this.subtitle,
    this.detail,
    required this.isActive,
    required this.actions,
    this.titleFlex = 3,
    this.detailFlex = 3,
    this.statusFlex = 2,
    required this.actionsWidth,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimaryColor,
      ),
      overflow: TextOverflow.ellipsis,
    );
    Widget secondaryText(String text, double size) => Text(
      text,
      style: TextStyle(fontSize: size, color: AppTheme.textSecondaryColor),
      overflow: TextOverflow.ellipsis,
    );
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    if (isCompactAdminList(context)) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleText,
                  if (hasSubtitle) secondaryText(subtitle!, 11.5),
                  if (detail != null && detail!.isNotEmpty)
                    secondaryText(detail!, 12),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatusChip(isActive: isActive),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ...actions,
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: titleFlex,
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleText,
                      if (hasSubtitle) secondaryText(subtitle!, 11.5),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (detail != null)
            Expanded(flex: detailFlex, child: secondaryText(detail!, 13)),
          Expanded(
            flex: statusFlex,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: StatusChip(isActive: isActive),
              ),
            ),
          ),
          SizedBox(
            width: actionsWidth,
            child: Row(children: actions),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final bool isActive;

  const StatusChip({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB91C1C),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Colored circle with the record's initial.
class InitialAvatar extends StatelessWidget {
  final String name;
  final String fallback;

  const InitialAvatar({super.key, required this.name, this.fallback = '?'});

  static const _colors = [
    Color(0xFF6366F1),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final color = trimmed.isEmpty
        ? _colors[0]
        : _colors[trimmed.codeUnitAt(0) % _colors.length];
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          trimmed.isEmpty ? fallback : trimmed[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
