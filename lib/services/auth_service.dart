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

  /// Login patient using PatientID (e.g., HB-8429-XT).
  /// Looks up the email from Firestore, then signs in.
  static Future<String> patientLoginWithId({
    required String patientId,
    required String password,
  }) async {
    // Look up email by patientId
    final query = await _db
        .collection('patients')
        .where('patientId', isEqualTo: patientId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw Exception('No patient found with ID: $patientId');
    }
    final email = query.docs.first.data()['email'] as String;

    // Sign in with the found email
    return patientLogin(email: email, password: password);
  }

  /// Check if input looks like a PatientID (HB-XXXX-XX)
  static bool isPatientId(String input) {
    return RegExp(r'^HB-\d{4}-[A-Z]{2}$').hasMatch(input.toUpperCase());
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
  /// Register a new doctor. Returns the auto-generated DoctorID.
  static Future<String> doctorSignup({
    required String email,
    required String password,
    required String name,
    required String phone,       // <-- Added Phone
    required String specialty,   // <-- Changed from specialization to match UI
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
      'specialty': specialty,    // <-- Saves the dropdown choice
      'phone': phone,            // <-- Saves the 10-digit number
      'hospital': 'Not Specified', // Defaulting since it isn't in the UI yet
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

  /// Login doctor using DoctorID (e.g., DR-5281-KM).
  static Future<String> doctorLoginWithId({
    required String doctorId,
    required String password,
  }) async {
    final query = await _db
        .collection('doctors')
        .where('doctorId', isEqualTo: doctorId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw Exception('No doctor found with ID: $doctorId');
    }
    final email = query.docs.first.data()['email'] as String;

    return doctorLogin(email: email, password: password);
  }

  /// Check if input looks like a DoctorID (DR-XXXX-XX)
  static bool isDoctorId(String input) {
    return RegExp(r'^DR-\d{4}-[A-Z]{2}$').hasMatch(input.toUpperCase());
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
