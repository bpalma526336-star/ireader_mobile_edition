import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/widgets/admin_top_header.dart';

class RCTopHeader extends StatelessWidget {
  final String pageTitle;
  final String? pageSubtitle;
  final Widget? trailing;

  const RCTopHeader({
    super.key,
    required this.pageTitle,
    this.pageSubtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return RoleTopHeader(
      roleLabel: 'RC',
      pageTitle: pageTitle,
      pageSubtitle: pageSubtitle,
      trailing: trailing,
    );
  }
}
