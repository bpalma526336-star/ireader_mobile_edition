import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ireader_mobile_edition/auth/login.dart';
import 'package:ireader_mobile_edition/core/firestore_cache.dart';
import 'package:ireader_mobile_edition/core/firestore_collections.dart';
import 'package:ireader_mobile_edition/model/readingcoordinator.dart';
import 'package:ireader_mobile_edition/model/schoolyear.dart';
import 'package:ireader_mobile_edition/model/teacher.dart';
import 'package:ireader_mobile_edition/views/admin/admindashboard.dart';
import 'package:ireader_mobile_edition/views/readingcoordinator/rcdashboard.dart';
import 'package:ireader_mobile_edition/views/teacher/sections/teacher_manage_section.dart';

/// Thrown when a signed-in Google account may not use the app.
class AccessDenied implements Exception {
  final String message;
  const AccessDenied(this.message);
  @override
  String toString() => message;
}

/// Sign-in, role lookup and sign-out in one place so every path leaves the
/// Firebase session in a consistent state.
abstract final class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  /// Interactive Google sign-in. Returns null when the user cancels.
  static Future<User?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      final result = await _auth.signInWithPopup(provider);
      return result.user;
    }
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// Finds the role for [user] and returns the screen they should land on.
  /// Any failure signs the user out before rethrowing, so a rejected account
  /// never keeps a live Firebase session.
  static Future<Widget> homeFor(User user) async {
    try {
      final email = user.email?.trim();
      if (email == null || email.isEmpty || !user.emailVerified) {
        throw const AccessDenied('This Google account has no verified email.');
      }

      // The three role lookups are independent, so run them together.
      final lookups = await Future.wait([
        _findByEmail(FirestoreCollections.teachers, email),
        _findByEmail(FirestoreCollections.admins, email),
        _findByEmail(FirestoreCollections.readingCoordinators, email),
      ]);
      final teacherDoc = lookups[0];
      final adminDoc = lookups[1];
      final rcDoc = lookups[2];

      if (teacherDoc != null) {
        _requireActive(teacherDoc, 'Teacher account inactive.');
        final teacher = Teacher.fromMap(teacherDoc.id, teacherDoc.data());
        final schoolyear = await _latestSchoolYearFor(teacher.id);
        return TeacherManageSection(teacher: teacher, schoolyear: schoolyear);
      }
      if (adminDoc != null) {
        _requireActive(adminDoc, 'Account inactive.');
        return const AdminDashboard();
      }
      if (rcDoc != null) {
        _requireActive(rcDoc, 'Account inactive.');
        return RCDashboard(
          readingcoordinator: RC.fromMap(rcDoc.id, rcDoc.data()),
        );
      }
      throw const AccessDenied(
        'No account associated with this Google account.',
      );
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  /// Signs out of both Google and Firebase and clears cached lookups.
  static Future<void> signOut() async {
    FirestoreCache.clear();
    await Future.wait([
      if (!kIsWeb) GoogleSignIn().signOut().catchError((Object _) => null),
      _auth.signOut(),
    ]);
  }

  /// Signs out and returns to the login screen, clearing the back stack.
  static Future<void> logout(BuildContext context) async {
    await signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  static Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findByEmail(
    String collection,
    String email,
  ) async {
    final snap = await _db
        .collection(collection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first;
  }

  static void _requireActive(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String msg,
  ) {
    if (doc.data()?['status'] != 'ACTIVE') throw AccessDenied(msg);
  }

  /// A teacher can have sections in several school years; open the newest one
  /// instead of whichever section Firestore happens to return first.
  static Future<SchoolYear> _latestSchoolYearFor(String teacherId) async {
    final sections = await _db
        .collection(FirestoreCollections.sections)
        .where('teacherid', isEqualTo: teacherId)
        .get();
    final yearIds = {
      for (final s in sections.docs)
        if ((s.data()['schoolyearid'] ?? '').toString().isNotEmpty)
          s.data()['schoolyearid'].toString(),
    };
    if (yearIds.isEmpty) {
      throw const AccessDenied('No section assigned to this teacher.');
    }

    final years = await Future.wait(
      yearIds.map(
        (id) => FirestoreCache.doc(FirestoreCollections.schoolYears, id),
      ),
    );
    final existing = [
      for (final y in years)
        if (y.exists) SchoolYear.fromMap(y.id, y.data()!),
    ];
    if (existing.isEmpty) throw const AccessDenied('School year not found.');
    existing.sort((a, b) => b.schoolyearstart.compareTo(a.schoolyearstart));
    return existing.first;
  }
}
