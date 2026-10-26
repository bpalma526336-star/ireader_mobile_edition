import 'package:ireader_mobile_edition/core/firestore_cache.dart';
import 'package:ireader_mobile_edition/core/memo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/parent.dart';
import 'package:ireader_mobile_edition/model/schoolyear.dart';
import 'package:ireader_mobile_edition/model/section.dart';
import 'package:ireader_mobile_edition/model/student.dart';
import 'package:ireader_mobile_edition/model/teacher.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/teacher/parent/add_student_parent.dart';

class ViewParentStudent extends StatefulWidget {
  final Parent? parent;
  final Teacher? teacher;
  const ViewParentStudent({super.key, this.parent, this.teacher});

  @override
  State<ViewParentStudent> createState() => _ViewParentStudentState();
}

class _ViewParentStudentState extends State<ViewParentStudent>
    with MemoMixin<ViewParentStudent> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<List<Student>> getStudentsStream(List<String> studentIds) {
    if (studentIds.isEmpty) {
      return Stream.value([]);
    }

    return firestore
        .collection('students')
        .where(FieldPath.documentId, whereIn: studentIds)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Student.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Stream<List<Student>> getStudentsUnderParent() {

  // }

  Future<List<Student>> getStudentsUnderParent() async {
    if (widget.parent == null) {
      return [];
    }

    final studentIds = widget.parent!.studentids ?? [];

    if (studentIds.isEmpty) {
      return [];
    }

    final snapshot = await firestore
        .collection('students')
        .where(FieldPath.documentId, whereIn: studentIds)
        .get();

    return snapshot.docs.map((doc) {
      return Student.fromMap(doc.id, doc.data());
    }).toList();
  }

  Future<SchoolYear?> getSchoolYear(String schoolYearId) async {
    if (schoolYearId.isEmpty) {
      return null;
    }

    final doc = await FirestoreCache.doc('schoolyears', schoolYearId);

    if (!doc.exists) {
      return null;
    }

    return SchoolYear.fromMap(doc.id, doc.data()!);
  }

  Future<Section?> getSection(String sectionId) async {
    if (sectionId.isEmpty) {
      return null;
    }

    final doc = await FirestoreCache.doc('sections', sectionId);

    if (!doc.exists) {
      return null;
    }

    return Section.fromMap(doc.id, doc.data()!);
  }

  @override
  Widget build(BuildContext context) {
    final parentName = widget.parent == null
        ? 'Parent'
        : '${widget.parent!.firstname} ${widget.parent!.lastname}';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Students of $parentName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Student',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddParentStudent(
                    parent: widget.parent,
                    teacher: widget.teacher,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderColor),
        ),
      ),

      body: widget.parent == null
          ? _emptyState('Parent not found.')
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: memo(
                ('inline1', widget.parent!.id),
                () => firestore
                    .collection('parents')
                    .doc(widget.parent!.id)
                    .snapshots(),
              ),
              builder: (context, parentSnapshot) {
                if (parentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (parentSnapshot.hasError) {
                  return Center(child: Text('Error: ${parentSnapshot.error}'));
                }

                final parentDocument = parentSnapshot.data;
                if (parentDocument == null || !parentDocument.exists) {
                  return _emptyState('Parent not found.');
                }

                final liveParent = Parent.fromMap(
                  parentDocument.id,
                  parentDocument.data()!,
                );
                final liveParentName =
                    '${liveParent.firstname} ${liveParent.lastname}';

                return StreamBuilder<List<Student>>(
                  stream: memo((
                    'getStudentsStream',
                    liveParent.studentids ?? [],
                  ), () => getStudentsStream(liveParent.studentids ?? [])),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final students = snapshot.data ?? [];

                    if (students.isEmpty) {
                      return _emptyState(
                        'This parent has no students assigned.',
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(liveParentName, students.length),
                          const SizedBox(height: 16),
                          Text(
                            'Assigned Students',
                            style: AppTheme.sectionTitleStyle,
                          ),
                          const SizedBox(height: 10),
                          _buildStudentsCard(students),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildHeader(String parentName, int studentCount) {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              parentName == 'Parent' ? '?' : parentName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 16,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$studentCount ${studentCount == 1 ? 'student' : 'students'} assigned',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsCard(List<Student> students) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: students.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _buildStudentRow(students[index]),
      ),
    );
  }

  Widget _buildStudentRow(Student student) {
    final fullName = '${student.firstname} ${student.lastname}'.trim();
    final initial = student.firstname.isNotEmpty
        ? student.firstname[0].toUpperCase()
        : '?';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width <= 600 ? 14 : 20,
        vertical: 14,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    Text(
                      'LRN: ${student.lrn}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),

                    FutureBuilder<Section?>(
                      future: memo((
                        'getSection',
                        student.sectionid,
                      ), () => getSection(student.sectionid)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _StudentDetailChip(
                            icon: Icons.class_outlined,
                            label: 'Section loading',
                          );
                        }

                        if (snapshot.hasError || snapshot.data == null) {
                          return const _StudentDetailChip(
                            icon: Icons.class_outlined,
                            label: 'Section not found',
                          );
                        }

                        final section = snapshot.data!;

                        return _StudentDetailChip(
                          icon: Icons.class_outlined,
                          label: 'Section: ${section.sectionname}',
                        );
                      },
                    ),
                    FutureBuilder<SchoolYear?>(
                      future: memo((
                        'getSchoolYear',
                        student.schoolyearid,
                      ), () => getSchoolYear(student.schoolyearid)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _StudentDetailChip(
                            icon: Icons.calendar_today_outlined,
                            label: 'School year loading',
                          );
                        }

                        if (snapshot.hasError || snapshot.data == null) {
                          return const _StudentDetailChip(
                            icon: Icons.calendar_today_outlined,
                            label: 'School year not found',
                          );
                        }

                        final schoolYear = snapshot.data!;

                        return _StudentDetailChip(
                          icon: Icons.calendar_today_outlined,
                          label:
                              'School Year: ${schoolYear.schoolyearstart}-${schoolYear.schoolyearend}',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _StudentDetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StudentDetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final maxLabelWidth = MediaQuery.of(context).size.width - 110;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxLabelWidth < 120 ? 120 : maxLabelWidth,
          ),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
