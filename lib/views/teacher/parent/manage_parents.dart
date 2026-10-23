import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/parent.dart';
import 'package:ireader_mobile_edition/model/schoolyear.dart';
import 'package:ireader_mobile_edition/model/teacher.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/teacher/parent/add_parent.dart';
import 'package:ireader_mobile_edition/views/teacher/parent/view_students.dart';
import 'package:ireader_mobile_edition/views/teacher/teacher_mobile_header.dart';
import 'package:ireader_mobile_edition/widgets/teacher_sidebar.dart';
import 'package:ireader_mobile_edition/widgets/teacher_top_header.dart';

class ManageParents extends StatefulWidget {
  final Teacher teacher;
  final SchoolYear schoolyear;

  const ManageParents({
    super.key,
    required this.teacher,
    required this.schoolyear,
  });

  @override
  State<ManageParents> createState() => _ManageParentsState();
}

class _ManageParentsState extends State<ManageParents> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  void _openAddParent() {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    if (isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddParent(parent: null)),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AddParent(parent: null),
      );
    }
  }

  Stream<QuerySnapshot> fetchParents() {
    return firestore.collection('parents').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isMobile = screenWidth <= 600;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      drawer: isDesktop
          ? null
          : Drawer(
              child: TeacherSidebar(
                activeRoute: TeacherRoute.parents,
                teacher: widget.teacher,
                schoolyear: widget.schoolyear,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            TeacherSidebar(
              activeRoute: TeacherRoute.parents,
              teacher: widget.teacher,
              schoolyear: widget.schoolyear,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile)
                  TeacherMobileHeader(
                    teacher: widget.teacher,
                    schoolyear: widget.schoolyear,
                    onMenuPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                  )
                else
                  TeacherHeader(
                    teacher: widget.teacher,
                    schoolyear: widget.schoolyear,
                    onMenuPressed: isDesktop
                        ? null
                        : () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 28,
                    isMobile ? 16 : 14,
                    isMobile ? 16 : 24,
                    isMobile ? 16 : 14,
                  ),
                  color: Colors.white,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Manage Parents',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Parent accounts and section assignments',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        fetchParents(), // Assuming you have a function to fetch parents
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading parents'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        );
                      }

                      var parents = snapshot.data!.docs
                          .map(
                            (doc) => Parent.fromMap(
                              doc.id,
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList();

                      if (_selectedFilter != 'All') {
                        parents = parents
                            .where((p) => p.status == _selectedFilter)
                            .toList();
                      }

                      final query = _searchController.text.trim().toLowerCase();
                      if (query.isNotEmpty) {
                        parents = parents.where((p) {
                          final name =
                              '${p.firstname} ${p.middlename ?? ''} ${p.lastname}'
                                  .toLowerCase();
                          return name.contains(query) ||
                              p.accesscode.toLowerCase().contains(query);
                        }).toList();
                      }

                      return Column(
                        children: [
                          _buildToolbar(isMobile: isMobile),
                          Expanded(
                            child: _buildTable(parents, isMobile: isMobile),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar({required bool isMobile}) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search parents by name or access code',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppTheme.textSecondaryColor,
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterTab('All'),
                  _filterTab('ACTIVE', label: 'Active'),
                  _filterTab('INACTIVE', label: 'Inactive'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _openAddParent,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Parent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search parents by name or access code',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppTheme.textSecondaryColor,
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _filterTab('All'),
          _filterTab('ACTIVE', label: 'Active'),
          _filterTab('INACTIVE', label: 'Inactive'),
          const SizedBox(width: 12),
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: _openAddParent,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Parent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String value, {String? label}) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            ),
          ),
          child: Center(
            child: Text(
              label ?? value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<Parent> parents, {required bool isMobile}) {
    if (parents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 52,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No parents found',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: parents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildRow(parents[index], isMobile: true),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'NAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Access Code',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'ACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: parents.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderColor),
              itemBuilder: (context, index) =>
                  _buildRow(parents[index], isMobile: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Parent parent, {required bool isMobile}) {
    final isActive = parent.status == 'ACTIVE';
    final fullName =
        '${parent.firstname} ${parent.middlename != null && parent.middlename!.isNotEmpty ? "${parent.middlename} " : ""}${parent.lastname}'
            .trim();
    final initial = parent.firstname.isNotEmpty
        ? parent.firstname[0].toUpperCase()
        : 'T';

    const avatarColors = [
      Color(0xFF6366F1),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
    ];
    final avatarColor =
        avatarColors[(fullName.isEmpty ? 0 : fullName.codeUnitAt(0)) %
            avatarColors.length];

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarColor,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fullName.isEmpty ? 'Unnamed parent' : fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(isActive),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: AppTheme.borderColor),
            ),
            const Text(
              'ACCESS CODE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryColor,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              parent.accesscode,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isActive ? 'Account active' : 'Account inactive',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                _buildParentActions(parent, isActive),
              ],
            ),
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
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              parent.accesscode,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(isActive),
            ),
          ),
          SizedBox(width: 140, child: _buildParentActions(parent, isActive)),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
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

  Widget _buildParentActions(Parent parent, bool isActive) {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View Students',
          icon: const Icon(
            Icons.people_outline,
            size: 18,
            color: AppTheme.textSecondaryColor,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ViewParentStudent(parent: parent, teacher: widget.teacher),
              ),
            );
          },
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          tooltip: 'Edit Parent',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: () {
            if (isMobile) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddParent(parent: parent, teacher: widget.teacher),
                ),
              );
            } else {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AddParent(parent: parent),
              );
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 15,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Switch(
          value: isActive,
          activeThumbColor: const Color(0xFF16A34A),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (val) async {
            final newStatus = val ? 'ACTIVE' : 'INACTIVE';
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(val ? 'Activate Parent' : 'Deactivate Parent'),
                content: Text(
                  val
                      ? 'Set this parent as active?'
                      : 'Set this parent as inactive?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            );
            if (confirmed ?? false) {
              await firestore.collection('parents').doc(parent.id).update({
                'status': newStatus,
              });
            }
          },
        ),
      ],
    );
  }
}
