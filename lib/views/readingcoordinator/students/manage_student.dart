import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/readingcoordinator.dart';
import 'package:ireader_mobile_edition/model/schoolyear.dart';
import 'package:ireader_mobile_edition/model/section.dart';
import 'package:ireader_mobile_edition/model/student.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/admin/student/add_student.dart';
import 'package:ireader_mobile_edition/views/readingcoordinator/students/student_profile.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class RCManageStudentScreen extends StatefulWidget {
  final SchoolYear schoolyear;
  final Section section;
  final RC readingcoordinator;

  const RCManageStudentScreen({
    super.key,
    required this.section,
    required this.schoolyear,
    required this.readingcoordinator,
  });

  @override
  State<RCManageStudentScreen> createState() => _RCManageStudentScreenState();
}

class _RCManageStudentScreenState extends State<RCManageStudentScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String? _teacherName;

  @override
  void initState() {
    super.initState();
    _fetchTeacherName();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeacherName() async {
    final teacherSnapshot = await firestore
        .collection('teachers')
        .doc(widget.section.teacherid)
        .get();
    if (teacherSnapshot.exists && mounted) {
      final d = teacherSnapshot.data()!;
      setState(() {
        final middle = (d['middlename'] as String?) ?? '';
        _teacherName = middle.isEmpty
            ? "${d['firstname']} ${d['lastname']}"
            : "${d['firstname']} $middle ${d['lastname']}";
      });
    }
  }

  Widget _readingLevelBadge(String level) {
    Color bg;
    Color fg;

    switch (level) {
      case 'Frustration':
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFF7C2D12);
        break;
      case 'Instructional':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF78350F);
        break;
      case 'Independent':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = AppTheme.textSecondaryColor;
    }

    final label = level.isEmpty ? 'N/A' : level;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  static const _avatarColors = [
    Color(0xFF6366F1),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  Widget _avatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final color = _avatarColors[name.codeUnitAt(0) % _avatarColors.length];
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    );
  }

  // ─── Table header ──────────────────────────────────────────────────────────

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 4,
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
            flex: 2,
            child: Text(
              'GRADE LEVEL',
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
              'READING LEVEL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            width: 80,
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
    );
  }

  // ─── Table row ─────────────────────────────────────────────────────────────

  Widget _buildRow(Student student) {
    final fullName =
        '${student.firstname}${student.middlename != null && student.middlename!.isNotEmpty ? " ${student.middlename}" : ""} ${student.lastname}';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // NAME
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _avatar(student.lastname),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'LRN: ${student.lrn}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // GRADE LEVEL
          Expanded(
            flex: 2,
            child: Text(
              student.gradelevelread.isEmpty ? '—' : student.gradelevelread,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),

          // READING LEVEL
          Expanded(flex: 3, child: _readingLevelBadge(student.readlevel)),

          // ACTIONS
          SizedBox(
            width: 80,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RCStudentProfileScreen(
                      student: student,
                      section: widget.section,
                      schoolyear: widget.schoolyear,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 15,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Toolbar ───────────────────────────────────────────────────────────────

  Widget _buildToolbar(int shown, int total) {
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
                  hintText: 'Search students by name or LRN...',
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
          Text(
            '$shown of $total students',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.section.sectionname,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            Text(
              'SY ${widget.schoolyear.schoolyearstart}–${widget.schoolyear.schoolyearend}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('sectionid', isEqualTo: widget.section.id)
            .where('schoolyearid', isEqualTo: widget.schoolyear.id)
            .where('schoolid', isEqualTo: widget.readingcoordinator.schoolid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading students'));
          }

          var students = (snapshot.data?.docs ?? [])
              .map(
                (doc) =>
                    Student.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList();

          students.sort(
            (a, b) =>
                a.lastname.toLowerCase().compareTo(b.lastname.toLowerCase()),
          );

          final total = students.length;

          final query = _searchController.text.trim().toLowerCase();
          if (query.isNotEmpty) {
            students = students.where((s) {
              final name = '${s.firstname} ${s.middlename ?? ''} ${s.lastname}'
                  .toLowerCase();
              return name.contains(query) ||
                  s.lrn.toLowerCase().contains(query);
            }).toList();
          }

          return Column(
            children: [
              _buildToolbar(students.length, total),
              if (students.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 52,
                          color: AppTheme.textSecondaryColor.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          total == 0
                              ? 'No students in this section yet.'
                              : 'No students match "$query".',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: students.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppTheme.borderColor,
                          ),
                          itemBuilder: (_, index) => _buildRow(students[index]),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
