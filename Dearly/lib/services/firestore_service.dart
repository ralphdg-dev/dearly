import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

class FirestoreService {
  static String pendingName = 'Friend';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

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

  // FIX FOR ERROR 1: Renamed from entriesStream() to getUserEntries(String userId)
  Stream<List<JournalEntry>> getUserEntries(String userId) {
    return _db
        .collection('tbl_entries')
        .where('user_id', isEqualTo: userId)
    // Note: Using 'where' and 'orderBy' together requires a Firestore Index.
    // If your entries don't load, check your debug console for a Firebase link to build the index!
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList());
  }

  // Kept your static fetch method, updated to accept userId optionally
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

  Future<AppUser?> getUser(String userId) async {
    try {
      // 1. Primary Check: Look for a document where ID == Auth UID
      var doc = await _db.collection('tbl_users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }

      // 2. Fallback Check: Look for a document where the 'user_id' field == Auth UID
      // (This catches users you manually typed into the Firebase Console)
      var query = await _db.collection('tbl_users')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return AppUser.fromFirestore(query.docs.first);
      }

      print("⚠️ No user document found in Firestore for UID: $userId");
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
      print("✅ User successfully saved to Firestore!");
    } catch (e) {
      print("🚨 Firestore Error in setUser: $e");
      rethrow; // <--- THIS IS THE MAGIC WORD! It sends the error to the UI.
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