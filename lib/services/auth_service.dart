import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get current Firebase user
  static User? get currentUser => _auth.currentUser;

  // ─── PATIENT ───

  /// Generate a PatientID like "HB-8429-XT"
  static String _generatePatientId() {
    final rand = Random();
    final nums = (1000 + rand.nextInt(9000)).toString(); // 4 digits
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final c1 = chars[rand.nextInt(chars.length)];
    final c2 = chars[rand.nextInt(chars.length)];
    return 'HB-$nums-$c1$c2';
  }

  /// Register a new patient.
  /// Returns the auto-generated PatientID on success.
  static Future<String> patientSignup({
    required String email,
    required String password,
    required String name,
    required String age,
    required String bloodGroup,
    required String emergencyContact,
  }) async {
    // 1. Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    // 2. Generate unique PatientID
    final patientId = _generatePatientId();

    // 3. Create Firestore patient document
    await _db.collection('patients').doc(uid).set({
      'patientId': patientId,
      'name': name,
      'age': age,
      'bloodGroup': bloodGroup,
      'phone': '',
      'emergencyContact': emergencyContact,
      'allergies': [],
      'diseases': [],
      'currentMedicines': [],
      'oldMedicines': [],
      'surgeries': [],
      'treatments': [],
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return patientId;
  }

  /// Login patient. Returns patientId on success.
  static Future<String> patientLogin({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    // Fetch patientId from Firestore
    final doc = await _db.collection('patients').doc(uid).get();
    if (!doc.exists) {
      throw Exception('Patient profile not found. Please register first.');
    }
    return doc.data()!['patientId'] as String;
  }

  // ─── DOCTOR ───

  /// Generate a DoctorID like "DR-5281-KM"
  static String _generateDoctorId() {
    final rand = Random();
    final nums = (1000 + rand.nextInt(9000)).toString();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final c1 = chars[rand.nextInt(chars.length)];
    final c2 = chars[rand.nextInt(chars.length)];
    return 'DR-$nums-$c1$c2';
  }

  /// Register a new doctor. Returns the auto-generated DoctorID.
  static Future<String> doctorSignup({
    required String email,
    required String password,
    required String name,
    required String specialization,
    required String hospital,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final doctorId = _generateDoctorId();

    await _db.collection('doctors').doc(uid).set({
      'doctorId': doctorId,
      'name': name,
      'specialization': specialization,
      'hospital': hospital,
      'phone': '',
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doctorId;
  }

  /// Login doctor. Returns doctorId on success.
  static Future<String> doctorLogin({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final doc = await _db.collection('doctors').doc(uid).get();
    if (!doc.exists) {
      throw Exception('Doctor profile not found. Please register first.');
    }
    return doc.data()!['doctorId'] as String;
  }

  /// Get doctor name from doctorId field
  static Future<String> getDoctorName(String doctorId) async {
    final query = await _db
        .collection('doctors')
        .where('doctorId', isEqualTo: doctorId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return 'Unknown Doctor';
    return query.docs.first.data()['name'] ?? 'Unknown Doctor';
  }

  // ─── COMMON ───

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
