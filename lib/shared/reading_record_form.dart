import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ireader_mobile_edition/core/reading_level.dart';
import 'package:ireader_mobile_edition/model/student.dart';
import 'package:ireader_mobile_edition/model/studentoverallresult.dart';
import 'package:ireader_mobile_edition/model/studentreadingresult.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/widgets/fun_ui.dart';

/// Records a student's oral-reading (word recognition) result for one
/// assessment. Used by both the admin and teacher flows, as a full screen on
/// phones and as a dialog on wide screens.
///
/// Writes exactly the same documents as before:
///  * `readingresult/{studentId}_{assessmentId}`
///  * `students/{studentId}` → `readingresult`, and `readlevel` when a
///    comprehension result already exists
///  * `overallresult` for the student/assessment pair
class ReadingRecordForm extends StatefulWidget {
  final Student student;
  final bool asDialog;

  const ReadingRecordForm({
    super.key,
    required this.student,
    required this.asDialog,
  });

  @override
  State<ReadingRecordForm> createState() => _ReadingRecordFormState();
}

class _AssessmentOption {
  final String id;
  final String title;
  final int totalWords;
  final String accessCode;
  const _AssessmentOption(
    this.id,
    this.title,
    this.totalWords,
    this.accessCode,
  );
}

class _ReadingRecordFormState extends State<ReadingRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _miscuesController = TextEditingController();
  final _db = FirebaseFirestore.instance;

  // Loaded once; the old code re-queried on every rebuild.
  late final Future<List<_AssessmentOption>> _assessments = _loadAssessments();
  _AssessmentOption? _selected;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _miscuesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _miscuesController.dispose();
    super.dispose();
  }

  Future<List<_AssessmentOption>> _loadAssessments() async {
    final snapshot = await _db
        .collection('assessment')
        .where('schoolyearid', isEqualTo: widget.student.schoolyearid)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final title =
          (data['assessmenttitle'] as String?) ??
          (data['assessmentTitle'] as String?) ??
          (data['title'] as String?) ??
          doc.id;
      return _AssessmentOption(
        doc.id,
        title,
        ReadingLevel.parseInt(data['totalwords']),
        (data['accesscode'] ?? '').toString(),
      );
    }).toList();
  }

  int get _miscues => int.tryParse(_miscuesController.text.trim()) ?? 0;
  int get _totalWords => _selected?.totalWords ?? 0;
  int get _accuracy =>
      ReadingLevel.accuracyPercent(totalWords: _totalWords, miscues: _miscues);
  String get _wordLevel => ReadingLevel.fromAccuracy(_accuracy);

  String? _validateMiscues(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'Please enter the number of miscues';
    final n = int.tryParse(text);
    if (n == null || n < 0) return 'Use a whole number (0 or more)';
    if (_totalWords > 0 && n > _totalWords) {
      return 'Miscues cannot be more than the $_totalWords total words';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final assessment = _selected!;
    if (assessment.totalWords <= 0) {
      _snack(
        'This assessment has no word count yet. Ask an admin to set it first.',
        error: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final studentId = widget.student.id;
    final pairId = '${studentId}_${assessment.id}';

    try {
      // Read everything we need up front, in parallel.
      final reads = await Future.wait([
        _db
            .collection('readingresult')
            .where('studentid', isEqualTo: studentId)
            .where('assessmentid', isEqualTo: assessment.id)
            .limit(1)
            .get(),
        _db
            .collection('comprehensionresult')
            .where('studentid', isEqualTo: studentId)
            .where('assessmentid', isEqualTo: assessment.id)
            .limit(1)
            .get(),
        _db
            .collection('overallresult')
            .where('studentid', isEqualTo: studentId)
            .where('assessmentid', isEqualTo: assessment.id)
            .limit(1)
            .get(),
      ]);
      final existingReading = reads[0];
      final comprehensionSnap = reads[1];
      final overallSnap = reads[2];

      if (existingReading.docs.isNotEmpty) {
        _snack(
          'This student is already done with reading assessment.',
          error: true,
        );
        return;
      }

      final wordLevel = _wordLevel;
      final hasComprehension = comprehensionSnap.docs.isNotEmpty;
      final finalProfile = hasComprehension
          ? ReadingLevel.overall(
              wordLevel,
              (comprehensionSnap.docs.first.data()['result'] ?? '').toString(),
            )
          : wordLevel;

      // All writes succeed or fail together.
      final batch = _db.batch();
      batch.set(
        _db.collection('readingresult').doc(pairId),
        StudentReadingresult(
          id: pairId,
          studentid: studentId,
          assessmentid: assessment.id,
          totalwordsread: assessment.totalWords.toString(),
          totalmiscues: _miscues.toString(),
          totalreadingresult: _accuracy,
          readinglevel: wordLevel,
        ).toMap(),
        SetOptions(merge: true),
      );

      batch.update(_db.collection('students').doc(studentId), {
        'readingresult': wordLevel,
        if (hasComprehension) 'readlevel': finalProfile,
      });

      if (overallSnap.docs.isNotEmpty) {
        batch.update(
          _db.collection('overallresult').doc(overallSnap.docs.first.id),
          {'wordreadresult': wordLevel, 'readlevel': finalProfile},
        );
      } else {
        final overall = studentoverallresult(
          id: pairId,
          studentid: studentId,
          assessmentid: assessment.id,
          wordreadresult: wordLevel,
          readcompresult: 'Not Started',
          readlevel: hasComprehension ? finalProfile : 'Not Started',
        ).toMap();
        batch.set(_db.collection('overallresult').doc(pairId), {
          ...overall,
          'id': pairId,
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (!mounted) return;
      _snack('Reading record saved! 🎉');
      Navigator.pop(context);
    } catch (_) {
      _snack('Could not save the record. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? const Color(0xFFE03131) : null,
      ),
    );
  }

  String get _studentName => [
    widget.student.firstname,
    widget.student.middlename ?? '',
    widget.student.lastname,
  ].where((s) => s.trim().isNotEmpty).join(' ');

  Widget _fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FutureBuilder<List<_AssessmentOption>>(
          future: _assessments,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return const Text(
                'Could not load assessments. Check your connection.',
              );
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return const Text(
                'No assessments available for this school year',
              );
            }
            return DropdownButtonFormField<String>(
              initialValue: _selected?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select Assessment',
                prefixIcon: Icon(Icons.assignment_rounded),
              ),
              items: [
                for (final a in items)
                  DropdownMenuItem(value: a.id, child: Text(a.title)),
              ],
              onChanged: (id) => setState(
                () => _selected = items.firstWhere((a) => a.id == id),
              ),
              validator: (v) =>
                  v == null ? 'Please select an assessment' : null,
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.text_fields_rounded,
                color: AppTheme.secondaryColor,
                label: 'Total words',
                value: _selected == null ? '—' : '$_totalWords',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                icon: Icons.key_rounded,
                color: AppTheme.grapeColor,
                label: 'Access code',
                value: _selected == null || _selected!.accessCode.isEmpty
                    ? '—'
                    : _selected!.accessCode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _miscuesController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Number of miscues (mistakes)',
            prefixIcon: Icon(Icons.edit_note_rounded),
          ),
          validator: _validateMiscues,
        ),
        if (_selected != null &&
            _totalWords > 0 &&
            _miscuesController.text.trim().isNotEmpty &&
            _validateMiscues(_miscuesController.text) == null) ...[
          const SizedBox(height: 14),
          _PreviewCard(accuracy: _accuracy, level: _wordLevel),
        ],
      ],
    );
  }

  Widget _saveButton() => ElevatedButton.icon(
    onPressed: _isLoading ? null : _save,
    icon: _isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.check_circle_rounded),
    label: const Text('Save Reading Record'),
  );

  @override
  Widget build(BuildContext context) {
    final form = Form(key: _formKey, child: _fields());

    if (widget.asDialog) {
      return AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save Reading Record'),
            const SizedBox(height: 6),
            Text(
              _studentName,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(child: form),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          _saveButton(),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reading Record')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: AppTheme.radiusL,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Oral reading for',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _studentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            form,
            const SizedBox(height: 24),
            SizedBox(height: 54, child: _saveButton()),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppTheme.radiusM,
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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

class _PreviewCard extends StatelessWidget {
  final int accuracy;
  final String level;
  const _PreviewCard({required this.accuracy, required this.level});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.levelColor(level);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppTheme.radiusM,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            '$accuracy%',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color.lerp(color, Colors.black, 0.3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Word reading result',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                LevelBadge(level: level),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
