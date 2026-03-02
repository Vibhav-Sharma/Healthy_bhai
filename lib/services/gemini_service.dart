import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';

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
        apiKey: GEMINI_API_KEY,
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
}
