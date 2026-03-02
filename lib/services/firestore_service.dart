import 'package:flutter/foundation.dart';
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
  /// Falls back to unordered query if composite index is missing.
  static Future<List<Map<String, dynamic>>> getReports(
      String patientId) async {
    try {
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
    } catch (e) {
      debugPrint('[FirestoreService] getReports ordered query failed (missing index?): $e');
      // Fallback: fetch without orderBy and sort client-side
      final query = await _db
          .collection('reports')
          .where('patientId', isEqualTo: patientId)
          .get();
      final list = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aDate = a['date'];
        final bDate = b['date'];
        if (aDate == null || bDate == null) return 0;
        return (bDate as dynamic).toDate().compareTo((aDate as dynamic).toDate());
      });
      return list;
    }
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
  /// Falls back to unordered query if composite index is missing.
  static Future<List<Map<String, dynamic>>> getNotes(String patientId) async {
    try {
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
    } catch (e) {
      debugPrint('[FirestoreService] getNotes ordered query failed (missing index?): $e');
      final query = await _db
          .collection('notes')
          .where('patientId', isEqualTo: patientId)
          .get();
      final list = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aDate = a['date'];
        final bDate = b['date'];
        if (aDate == null || bDate == null) return 0;
        return (bDate as dynamic).toDate().compareTo((aDate as dynamic).toDate());
      });
      return list;
    }
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
  /// Falls back to unordered query if composite index is missing.
  static Future<List<Map<String, dynamic>>> getTimeline(
      String patientId) async {
    try {
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
    } catch (e) {
      debugPrint('[FirestoreService] getTimeline ordered query failed (missing index?): $e');
      // Fallback: fetch without orderBy and sort client-side
      final query = await _db
          .collection('timeline')
          .where('patientId', isEqualTo: patientId)
          .get();
      final list = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aDate = a['date'];
        final bDate = b['date'];
        if (aDate == null || bDate == null) return 0;
        return (bDate as dynamic).toDate().compareTo((aDate as dynamic).toDate());
      });
      return list;
    }
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
    try {
      final query = await _db
          .collection('doctor_activity')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('date', descending: true)
          .get();
      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreService] getDoctorActivity ordered query failed (missing index?): $e');
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
        final aDate = a['date'];
        final bDate = b['date'];
        if (aDate == null || bDate == null) return 0;
        return (bDate as dynamic).toDate().compareTo((aDate as dynamic).toDate());
      });
      return docs;
    }
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

  // ─── REMINDERS / MEDICINES ───

  /// Saves extracted medicines to Firestore.
  /// 1. Appends the medicine list to the patient's `currentMedicines` array.
  /// 2. Saves individual reminders to a `reminders` subcollection.
  static Future<void> saveMedicinesFromPrescription({
    required String patientId,
    required List<Map<String, dynamic>> medicines,
  }) async {
    // 1. Get UID from Patient ID
    final query = await _db.collection('patients').where('patientId', isEqualTo: patientId).limit(1).get();
    if (query.docs.isEmpty) throw Exception('Patient not found');
    
    final patientDoc = query.docs.first;
    final uid = patientDoc.id;

    // 2. Extract just the names for the profile array
    final List<String> newMedicineNames = medicines.map((m) => m['name'].toString()).toList();

    // 3. Batch write both profile update and reminders collection
    final batch = _db.batch();

    // Update Profile Array
    batch.update(patientDoc.reference, {
      'currentMedicines': FieldValue.arrayUnion(newMedicineNames),
    });

    // Add reminders
    for (var med in medicines) {
      final reminderRef = patientDoc.reference.collection('reminders').doc();
      batch.set(reminderRef, {
        'name': med['name'],
        'dosage': med['dosage'],
        'timings': med['timings'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Add timeline event
    final timelineRef = _db.collection('timeline').doc();
    batch.set(timelineRef, {
      'patientId': patientId,
      'event': 'AI extracted ${medicines.length} medicines from prescription.',
      'date': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}

