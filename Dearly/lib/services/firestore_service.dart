import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/journal_entry.dart';

class FirestoreService {
  static String pendingName = 'Friend';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── STORAGE ──────────────────────────────────────────────────────────────

  Future<String> uploadProfilePicture(String userId, File file) async {
    final ref = _storage.ref().child('user_avatars').child('$userId.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadEntryImage(String entryId, File file) async {
    final ref = _storage.ref().child('entry_images').child('$entryId.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ── ENTRIES ────────────────────────────────────────────────────────────────

  Future<void> addEntry(JournalEntry entry) async {
    await _db.collection('tbl_entries').doc(entry.entryId).set(entry.toFirestore());
  }

  Future<void> updateEntry(JournalEntry entry) async {
    await _db.collection('tbl_entries').doc(entry.entryId).update(entry.toFirestore());
  }

  Future<void> deleteEntry(String entryId) async {
    await _db.collection('tbl_entries').doc(entryId).delete();
  }

  Stream<List<JournalEntry>> getUserEntries(String userId) {
    return _db
        .collection('tbl_entries')
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList());
  }

  Future<List<JournalEntry>> getEntries([String? userId]) async {
    final targetUid = userId ?? _uid;
    if (targetUid == null) return [];

    final snap = await _db
        .collection('tbl_entries')
        .where('user_id', isEqualTo: targetUid)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();
  }

// ── USER ───────────────────────────────────────────────────────────────────

  Stream<AppUser?> userStream(String userId) {
    return _db.collection('tbl_users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  Future<AppUser?> getUser(String userId) async {
    try {
      var doc = await _db.collection('tbl_users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }

      var query = await _db.collection('tbl_users')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return AppUser.fromFirestore(query.docs.first);
      }

      return null;
    } catch (e) {
      print("🚨 Firestore Error in getUser: $e");
      return null;
    }
  }

  Future<void> setUser(AppUser user) async {
    try {
      await _db.collection('tbl_users').doc(user.userId).set(
        user.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      print("🚨 Firestore Error in setUser: $e");
      rethrow;
    }
  }

  // ── AUTH ───────────────────────────────────────────────────────────────────

  Future<UserCredential> signIn(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
