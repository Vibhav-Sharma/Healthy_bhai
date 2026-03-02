import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  /// Sends patient info + symptoms to Gemini 2.5 Flash and returns advice.
  ///
  /// [symptoms] - User-entered symptoms (e.g., "Fever and headache")
  /// [bloodGroup] - Patient's blood group (e.g., "O+")
  /// [diseases] - Known diseases (e.g., "Diabetes")
  /// [allergies] - Known allergies (e.g., "Penicillin")
  /// [medicines] - Current medicines (e.g., "Metformin")
  static Future<String> getEmergencyAdvice({
    required String symptoms,
    String bloodGroup = 'Not provided',
    String diseases = 'None',
    String allergies = 'None',
    String medicines = 'None',
  }) async {
    try {
      // Create the Gemini model with system instruction
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
        systemInstruction: Content.system(
          'You are an AI emergency medical triage assistant.\n\n'
          'RULES:\n'
          '1. Provide practical, actionable first-aid and emergency advice.\n'
          '2. You MAY suggest safe, common over-the-counter (OTC) medicines '
          '(e.g., paracetamol/acetaminophen, ORS, antacids, antihistamines like cetirizine) '
          'when appropriate for symptom relief.\n'
          '3. ALWAYS cross-check your suggestions against the patient\'s listed allergies, '
          'diseases, and current medicines to AVOID dangerous interactions or contraindications.\n'
          '4. For patients with serious conditions (stroke history, heart disease, epilepsy, etc.), '
          'be extra cautious — avoid blood thinners, NSAIDs, or anything risky for their condition.\n'
          '5. If the situation sounds life-threatening (chest pain, stroke symptoms, severe bleeding, '
          'breathing difficulty), tell them to CALL EMERGENCY SERVICES IMMEDIATELY.\n'
          '6. Always recommend visiting a doctor for proper diagnosis.\n'
          '7. Give short bullet-point advice.\n'
          '8. End with a disclaimer that this is AI-generated advice, not a substitute for a real doctor.',
        ),
      );

      // Build the prompt with patient info + symptoms
      final String prompt = '''
Patient Information:
Blood group: $bloodGroup
Diseases: $diseases
Allergies: $allergies
Medicines: $medicines

Symptoms:
$symptoms
''';

      // Send request to Gemini
      final response = await model.generateContent([Content.text(prompt)]);

      return response.text?.trim() ??
          'No advice generated. Please try again.';
    } catch (e) {
      return 'Error: Could not connect to AI service. Please check your internet connection and try again.\n\nDetails: $e';
    }
  }

  /// Generates a concise clinical summary of a patient for the doctor.
  ///
  /// Fetches all available data (profile, reports, notes, timeline) and
  /// asks Gemini to produce a structured, diagnosis-ready overview.
  static Future<String> getPatientSummary({
    required Map<String, dynamic> patient,
    required List<Map<String, dynamic>> reports,
    required List<Map<String, dynamic>> notes,
    required List<Map<String, dynamic>> timeline,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: GEMINI_API_KEY,
        systemInstruction: Content.system(
          'You are a clinical summarisation assistant for doctors.\n\n'
          'RULES:\n'
          '1. Summarise the patient\'s medical history in a concise, structured way.\n'
          '2. Highlight critical information first: allergies, active diseases, current medicines.\n'
          '3. Note any potential drug interactions or contraindications.\n'
          '4. Summarise doctor notes and timeline events chronologically.\n'
          '5. Use clear Markdown formatting with headings, bold text, and bullet points.\n'
          '6. Keep the summary brief but comprehensive — a doctor should be able to glance at it before a consultation.\n'
          '7. End with a quick "Key Points for Consultation" section.\n'
          '8. Do NOT provide treatment advice. Only summarise existing data.',
        ),
      );

      // Build the data dump
      final name = patient['name'] ?? 'Unknown';
      final age = patient['age']?.toString() ?? 'Unknown';
      final bloodGroup = patient['bloodGroup'] ?? 'Unknown';
      final allergies = (patient['allergies'] as List?)?.join(', ') ?? 'None';
      final diseases = (patient['diseases'] as List?)?.join(', ') ?? 'None';
      final currentMeds = (patient['currentMedicines'] as List?)?.join(', ') ?? 'None';
      final oldMeds = (patient['oldMedicines'] as List?)?.join(', ') ?? 'None';

      final reportsSummary = reports.isNotEmpty
          ? reports.map((r) => '- ${r['fileName'] ?? 'Report'} (${r['type'] ?? 'Unknown type'})').join('\n')
          : 'No reports uploaded.';

      final notesSummary = notes.isNotEmpty
          ? notes.map((n) => '- ${n['note'] ?? ''}').join('\n')
          : 'No doctor notes.';

      final timelineSummary = timeline.isNotEmpty
          ? timeline.map((t) => '- ${t['event'] ?? ''}').join('\n')
          : 'No timeline events.';

      final prompt = '''
Patient Profile:
Name: $name
Age: $age
Blood Group: $bloodGroup
Allergies: $allergies
Active Diseases: $diseases
Current Medicines: $currentMeds
Old Medicines: $oldMeds

Reports:
$reportsSummary

Doctor Notes:
$notesSummary

Timeline Events:
$timelineSummary

Please provide a concise clinical summary for the attending doctor.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No summary generated. Please try again.';
    } catch (e) {
      return 'Error: Could not generate summary. Please check your internet connection and try again.\n\nDetails: $e';
    }
  }

  /// Extracts medicines, dosages, and timings from a prescription image.
  /// Uses Gemini 2.5 Flash multimodal capabilities.
  /// Returns a structured Map or throws an Exception.
  static Future<Map<String, dynamic>> extractPrescription(Uint8List imageBytes) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: GEMINI_API_KEY,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system(
        'You are a highly accurate medical prescription reader.\n'
        'Extract the medicines, dosages, and timings from the provided prescription image.\n\n'
        'Return ONLY a valid JSON object strictly following this schema:\n'
        '{\n'
        '  "medicines": [\n'
        '    {\n'
        '      "name": "Paracetamol",\n'
        '      "dosage": "500mg",\n'
        '      "timings": ["Morning", "Night"]  // Options: Morning, Afternoon, Night\n'
        '    }\n'
        '  ]\n'
        '}\n'
        'If no medicines are found, return {"medicines": []}.',
      ),
    );

    final prompt = TextPart('Extract the medicines from this prescription.');
    final imagePart = DataPart('image/jpeg', imageBytes);

    try {
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No response from AI.');
      }

      // Parse the JSON strictly
      final data = jsonDecode(response.text!) as Map<String, dynamic>;
      
      // Ensure the key exists
      if (!data.containsKey('medicines')) {
        return {'medicines': []};
      }

      return data;
    } catch (e) {
      throw Exception('Failed to extract medicines: $e');
    }
  }
}
