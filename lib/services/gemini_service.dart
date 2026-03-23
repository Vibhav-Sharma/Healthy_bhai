import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class GeminiService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> _callGroqApi({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
  }) async {
    final Map<String, dynamic> body = {
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.2,
    };

    if (jsonMode) {
      body['response_format'] = {'type': 'json_object'};
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $ACTIVE_AI_API_KEY',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception('Groq API Error: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<String> _callGroqVisionApi({
    required String systemPrompt,
    required String userPrompt,
    required Uint8List imageBytes,
  }) async {
    final base64Image = base64Encode(imageBytes);
    final String dataUrl = 'data:image/jpeg;base64,$base64Image';

    final Map<String, dynamic> body = {
      'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
      'messages': [
        {
          'role': 'user',
          'content': [
            // Vision model sometimes performs better with system prompt embedded in user prompt
            {'type': 'text', 'text': systemPrompt + '\n\n' + userPrompt},
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl}
            }
          ]
        }
      ],
      'temperature': 0.2,
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $ACTIVE_AI_API_KEY',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception('Groq Vision API Error: ${response.statusCode} - ${response.body}');
    }
  }

  static String _cleanJsonResponse(String text) {
    text = text.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  /// Sends patient info + symptoms to Groq and returns advice.
  static Future<String> getEmergencyAdvice({
    required String symptoms,
    String bloodGroup = 'Not provided',
    String diseases = 'None',
    String allergies = 'None',
    String medicines = 'None',
  }) async {
    try {
      final systemInstruction =
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
          '8. End with a disclaimer that this is AI-generated advice, not a substitute for a real doctor.';

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

      final responseText = await _callGroqApi(
        systemPrompt: systemInstruction,
        userPrompt: prompt,
      );

      return responseText.trim().isEmpty
          ? 'No advice generated. Please try again.'
          : responseText.trim();
    } catch (e) {
      return 'Error: Could not connect to AI service. Please check your internet connection and try again.\n\nDetails: $e';
    }
  }

  /// Generates a concise clinical summary of a patient for the doctor.
  static Future<String> getPatientSummary({
    required Map<String, dynamic> patient,
    required List<Map<String, dynamic>> reports,
    required List<Map<String, dynamic>> notes,
    required List<Map<String, dynamic>> timeline,
  }) async {
    try {
      final systemInstruction =
          'You are a clinical summarisation assistant for doctors.\n\n'
          'RULES:\n'
          '1. Summarise the patient\'s medical history in a concise, structured way.\n'
          '2. Highlight critical information first: allergies, active diseases, current medicines.\n'
          '3. Note any potential drug interactions or contraindications.\n'
          '4. Summarise doctor notes and timeline events chronologically.\n'
          '5. Use clear Markdown formatting with headings, bold text, and bullet points.\n'
          '6. Keep the summary brief but comprehensive — a doctor should be able to glance at it before a consultation.\n'
          '7. End with a quick "Key Points for Consultation" section.\n'
          '8. Do NOT provide treatment advice. Only summarise existing data.';

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

      final responseText = await _callGroqApi(
        systemPrompt: systemInstruction,
        userPrompt: prompt,
      );

      return responseText.trim().isEmpty
          ? 'No summary generated. Please try again.'
          : responseText.trim();
    } catch (e) {
      return 'Error: Could not generate summary. Please check your internet connection and try again.\n\nDetails: $e';
    }
  }

  /// Extracts medicines, dosages, and timings from a prescription image.
  static Future<Map<String, dynamic>> extractPrescription(Uint8List imageBytes) async {
    final systemInstruction =
        'You are a highly accurate medical prescription reader.\n'
        'Extract the medicines, dosages, frequency, meal-timing context, and duration '
        'from the provided prescription image.\n\n'
        'IMPORTANT: Preserve the EXACT medical abbreviation written by the doctor for '
        'frequency (e.g., OD, BD, TDS, TID, QID, Q6H, Q8H, Q12H, SOS, PRN, STAT, HS).\n'
        'For timing_context, use the meal-relative abbreviation or phrase '
        '(e.g., AC, PC, "before meals", "after meals", "empty stomach", "before bed", "with meals").\n'
        'If the doctor wrote plain English like "Morning and Night", put that in frequency.\n\n'
        'Return ONLY a valid JSON object strictly following this schema without any markdown formatting:\n'
        '{\n'
        '  "medicines": [\n'
        '    {\n'
        '      "name": "Paracetamol",\n'
        '      "dosage": "500mg",\n'
        '      "frequency": "BD",\n'
        '      "timing_context": "PC",\n'
        '      "duration": "5 days",\n'
        '      "timings": ["Morning", "Night"]\n'
        '    }\n'
        '  ]\n'
        '}\n'
        'Rules:\n'
        '- "frequency" = the dosing frequency abbreviation or phrase (BD, TDS, OD, Q8H, etc.)\n'
        '- "timing_context" = meal relation (AC, PC, HS, empty stomach, etc.) or empty string if unspecified\n'
        '- "duration" = how long to take (e.g., "5 days", "1 week", "30 days") or empty string if unspecified\n'
        '- "timings" = still include the simple Morning/Afternoon/Night array as a fallback\n'
        'If no medicines are found, return {"medicines": []}.';

    final prompt = 'Extract the medicines from this prescription strictly using the requested JSON format. Ensure the output is valid JSON.';

    try {
      final responseText = await _callGroqVisionApi(
        systemPrompt: systemInstruction,
        userPrompt: prompt,
        imageBytes: imageBytes,
      );

      if (responseText.isEmpty) {
        throw Exception('No response from AI.');
      }

      // Parse the JSON strictly
      final cleanedText = _cleanJsonResponse(responseText);
      final data = jsonDecode(cleanedText) as Map<String, dynamic>;
      
      // Ensure the key exists
      if (!data.containsKey('medicines')) {
        return {'medicines': []};
      }

      return data;
    } catch (e) {
      throw Exception('Failed to extract medicines: $e');
    }
  }

  /// Spell-checks / corrects medicine names extracted by OCR.
  static Future<Map<String, String>> correctMedicineNames(List<String> names) async {
    if (names.isEmpty) return {};

    try {
      final systemInstruction =
          'You are a pharmaceutical spell-checker.\n\n'
          'TASK:\n'
          'Given a JSON array of medicine names extracted via OCR from a '
          'handwritten prescription, verify each name:\n'
          '- If the name is a valid, correctly-spelled medicine, keep it exactly as-is.\n'
          '- If the name is misspelled or garbled, return the CLOSEST MATCHING '
          'real pharmaceutical / brand / generic medicine name.\n'
          '- Preserve the original casing style (e.g., if input is uppercase keep uppercase).\n\n'
          'Return ONLY a valid JSON object with this schema:\n'
          '{\n'
          '  "corrections": [\n'
          '    {"original": "Paracetamol", "corrected": "Paracetamol", "changed": false},\n'
          '    {"original": "Amoxycilln", "corrected": "Amoxicillin", "changed": true}\n'
          '  ]\n'
          '}\n'
          'RULES:\n'
          '- One entry per input name, in the same order.\n'
          '- "changed" is true only if you modified the name.\n'
          '- Do NOT add medicines that were not in the input.\n'
          '- Do NOT remove any medicines from the input.';

      final prompt = 'Verify and correct these medicine names:\n${jsonEncode(names)}';
      
      final responseText = await _callGroqApi(
        systemPrompt: systemInstruction,
        userPrompt: prompt,
        jsonMode: true,
      );

      if (responseText.isEmpty) return {};

      final cleanedText = _cleanJsonResponse(responseText);
      final data = jsonDecode(cleanedText) as Map<String, dynamic>;
      final corrections = List<Map<String, dynamic>>.from(data['corrections'] ?? []);

      final result = <String, String>{};
      for (final c in corrections) {
        final original = c['original']?.toString() ?? '';
        final corrected = c['corrected']?.toString() ?? original;
        if (original.isNotEmpty) {
          result[original] = corrected;
        }
      }
      return result;
    } catch (e) {
      // On failure, return empty map — caller will keep original names
      return {};
    }
  }
}
