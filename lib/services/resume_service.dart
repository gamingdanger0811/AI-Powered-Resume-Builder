import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/resume.dart';

class ResumeService {
  ResumeService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _col {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to access resumes.');
    }
    return _db.collection('users').doc(user.uid).collection('resumes');
  }

  Stream<List<Resume>> watchResumes() {
    return _col
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => Resume.fromMap(document.id, document.data()))
              .toList(),
        );
  }

  Future<String> saveResume(Resume resume) async {
    final data = resume.toMap()..['updatedAt'] = FieldValue.serverTimestamp();
    if (resume.id.isEmpty) {
      final document = await _col.add(data);
      return document.id;
    }
    await _col.doc(resume.id).set(data);
    return resume.id;
  }

  Future<void> deleteResume(String id) => _col.doc(id).delete();

  Future<String> duplicateResume(Resume resume) {
    final copy = Resume.fromMap('', resume.toMap())
      ..title = '${resume.title} (copy)';
    return saveResume(copy);
  }
}
