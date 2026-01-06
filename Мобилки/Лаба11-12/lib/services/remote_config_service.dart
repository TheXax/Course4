import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  RemoteConfigService._internal();

  static final RemoteConfigService instance = RemoteConfigService._internal();

  FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;

  final ValueNotifier<Color> headerColorNotifier = ValueNotifier<Color>(const Color(0xFF3E4EB8));
  final ValueNotifier<bool> isLikeEnabledNotifier = ValueNotifier<bool>(true);

  Future<void> init() async {
    try {
      try {
        await _rc.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10), //сколько ждать ответ
          minimumFetchInterval: Duration.zero,
        ));
      } catch (_) {}
      await _rc.setDefaults(<String, dynamic>{
        'like_enabled': true,
        'header_color': '#3E4EB8',
      });

      await _rc.fetchAndActivate();

      _applyValues();
    } catch (e) {
      // ignore errors, keep defaults
      if (kDebugMode) {
        // ignore: avoid_print
        print('RemoteConfig init error: $e');
      }
      _applyValues();
    }
  }

  //подтягивают значения из Firebase
  Future<void> fetchNow() async {
    try {
      await _rc.fetchAndActivate();
      _applyValues();
    } catch (e) {
      _applyValues();
    }
  }

  void _applyValues() {
    try {
      final likeEnabled = _rc.getBool('like_enabled');
      final colorStr = _rc.getString('header_color');
      isLikeEnabledNotifier.value = likeEnabled;
      headerColorNotifier.value = _parseColor(colorStr) ?? const Color(0xFF3E4EB8);
    } catch (_) {
      // fallback to defaults
      isLikeEnabledNotifier.value = true;
      headerColorNotifier.value = const Color(0xFF3E4EB8);
    }
  }

  //преобразует строку из вне в объект цвета
  Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    var cleaned = hex.trim();
    // Accept 0x, #, or plain hex; add alpha if missing
    cleaned = cleaned.replaceAll('#', '');
    cleaned = cleaned.startsWith('0x') ? cleaned.substring(2) : cleaned;
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    if (cleaned.length != 8) return null;
    try {
      final intVal = int.parse(cleaned, radix: 16);
      return Color(intVal);
    } catch (_) {
      return null;
    }
  }
}
