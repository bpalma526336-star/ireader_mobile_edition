import 'package:ireader_mobile_edition/core/safe_file_name.dart';
import 'package:ireader_mobile_edition/core/firestore_cache.dart';
import 'package:ireader_mobile_edition/core/memo.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/schoolyear.dart';
import 'package:ireader_mobile_edition/model/section.dart';
import 'package:ireader_mobile_edition/model/student.dart';
import 'package:ireader_mobile_edition/model/teacher.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/widgets/teacher_sidebar.dart';
import 'package:ireader_mobile_edition/widgets/teacher_top_header.dart';
import 'package:ireader_mobile_edition/views/teacher/assessments/viewassessment.dart';
import 'package:ireader_mobile_edition/views/teacher/practice_set/select_practice_set.dart';
import 'package:ireader_mobile_edition/views/teacher/students/manage_student.dart';
import 'package:ireader_mobile_edition/widgets/fun_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class TeacherManageSection extends StatefulWidget {
  final Teacher teacher;
  final SchoolYear schoolyear;

  const TeacherManageSection({
    super.key,
    required this.teacher,
    required this.schoolyear,
  });

  @override
  State<TeacherManageSection> createState() => _TeacherManageSectionState();
}

class _TeacherManageSectionState extends State<TeacherManageSection>
    with MemoMixin<TeacherManageSection> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> studentreads = ['Overall Result', 'Comprehension Result'];
  String _selectedReadType = 'Overall Result';

  String generateReadingInsight(Map<String, int> counts) {
    final frustration = counts['Frustration'] ?? 0;
    final instructional = counts['Instructional'] ?? 0;
    final independent = counts['Independent'] ?? 0;
    final total = frustration + instructional + independent;

    if (total == 0) return 'No reading data available for this section yet.';

    final totalScore =
        (frustration * 1) + (instructional * 2) + (independent * 3);
    final averageScore = totalScore / total;
    final percentage = (averageScore / 3) * 100;
    final percentFormatted = percentage.toStringAsFixed(1);

    if (independent >= instructional && independent >= frustration) {
      return 'Most students read at the Independent level ($percentFormatted% avg). '
          'Learners comprehend passages independently with minimal guidance.';
    } else if (instructional >= independent && instructional >= frustration) {
      return 'Most students are at the Instructional level ($percentFormatted% avg). '
          'Learners operate within a guided reading range.';
    } else {
      return 'Most students fall at the Frustration level ($percentFormatted% avg). '
          'This reflects a concentration of learners currently experiencing reading difficulties.';
    }
  }

  Future<void> exportSectionStudents(Section section) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    const String lastCol = 'D';
    const String lastcolgender = 'C';
    const String lastcolgstscore = 'D';

    sheet.getRangeByName('A1:${lastCol}1').merge();
    sheet.getRangeByName('A1').setText('STAGE 2 ADMISSION IN PHIL-IRI');
    sheet.getRangeByName('A1').cellStyle
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..bold = true;

    sheet.getRangeByName('A2:${lastCol}2').merge();
    sheet
        .getRangeByName('A2')
        .setText(
          'School Year: ${widget.schoolyear.schoolyearstart} - ${widget.schoolyear.schoolyearend}',
        );
    sheet.getRangeByName('A2').cellStyle
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center;

    final teacherSnap = await FirestoreCache.doc('teachers', section.teacherid);
    final teacherName = teacherSnap.exists
        ? () {
            final middle = (teacherSnap['middlename'] as String?) ?? '';
            return middle.isEmpty
                ? '${teacherSnap['firstname']} ${teacherSnap['lastname']}'
                : '${teacherSnap['firstname']} $middle ${teacherSnap['lastname']}';
          }()
        : 'Unknown';

    sheet.getRangeByName('A3:${lastCol}3').merge();
    sheet.getRangeByName('A3').setText('Teacher: $teacherName');
    sheet.getRangeByName('A3').cellStyle
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center;

    sheet.getRangeByName('A4:${lastCol}4').merge();
    sheet
        .getRangeByName('A4')
        .setText(
          'Students who will undergo Phil-IRI Oral Reading in English (Stage 2)',
        );
    sheet.getRangeByName('A4').cellStyle
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center;

    sheet.getRangeByName('A5').setText('NAME');
    sheet.getRangeByName('B5:${lastcolgender}5').setText('GENDER');
    sheet.getRangeByName('C5:${lastcolgstscore}5').setText('SCORE');
    sheet.getRangeByName('D5').setText('START LEVEL OF GRADE PASSAGE');
    sheet.getRangeByName('A5:${lastCol}5').cellStyle.bold = true;

    int rowIndex = 6;
    final snapshot = await _firestore
        .collection('students')
        .where('sectionid', isEqualTo: section.id)
        .where('schoolyearid', isEqualTo: widget.schoolyear.id)
        .where('schoolid', isEqualTo: widget.teacher.schoolid)
        .where('divisionid', isEqualTo: widget.teacher.divisionid)
        .get();
    final students = snapshot.docs
        .map((doc) => Student.fromMap(doc.id, doc.data()))
        .toList();
    students.sort(
      (a, b) => a.lastname.toLowerCase().compareTo(b.lastname.toLowerCase()),
    );

    for (var student in students) {
      sheet
          .getRangeByName('A$rowIndex')
          .setText(
            '${student.lastname}, ${student.firstname} ${student.middlename != null && student.middlename!.isNotEmpty ? "${student.middlename!} " : ""}',
          );
      sheet.getRangeByName('B$rowIndex').setText(student.gender);
      sheet.getRangeByName('C$rowIndex').setText(student.gstscore.toString());
      sheet
          .getRangeByName('D$rowIndex')
          .setText(student.gradelevelread.toString());
      rowIndex++;
    }

    sheet.getRangeByName('A1:$lastCol$rowIndex').autoFitColumns();

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = (await getApplicationDocumentsDirectory()).path;
    final filePath =
        '$directory/Phil-IRI_Student_List(Stage_2)_${safeFileName(section.sectionname)}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    OpenFile.open(filePath);
  }

  // ─── RESULT TOGGLE ──────────────────────────────────────────
  Widget _buildResultToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: studentreads.map((type) {
          final isSelected = _selectedReadType == type;
          return GestureDetector(
            onTap: () {
              if (_selectedReadType != type) {
                setState(() => _selectedReadType = type);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Live student list for a section. Cached per section so switching the
  /// Overall/Comprehension toggle only recounts locally instead of
  /// re-subscribing to Firestore.
  Stream<QuerySnapshot<Map<String, dynamic>>> _sectionStudents(
    Section section,
  ) {
    return memo(
      ('students', section.id, section.schoolyearid),
      () => _firestore
          .collection('students')
          .where('schoolyearid', isEqualTo: section.schoolyearid)
          .where('schoolid', isEqualTo: widget.teacher.schoolid)
          .where('divisionid', isEqualTo: widget.teacher.divisionid)
          .where('sectionid', isEqualTo: section.id)
          .where('status', isEqualTo: 'ACTIVE')
          .snapshots(),
    );
  }

  Map<String, int> _countLevels(QuerySnapshot<Map<String, dynamic>>? snap) {
    var f = 0, i = 0, ind = 0;
    for (final doc in snap?.docs ?? const []) {
      final data = doc.data();
      final level = _selectedReadType == 'Overall Result'
          ? (data['readlevel'] ?? '')
          : (data['comprehensionresult'] ?? '');
      if (level == 'Frustration') {
        f++;
      } else if (level == 'Instructional') {
        i++;
      } else if (level == 'Independent') {
        ind++;
      }
    }
    return {
      'Frustration': f,
      'Instructional': i,
      'Independent': ind,
      'Total': snap?.docs.length ?? 0,
    };
  }

  static const _cardAccents = [
    AppTheme.primaryColor,
    AppTheme.mintColor,
    AppTheme.grapeColor,
    AppTheme.coralColor,
    AppTheme.secondaryColor,
  ];

  // ─── SECTION CARD ────────────────────────────────────────────
  Widget _buildSectionCard(Section section, int index) {
    final accent = _cardAccents[index % _cardAccents.length];
    return Container(
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, Color.lerp(accent, Colors.white, 0.3)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: AppTheme.radiusM,
                  ),
                  child: const Icon(
                    Icons.groups_2_rounded,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.sectionname,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirestoreCache.doc(
                          'schoolyears',
                          section.schoolyearid,
                        ),
                        builder: (context, sySnap) {
                          final sy = sySnap.data?.data();
                          if (sy == null) return const SizedBox(height: 16);
                          return Text(
                            'School Year ${sy['schoolyearstart']}-${sy['schoolyearend']}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Reading level stats ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _sectionStudents(section),
              builder: (context, snapshot) {
                final counts = _countLevels(snapshot.data);
                final f = counts['Frustration']!;
                final i = counts['Instructional']!;
                final ind = counts['Independent']!;
                final total = counts['Total']!;
                final displayCounts = {
                  'Frustration': f,
                  'Instructional': i,
                  'Independent': ind,
                };
                final insight = generateReadingInsight(displayCounts);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _DonutChart(counts: displayCounts, total: total),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            children: [
                              _legendRow(
                                AppTheme.levelIndependent,
                                'Independent',
                                ind,
                              ),
                              const SizedBox(height: 8),
                              _legendRow(
                                AppTheme.levelInstructional,
                                'Instructional',
                                i,
                              ),
                              const SizedBox(height: 8),
                              _legendRow(
                                AppTheme.levelFrustration,
                                'Frustration',
                                f,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.sunColor.withValues(alpha: 0.12),
                        borderRadius: AppTheme.radiusM,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            size: 18,
                            color: Color(0xFFB7791F),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              insight,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: [
                _viewStudentsButton(section),
                _viewAssessmentButton(section),
                _viewPracticeSetButton(section),
                _exportButton(section),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppTheme.radiusS,
      ),
      child: Row(
        children: [
          Icon(AppTheme.levelIcon(label), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color.lerp(color, Colors.black, 0.35),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTION BUTTONS ──────────────────────────────────────────
  Widget _viewStudentsButton(Section section) {
    return _actionBtn(
      icon: Icons.people_outline,
      label: 'Students',
      isPrimary: true,
      onTap: () async {
        final schoolYearDoc = await FirestoreCache.doc(
          'schoolyears',
          section.schoolyearid,
        );
        if (!schoolYearDoc.exists) return;
        final correctSchoolYear = SchoolYear.fromMap(
          schoolYearDoc.id,
          schoolYearDoc.data() as Map<String, dynamic>,
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherManageStudentScreen(
              section: section,
              schoolyear: correctSchoolYear,
              teacher: widget.teacher,
            ),
          ),
        );
      },
    );
  }

  Widget _viewAssessmentButton(Section section) {
    return _actionBtn(
      icon: Icons.assignment_outlined,
      label: 'Assessments',
      isPrimary: true,
      onTap: () async {
        final schoolYearDoc = await FirestoreCache.doc(
          'schoolyears',
          section.schoolyearid,
        );
        if (!schoolYearDoc.exists) return;
        final correctSchoolYear = SchoolYear.fromMap(
          schoolYearDoc.id,
          schoolYearDoc.data() as Map<String, dynamic>,
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewAssessment(
              schoolyear: correctSchoolYear,
              teacher: widget.teacher,
            ),
          ),
        );
      },
    );
  }

  Widget _viewPracticeSetButton(Section section) {
    return _actionBtn(
      icon: Icons.menu_book_outlined,
      label: 'Practice Set',
      isPrimary: false,
      onTap: () async {
        final schoolYearDoc = await FirestoreCache.doc(
          'schoolyears',
          section.schoolyearid,
        );
        if (!schoolYearDoc.exists) return;
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectPracticeSetScreen(
              section: section,
              schoolyear: widget.schoolyear,
            ),
          ),
        );
      },
    );
  }

  Widget _exportButton(Section section) {
    return _actionBtn(
      icon: Icons.file_download_outlined,
      label: 'Export',
      isPrimary: false,
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await exportSectionStudents(section);
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
        }
      },
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final color = switch (label) {
      'Students' => AppTheme.primaryColor,
      'Assessments' => AppTheme.grapeColor,
      'Practice Set' => AppTheme.mintColor,
      _ => AppTheme.sunColor,
    };
    final filled = isPrimary;
    return Material(
      color: filled ? color : color.withValues(alpha: 0.12),
      borderRadius: AppTheme.radiusM,
      child: InkWell(
        borderRadius: AppTheme.radiusM,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: filled
                    ? Colors.white
                    : Color.lerp(color, Colors.black, 0.3),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: filled
                        ? Colors.white
                        : Color.lerp(color, Colors.black, 0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _welcomeCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: AppTheme.radiusL,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${widget.teacher.firstname}! 👋',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here are your reading classes for '
                  'SY ${widget.schoolyear.schoolyearstart}-${widget.schoolyear.schoolyearend}.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 900;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop
          ? null
          : Drawer(
              child: TeacherSidebar(
                activeRoute: TeacherRoute.sections,
                teacher: widget.teacher,
                schoolyear: widget.schoolyear,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            TeacherSidebar(
              activeRoute: TeacherRoute.sections,
              teacher: widget.teacher,
              schoolyear: widget.schoolyear,
            ),
          Expanded(
            child: Column(
              children: [
                TeacherHeader(
                  teacher: widget.teacher,
                  schoolyear: widget.schoolyear,
                  compact: isMobile,
                  onMenuPressed: isDesktop
                      ? null
                      : () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: memo(
                      ('sections', widget.teacher.id),
                      () => _firestore
                          .collection('sections')
                          .where('teacherid', isEqualTo: widget.teacher.id)
                          .snapshots(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: BouncyLoader(label: 'Loading your classes…'),
                        );
                      }
                      if (snapshot.hasError) {
                        return const FunEmptyState(
                          icon: Icons.wifi_off_rounded,
                          color: AppTheme.coralColor,
                          title: 'Could not load your sections',
                          message:
                              'Check your internet connection and try again.',
                        );
                      }

                      final sections =
                          (snapshot.data?.docs ?? const [])
                              .map(
                                (doc) => Section.fromMap(
                                  doc.id,
                                  doc.data() as Map<String, dynamic>,
                                ),
                              )
                              .toList()
                            ..sort(
                              (a, b) => a.sectionname.compareTo(b.sectionname),
                            );

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final pad = width <= 520 ? 16.0 : 24.0;
                          final columns = width <= 640
                              ? 1
                              : width <= 1000
                              ? 2
                              : 3;
                          final cardWidth =
                              (width - pad * 2 - (columns - 1) * 16) / columns;

                          return ListView(
                            padding: EdgeInsets.fromLTRB(pad, pad, pad, 32),
                            children: [
                              _welcomeCard(isMobile)
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.05),
                              const SizedBox(height: 20),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: 12,
                                spacing: 12,
                                children: [
                                  Text(
                                    'My Sections (${sections.length})',
                                    style: AppTheme.pageTitleStyle.copyWith(
                                      fontSize: 20,
                                    ),
                                  ),
                                  _buildResultToggle(),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (sections.isEmpty)
                                const FunEmptyState(
                                  icon: Icons.class_rounded,
                                  title: 'No sections assigned yet',
                                  message:
                                      'Contact your administrator to be assigned to a section.',
                                )
                              else
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    for (final (i, section) in sections.indexed)
                                      SizedBox(
                                        width: cardWidth,
                                        child: _buildSectionCard(section, i)
                                            .animate()
                                            .fadeIn(
                                              delay: (60 * i).ms,
                                              duration: 300.ms,
                                            )
                                            .slideY(begin: 0.06),
                                      ),
                                  ],
                                ),
                            ],
                          );
                        },
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
}

// ─── DONUT CHART ─────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  final Map<String, int> counts;
  final int total;
  const _DonutChart({required this.counts, required this.total});

  @override
  Widget build(BuildContext context) {
    final rated =
        (counts['Frustration'] ?? 0) +
        (counts['Instructional'] ?? 0) +
        (counts['Independent'] ?? 0);
    return SizedBox(
      width: 108,
      height: 108,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => CustomPaint(
          painter: _DonutPainter(counts: counts, total: rated, progress: t),
          child: child,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Text(
                'students',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, int> counts;
  final int total;
  final double progress;
  _DonutPainter({
    required this.counts,
    required this.total,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 15.0;
    final radius = (size.shortestSide / 2) - strokeWidth / 2 - 1;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    if (total == 0) return;

    final segments = [
      (key: 'Independent', color: AppTheme.levelIndependent),
      (key: 'Instructional', color: AppTheme.levelInstructional),
      (key: 'Frustration', color: AppTheme.levelFrustration),
    ];

    double startAngle = -math.pi / 2;
    const gap = 0.06;

    for (final seg in segments) {
      final value = counts[seg.key] ?? 0;
      if (value == 0) continue;
      final full = (value / total) * 2 * math.pi;
      final sweep = math.max(0.0, full * progress - gap);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += full * progress;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress ||
      old.total != total ||
      !_sameCounts(old.counts, counts);

  static bool _sameCounts(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length && a.keys.every((k) => a[k] == b[k]);
}
