import 'package:cloud_firestore/cloud_firestore.dart';

/// In-memory memo for single-document reads that many widgets repeat
/// (assessment titles, school years, teacher names, ...).
///
/// Lists rebuild often; without this every row re-fetched its lookup on each
/// rebuild. Entries expire so edits made elsewhere still show up.
abstract final class FirestoreCache {
  static const _ttl = Duration(minutes: 5);
  static final _docs = <String, _Entry>{};

  static Future<DocumentSnapshot<Map<String, dynamic>>> doc(
    String collection,
    String id,
  ) {
    final key = '$collection/$id';
    final hit = _docs[key];
    if (hit != null && DateTime.now().difference(hit.at) < _ttl) {
      return hit.future;
    }
    final future = FirebaseFirestore.instance
        .collection(collection)
        .doc(id)
        .get();
    _docs[key] = _Entry(future, DateTime.now());
    // Do not keep failures around; let the next caller retry.
    future.catchError((Object _) {
      _docs.remove(key);
      return future;
    });
    return future;
  }

  /// Convenience for reading one field, e.g. an assessment title.
  static Future<T?> field<T>(String collection, String id, String name) async {
    if (id.isEmpty) return null;
    final snap = await doc(collection, id);
    final value = snap.data()?[name];
    return value is T ? value : null;
  }

  static void invalidate(String collection, [String? id]) {
    if (id != null) {
      _docs.remove('$collection/$id');
    } else {
      _docs.removeWhere((key, _) => key.startsWith('$collection/'));
    }
  }

  static void clear() => _docs.clear();
}

class _Entry {
  final Future<DocumentSnapshot<Map<String, dynamic>>> future;
  final DateTime at;
  _Entry(this.future, this.at);
}
