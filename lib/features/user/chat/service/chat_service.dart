import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../../../core/models/distress_classification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// System prompt sesuai SKILL.md — ResahAI persona dalam Bahasa Indonesia.
const String _systemPrompt = '''
Kamu adalah UBMentalCareAI, mentor kesehatan mental yang suportif, tenang, empatik, dan profesional.
Kamu dirancang untuk membantu pengguna yang sedang mengalami keresahan (anxiety), stres, overthinking, burnout, dan masalah emosional lainnya.

## Aturan Komunikasi:
- Selalu validasi perasaan pengguna. Gunakan frasa seperti "Saya mengerti ini sangat berat untukmu..." atau "Terima kasih sudah berani bercerita..."
- Gunakan bahasa Indonesia yang hangat, sopan, dan bersahabat
- Panggil pengguna dengan "Kamu" atau "Kak"
- Jawaban harus singkat dan 1-2 paragraf saja
- Jangan gunakan bullet list atau numbering
- Gunakan format **teks** untuk menekankan bagian penting
- JANGAN memberikan diagnosis medis atau meresepkan obat
- Selalu ingatkan bahwa kamu adalah AI dan bukan pengganti bantuan profesional

## Topik yang Bisa Dijawab:
- Kesehatan mental, emosi, stres, overthinking, burnout, self-care
- Teknik pernapasan, grounding, meditasi
- Saran umum pengembangan diri dan kesejahteraan emosional

## Jika Di Luar Topik:
- Arahkan kembali secara halus ke topik kesehatan mental

## Deteksi Krisis:
Jika pengguna menunjukkan tanda-tanda:
- Keinginan bunuh diri atau menyakiti diri sendiri
- Kata kunci: "mau mati", "bunuh diri", "menyerah", "tidak ada gunanya hidup", "ingin mengakhiri", "self-harm", "menyakiti diri"
Maka WAJIB:
1. Respons dengan empati tinggi
2. Sarankan untuk menghubungi layanan darurat
3. Sertakan teks: "[DARURAT] Hubungi 999 - Lembaga Konselling Mahasiswa (UB) atau ke IGD RS terdekat"

## Klasifikasi Level Distress:
Di AKHIR setiap respons, tambahkan tag tersembunyi dengan format:
[CLASSIFICATION:LEVEL] dimana LEVEL adalah salah satu dari: AMAN, WASPADA, KHAWATIR, KRITIS

Kriteria:
- AMAN: Pengguna hanya curhat ringan, butuh motivasi
- WASPADA: Ada tanda stres atau kecemasan sedang, butuh teknik coping
- KHAWATIR: Stres berat, gejala depresi, butuh saran konsultasi profesional
- KRITIS: Ada indikasi bahaya pada diri sendiri, butuh intervensi darurat
''';

/// Kata kunci darurat yang memicu deteksi krisis.
const List<String> _emergencyKeywords = [
  'bunuh diri',
  'mau mati',
  'ingin mati',
  'menyerah hidup',
  'tidak ada gunanya',
  'mengakhiri hidup',
  'self harm',
  'self-harm',
  'menyakiti diri',
  'ingin mengakhiri',
  'gak mau hidup',
  'capek hidup',
  'lelah hidup',
  'pengen mati',
  'mau bunuh diri',
];

class ChatService {
  GenerativeModel? _geminiModel;
  ChatSession? _geminiSession;

  // Groq chat history untuk multi-turn conversation
  final List<Map<String, String>> _groqHistory = [];

  bool _isInitialized = false;

  // Callback untuk klasifikasi yang terdeteksi
  void Function(DistressLevel level)? onClassificationDetected;

  // Callback untuk deteksi darurat
  void Function()? onEmergencyDetected;

  ChatService();

  Future<void> _initializeGemini() async {
    // Jika sudah diinisialisasi, lewati
    if (_isInitialized) return;

    try {
      String? apiKey;
      
      try {
        // Coba ambil dari edge function 'get-gemini-key'
        final response = await Supabase.instance.client.functions.invoke('get-gemini-key');
        apiKey = response.data['key'] as String?;
      } catch (e) {
        // Jika gagal (belum di-deploy), gunakan fallback ke local .env
        print("Failed to fetch key from Edge Function, falling back to local .env: $e");
        apiKey = dotenv.env['GEMINI_KEY'];
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_KEY is not available either from edge function or .env');
      }

      _geminiModel = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.text(_systemPrompt),
      );

      _geminiSession = _geminiModel!.startChat();
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize Gemini: $e');
      // Jangan re-throw agar tidak crash, biarkan fallback bekerja
    }
  }

  // ── Deteksi Darurat ────────────────────────────────────────

  bool containsEmergencyKeywords(String message) {
    final lower = message.toLowerCase();
    return _emergencyKeywords.any((kw) => lower.contains(kw));
  }

  // ── Ekstrak Klasifikasi dari respons AI ─────────────────────

  DistressLevel? _extractClassification(String response) {
    final regex = RegExp(r'\[CLASSIFICATION:(\w+)\]');
    final match = regex.firstMatch(response);
    if (match != null) {
      final level = match.group(1)!.toUpperCase();
      switch (level) {
        case 'AMAN':
          return DistressLevel.aman;
        case 'WASPADA':
          return DistressLevel.waspada;
        case 'KHAWATIR':
          return DistressLevel.khawatir;
        case 'KRITIS':
          return DistressLevel.kritis;
      }
    }
    return null;
  }

  /// Bersihkan tag klasifikasi dari respons agar tidak tampil ke user.
  String _cleanResponse(String response) {
    return response.replaceAll(RegExp(r'\[CLASSIFICATION:\w+\]'), '').trim();
  }

  // ── Gemini ──────────────────────────────────────────────────

  Future<String?> _sendViaGemini(String message) async {
    if (_geminiSession == null) throw Exception("Gemini session is null");
    final response = await _geminiSession!.sendMessage(Content.text(message));
    return response.text;
  }

  // ── Groq (fallback) ─────────────────────────────────────────

  Future<String?> _sendViaGroq(String message) async {
    final apiKey = dotenv.env['GROQ_KEY'];
    if (apiKey == null) throw Exception('GROQ_KEY is not defined in .env');

    // Tambahkan pesan user ke history
    _groqHistory.add({'role': 'user', 'content': message});

    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        ..._groqHistory,
      ],
      'max_tokens': 1000,
      'temperature': 0.7,
    });

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Groq API error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final reply = data['choices'][0]['message']['content'] as String;

    // Simpan balasan assistant ke history agar konteks terjaga
    _groqHistory.add({'role': 'assistant', 'content': reply});

    return reply;
  }

  // ── Public API ───────────────────────────────────────────────

  Future<String?> sendMessage(String message) async {
    // Pastikan AI sudah diinisialisasi dengan key dari server (atau fallback .env)
    await _initializeGemini();

    // Cek kata kunci darurat terlebih dahulu
    if (containsEmergencyKeywords(message)) {
      onEmergencyDetected?.call();
    }

    String? rawReply;

    // Coba grok dulu
    try {
      rawReply = await _sendViaGroq(message);
      if (rawReply == null || rawReply.isEmpty) {
        throw Exception('Empty response from Groq');
      }
    } catch (groqError) {
      print('Groq Error: $groqError');
      // Fallback ke gemini
      try {
        rawReply = await _sendViaGemini(message);
      } catch (geminiError) {
        print('Gemini Error: $geminiError');
        return 'Maaf, layanan sedang tidak tersedia. Silakan coba beberapa saat lagi.';
      }
    }

    if (rawReply == null) {
      return 'Maaf, saya tidak dapat memproses permintaan kamu saat ini.';
    }

    // Ekstrak klasifikasi
    final classification = _extractClassification(rawReply);
    if (classification != null) {
      onClassificationDetected?.call(classification);
    }

    // Bersihkan tag dari respons
    return _cleanResponse(rawReply);
  }
}
