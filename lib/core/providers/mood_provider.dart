import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mood_entry.dart';

class MoodProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  MoodEntry? _todayMood;
  MoodEntry? get todayMood => _todayMood;

  List<MoodEntry> _moodHistory = [];
  List<MoodEntry> get moodHistory => _moodHistory;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Simpan mood hari ini
  Future<void> saveMood(
    MoodType mood, {
    String? note,
    required Function(int difference) onScoreChanged,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      int oldScore = _todayMood?.mood.numericValue ?? 0;
      int newScore = mood.numericValue;
      int difference = newScore - oldScore;

      final today = DateTime.now();
      final entry = MoodEntry(
        userId: user.id,
        mood: mood,
        note: note,
        date: today,
        createdAt: today,
      );

      // Upsert: jika sudah ada mood hari ini, update
      await _supabase
          .from('mood_entries')
          .upsert(entry.toJson(), onConflict: 'user_id,date');

      _todayMood = entry;
      notifyListeners();

      // Notify caller to update profile score
      onScoreChanged(difference);
    } catch (e) {
      debugPrint('Error saving mood: $e');
      // Simpan secara lokal jika Supabase gagal
      _todayMood = MoodEntry(
        userId: 'local',
        mood: mood,
        note: note,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Ambil mood hari ini
  Future<void> fetchTodayMood() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _supabase
          .from('mood_entries')
          .select()
          .eq('user_id', user.id)
          .eq('date', today)
          .maybeSingle();

      if (response != null) {
        _todayMood = MoodEntry.fromJson(response);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching today mood: $e');
    }
  }

  /// Ambil riwayat mood (30 hari terakhir)
  Future<void> fetchMoodHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('mood_entries')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false)
          .limit(30);

      _moodHistory = (response as List)
          .map((json) => MoodEntry.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching mood history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
