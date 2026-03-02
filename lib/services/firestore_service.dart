import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── PATIENTS ───

  /// Get patient document by Firebase Auth UID
  static Future<Map<String, dynamic>?> getPatientByUid(String uid) async {
    final doc = await _db.collection('patients').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Get patient document by PatientID (e.g., "HB-8429-XT")
  static Future<Map<String, dynamic>?> getPatientByPatientId(
      String patientId) async {
    final query = await _db
        .collection('patients')
        .where('patientId', isEqualTo: patientId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  /// Update patient profile fields
  static Future<void> updatePatientProfile(
      String uid, Map<String, dynamic> data) async {
    await _db.collection('patients').doc(uid).update(data);
  }

  // ─── REPORTS ───

  /// Save report metadata after file upload
  static Future<void> saveReport({
    required String patientId,
    required String fileUrl,
    required String fileName,
    required String type,
  }) async {
    await _db.collection('reports').add({
      'patientId': patientId,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'date': FieldValue.serverTimestamp(),
      'type': type,
    });
  }

  /// Get all reports for a patient, ordered by date (newest first)
  static Future<List<Map<String, dynamic>>> getReports(
      String patientId) async {
    final query = await _db
        .collection('reports')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .get();
    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ─── NOTES ───

  /// Add a doctor's note for a patient
  static Future<void> addNote({
    required String patientId,
    required String doctorId,
    required String note,
  }) async {
    await _db.collection('notes').add({
      'patientId': patientId,
      'doctorId': doctorId,
      'note': note,
      'date': FieldValue.serverTimestamp(),
    });
  }

  /// Get all notes for a patient, ordered by date (newest first)
  static Future<List<Map<String, dynamic>>> getNotes(String patientId) async {
    final query = await _db
        .collection('notes')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .get();
    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ─── TIMELINE ───

  /// Add a timeline event (e.g., "Report Uploaded", "AI Advice", "Doctor Note")
  static Future<void> addTimelineEvent({
    required String patientId,
    required String event,
  }) async {
    await _db.collection('timeline').add({
      'patientId': patientId,
      'event': event,
      'date': FieldValue.serverTimestamp(),
    });
  }

  /// Get timeline events for a patient, ordered by date (newest first)
  static Future<List<Map<String, dynamic>>> getTimeline(
      String patientId) async {
    final query = await _db
        .collection('timeline')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .get();
    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
