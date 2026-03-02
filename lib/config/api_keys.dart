import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads API keys from the .env file at runtime.
/// NEVER hardcode secrets here — use the .env file instead.

String get GEMINI_API_KEY =>
    dotenv.env['GEMINI_API_KEY'] ?? '';
