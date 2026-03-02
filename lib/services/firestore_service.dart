import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── PATIENTS ───

  /// Get all registered patients
  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final query = await _db.collection('patients').get();
    return query.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }

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
        .get();
    final docs = query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    docs.sort((a, b) {
      final aDate = a['date'] as Timestamp?;
      final bDate = b['date'] as Timestamp?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return docs;
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
        .get();
    final docs = query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    docs.sort((a, b) {
      final aDate = a['date'] as Timestamp?;
      final bDate = b['date'] as Timestamp?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return docs;
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
        .get();
    final docs = query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    docs.sort((a, b) {
      final aDate = a['date'] as Timestamp?;
      final bDate = b['date'] as Timestamp?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return docs;
  }

  // ─── DOCTOR ACTIVITY ───

  /// Add a doctor activity event
  static Future<void> addDoctorActivity({
    required String doctorId,
    required String action,
  }) async {
    await _db.collection('doctor_activity').add({
      'doctorId': doctorId,
      'action': action,
      'date': FieldValue.serverTimestamp(),
    });
  }

  /// Get timeline events for a doctor, ordered by date (newest first)
  static Future<List<Map<String, dynamic>>> getDoctorActivity(String doctorId) async {
    final query = await _db
        .collection('doctor_activity')
        .where('doctorId', isEqualTo: doctorId)
        .get();
    final docs = query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    docs.sort((a, b) {
      final aDate = a['date'] as Timestamp?;
      final bDate = b['date'] as Timestamp?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return docs;
  }

  // ─── DOCTORS LIST ───

  /// Get all registered doctors
  static Future<List<Map<String, dynamic>>> getAllDoctors() async {
    final query = await _db.collection('doctors').get();
    return query.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }

  // ─── APPOINTMENTS ───

  /// Book an appointment
  static Future<void> bookAppointment({
    required String patientId,
    required String doctorId,
    required String doctorName,
    required DateTime appointmentDate,
    required String symptoms,
  }) async {
    await _db.collection('appointments').add({
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'symptoms': symptoms,
      'status': 'upcoming',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addTimelineEvent(
      patientId: patientId,
      event: 'Booked appointment with Dr. $doctorName',
    );
  }

  /// Get appointments for a patient
  static Future<List<Map<String, dynamic>>> getPatientAppointments(String patientId) async {
    final query = await _db
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .get();
    final docs = query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    docs.sort((a, b) => (a['appointmentDate'] as Timestamp).compareTo(b['appointmentDate'] as Timestamp));
    return docs;
  }

  /// Get appointments for a doctor
  static Future<List<Map<String, dynamic>>> getDoctorAppointments(String doctorId) async {
    final query = await _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();
    final docs = query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    docs.sort((a, b) => (a['appointmentDate'] as Timestamp).compareTo(b['appointmentDate'] as Timestamp));
    return docs;
  }
}

