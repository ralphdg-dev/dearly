import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String entryId;
  final String userId;
  final DateTime date;
  final String content;
  final String mood;
  final String location;
  final String title;
  final String? imageUrl;
  final List<String> tags;
  final int wordCount;

  JournalEntry({
    required this.entryId,
    required this.userId,
    required this.date,
    required this.content,
    required this.mood,
    this.location = '',
    this.title = '',
    this.imageUrl,
    this.tags = const [],
    this.wordCount = 0,
  });

  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    // Add a fallback empty map in case doc.data() is somehow null
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return JournalEntry(
      entryId: data['entry_id'] ?? doc.id,
      userId: data['user_id'] ?? '',
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      content: data['content'] ?? '',
      mood: data['mood'] ?? '',
      location: data['location'] ?? '',
      title: data['title'] ?? '',
      imageUrl: data['image_url'],
      // Safer list parsing: handles nulls and ensures everything is treated as a String
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      wordCount: data['word_count'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'entry_id': entryId,
      'user_id': userId,
      'date': Timestamp.fromDate(date),
      'content': content,
      'mood': mood,
      'location': location,
      'title': title,
      'image_url': imageUrl,
      'tags': tags,
      'word_count': wordCount,
    };
  }
}

class AppUser {
  final String userId;
  final String name;
  final String profilePicture;
  final DateTime memberSince;

  AppUser({
    required this.userId,
    required this.name,
    this.profilePicture = '',
    required this.memberSince,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AppUser(
      userId: data['user_id'] ?? doc.id,
      name: data['name'] ?? '',
      profilePicture: data['profile_picture'] ?? '',
      memberSince: data['member_since'] is Timestamp
          ? (data['member_since'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'profile_picture': profilePicture,
      'member_since': Timestamp.fromDate(memberSince),
    };
  }
}

const List<Map<String, String>> kMoods = [
  {'label': 'Happy',   'emoji': '😊'},
  {'label': 'Calm',    'emoji': '🧘'},
  {'label': 'Neutral', 'emoji': '😐'},
  {'label': 'Sad',     'emoji': '😢'},
  {'label': 'Anxious', 'emoji': '😰'},
  {'label': 'Radiant', 'emoji': '☀️'},
  {'label': 'Pensive', 'emoji': '💧'},
];