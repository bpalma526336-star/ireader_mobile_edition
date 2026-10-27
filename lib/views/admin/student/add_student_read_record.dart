import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/student.dart';
import 'package:ireader_mobile_edition/shared/reading_record_form.dart';

class AddStudentReadRecordScreen extends StatelessWidget {
  final Student student;

  const AddStudentReadRecordScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) =>
      ReadingRecordForm(student: student, asDialog: false);
}
