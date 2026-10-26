import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/schoolyear.dart';
import 'package:ireader_mobile_edition/model/section.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/readingcoordinator/practice_set/sentences/manage_sentence_ps.dart';
import 'package:ireader_mobile_edition/views/readingcoordinator/practice_set/storyline/manage_storyline_ps.dart';
import 'package:ireader_mobile_edition/views/readingcoordinator/practice_set/word_recognition/manage_wr_ps.dart';

class SelectPracticeSetScreen extends StatefulWidget {
  final Section section;
  final SchoolYear schoolyear;
  const SelectPracticeSetScreen({
    super.key,
    required this.section,
    required this.schoolyear,
  });

  @override
  State<SelectPracticeSetScreen> createState() =>
      _SelectPracticeSetScreenState();
}

class _SelectPracticeSetScreenState extends State<SelectPracticeSetScreen> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Widget _practiceCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final (image, blurb, accent) = switch (title) {
      'Word Recognition' => (
        'assets/images/word_recognition.png',
        'Spot and read words fast!',
        AppTheme.primaryColor,
      ),
      'Phrase & Sentences' => (
        'assets/images/phrase.png',
        'Read short phrases and sentences.',
        AppTheme.mintColor,
      ),
      _ => (
        'assets/images/storyline.png',
        'Enjoy stories and answer questions.',
        AppTheme.grapeColor,
      ),
    };
    return Material(
      color: Colors.white,
      borderRadius: AppTheme.radiusL,
      child: InkWell(
        borderRadius: AppTheme.radiusL,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppTheme.radiusL,
            border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
            boxShadow: AppTheme.softShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppTheme.radiusM,
                ),
                child: Image.asset(
                  image,
                  errorBuilder: (_, _, _) =>
                      Icon(icon, size: 40, color: accent),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      blurb,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                const Text(
                  'Practice Time! ✨',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.section.sectionname} · SY ${widget.schoolyear.schoolyearstart}-${widget.schoolyear.schoolyearend}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.extension_rounded, color: Colors.white, size: 44),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice Sets')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _hero(),
          const SizedBox(height: 18),
          _practiceCard(
            title: 'Word Recognition',
            icon: Icons.spellcheck,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageWRPS(
                    section: widget.section,
                    schoolyear: widget.schoolyear,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          _practiceCard(
            title: 'Phrase & Sentences',
            icon: Icons.short_text,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SentencePS(
                    section: widget.section,
                    schoolyear: widget.schoolyear,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          _practiceCard(
            title: 'Storyline',
            icon: Icons.menu_book,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageSLPS(
                    section: widget.section,
                    schoolyear: widget.schoolyear,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
