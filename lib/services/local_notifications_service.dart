import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'comunidad_service.dart';

class LocalNotificationsService {
  LocalNotificationsService._internal();
  static final LocalNotificationsService instance = LocalNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;

  // Canal Android
  static const String _channelId = 'competitive_alerts';
  static const String _channelName = 'Alertas competitivas';
  static const String _channelDesc = 'Avisos sobre tu posición y actividad en rankings';

  // Reglas generales (solo aplican cuando immediateMode=false)
  Duration pollingInterval = const Duration(minutes: 15);
  Duration minCooldown = const Duration(hours: 2);
  int maxPerDay = 3;
  int closeGapThreshold = 10; // diferencia de puntos
  bool enableQuietHours = true;
  int quietStartHour = 22; // 22:00
  int quietEndHour = 7; // 07:00

  // Modo inmediato: sin cooldown, sin horario silencioso, evalúa TODAS las comunidades y envía todas.
  bool immediateMode = true; // ✅ por defecto inmediato según lo solicitado

  // Recordatorios cada 2 días si no hubo eventos
  final Duration reminderInterval = const Duration(days: 2);
  final List<String> reminderMessages = const [
    'Recuerda sumar puntos hoy. ¡No te quedes atrás! 🚗💨',
    'Tu comunidad te espera. Conduce y gana puntos. 🏁',
    'Sigue avanzando para mantener tu clasificación. 📈',
  ];

  bool _initialized = false;
  bool _permissionGranted = false;
  int _autoId = 1000;

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: initAndroid);

    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      // Pedir permiso (Android 13+)
      await ensurePermission();

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ),
      );
    } else {
      _permissionGranted = true;
    }

    _initialized = true;
    if (kDebugMode) debugPrint('🔔 Notificaciones inicializadas. Permiso=$_permissionGranted');
  }

  Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) {
      _permissionGranted = true;
      return true;
    }
    final status = await Permission.notification.status;
    if (status.isGranted) {
      _permissionGranted = true;
      return true;
    }
    final result = await Permission.notification.request();
    _permissionGranted = result.isGranted;
    if (!_permissionGranted) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      try {
        _permissionGranted = (await androidImpl?.requestNotificationsPermission()) ?? false;
      } catch (_) {}
    }
    return _permissionGranted;
  }

  Future<void> ensureFirstPromptAndTest() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('lns_intro_test_shown') ?? false;
    if (shown) return;

    final ok = await ensurePermission();
    if (!ok) return;

    await sendTest(
      title: '🔔 Notificaciones activadas',
      body: 'Te avisaremos de cambios en tu ranking y logros. Puedes desactivarlas en Ajustes.',
    );
    await prefs.setBool('lns_intro_test_shown', true);
  }

  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  Future<void> startPolling({Duration? interval}) async {
    await init();
    if (!_permissionGranted) return;

    _timer?.cancel();

    if (immediateMode) {
      // Modo pruebas/inmediato
      enableQuietHours = false;
      minCooldown = Duration.zero;
      maxPerDay = 9999;
      pollingInterval = interval ?? const Duration(seconds: 15);
    } else {
      // Modo normal
      pollingInterval = interval ?? pollingInterval;
    }

    // chequeo inmediato y luego periódico
    unawaited(_checkAndNotify());
    _timer = Timer.periodic(pollingInterval, (_) => _checkAndNotify());

    if (kDebugMode) {
      final desc = pollingInterval.inSeconds < 60
          ? '${pollingInterval.inSeconds}s'
          : '${pollingInterval.inMinutes}m';
      debugPrint('🔁 Polling notificaciones cada $desc (immediateMode=$immediateMode)');
    }
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    if (kDebugMode) debugPrint('⏸️ Polling detenido');
  }

  Future<void> _checkAndNotify() async {
    if (!_permissionGranted) return;

    final prefs = await SharedPreferences.getInstance();

    // Límites solo en modo normal
    String? dayKey;
    int dayCount = 0;
    if (!immediateMode) {
      if (enableQuietHours && _isInQuietHours(DateTime.now())) {
        if (kDebugMode) debugPrint('🌙 Silencio activo');
        return;
      }
      final lastNotifiedMs = prefs.getInt('lns_last_notified_ms') ?? 0;
      if (lastNotifiedMs > 0) {
        final last = DateTime.fromMillisecondsSinceEpoch(lastNotifiedMs);
        if (DateTime.now().difference(last) < minCooldown) {
          if (kDebugMode) debugPrint('⏱️ Cooldown activo');
          return;
        }
      }
      dayKey = _formatDayKey(DateTime.now());
      dayCount = prefs.getInt('lns_day_count_$dayKey') ?? 0;
      if (dayCount >= maxPerDay) {
        if (kDebugMode) debugPrint('📵 Límite diario $dayCount/$maxPerDay');
        return;
      }
    }

    // Obtener comunidades
    final comunidadSvc = ComunidadService();
    Map<String, dynamic> result;
    try {
      result = await comunidadSvc.obtenerMisComunidades();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Comunidades error: $e');
      // Si no se puede consultar, intentar recordatorio si aplica
      await _maybeSendReminder(prefs);
      return;
    }

    // Tolerancia a diferentes envolturas del backend
    dynamic rawComus = result['comunidades'] ?? result['data'] ?? result['mis_comunidades'] ?? result['items'];
    if (rawComus == null && result is List) rawComus = result;
    if (rawComus == null) {
      await _maybeSendReminder(prefs);
      return;
    }

    final comunidades = List<Map<String, dynamic>>.from(rawComus);
    if (comunidades.isEmpty) {
      await _maybeSendReminder(prefs);
      return;
    }

    int sent = 0;

    // Evaluar TODAS las comunidades y notificar todas las que apliquen
    for (final comunidad in comunidades) {
      final int comunidadId = (comunidad['id'] ?? comunidad['comunidad_id'] ?? 0) as int;
      final String communityName = (comunidad['nombre'] ?? comunidad['name'] ?? 'tu comunidad').toString();

      final usuariosRaw = comunidad['usuarios'];
      if (usuariosRaw is! List) continue;
      final usuarios = List<Map<String, dynamic>>.from(usuariosRaw);

      final myData = _findMeAndPosition(usuarios);
      final int? myPos = myData['posicion'];
      final int myPts = myData['puntos'] ?? 0;

      final String posKey = 'lns_last_pos_$comunidadId';
      final String ptsKey = 'lns_last_pts_$comunidadId';
      final int? prevPos = prefs.getInt(posKey);

      final List<_Notif> notifs = [];

      // 0) Validación de datos previos: si no había baseline, solo guardamos y continuamos sin notificar falsos positivos
      if (prevPos == null && myPos != null) {
        await prefs.setInt(posKey, myPos);
        await prefs.setInt(ptsKey, myPts);
        continue;
      }

      // 1) Me quitaron el primer lugar (solo si antes realmente eras 1.º)
      if (prevPos == 1 && (myPos != null && myPos > 1)) {
        notifs.add(_Notif(
          title: '🥇 Te quitaron el 1.º',
          body: 'En $communityName perdiste el liderato. ¡Recupéralo! 💪',
        ));
      }

      // 1b) En general: bajaste posiciones
      if (prevPos != null && myPos != null && myPos > prevPos) {
        final delta = myPos - prevPos;
        notifs.add(_Notif(
          title: '⬇️ Te superaron',
          body: 'En $communityName bajaste a ${myPos}. ${delta > 1 ? 'Cayeste $delta puestos.' : 'No te quedes atrás.'}',
        ));
      }

      // 2) Te pisan los talones (si eres 1.º)
      if (myPos == 1 && usuarios.length >= 2) {
        final sorted = [...usuarios]..sort((a, b) => (b['puntaje'] ?? 0).compareTo(a['puntaje'] ?? 0));
        final int topPts = (sorted.first['puntaje'] ?? 0) as int;
        final int secondPts = (sorted[1]['puntaje'] ?? 0) as int;
        final gap = topPts - secondPts;
        if (gap <= closeGapThreshold) {
          notifs.add(_Notif(
            title: '⚠️ Te pisan los talones',
            body: 'En $communityName el 2.º está a $gap pts. ¡Mantén el ritmo! 🏁',
          ));
        }
      }

      // 3) Subiste 3+ posiciones
      if (myPos != null && prevPos != null && prevPos - myPos >= 3) {
        notifs.add(_Notif(
          title: '📈 ¡Vas con todo!',
          body: 'En $communityName subiste ${prevPos - myPos} posiciones. 🚀',
        ));
      }

      // 4) A pocos puntos del siguiente
      if (myPos != null && myPos > 1) {
        final sorted = [...usuarios]..sort((a, b) => (b['puntaje'] ?? 0).compareTo(a['puntaje'] ?? 0));
        final idx = sorted.indexWhere((u) => u['es_usuario_actual'] == true || u['es_actual'] == true);
        if (idx > 0) {
          final int aheadPts = (sorted[idx - 1]['puntaje'] ?? 0) as int;
          final diff = aheadPts - myPts;
          if (diff > 0 && diff <= 20) {
            notifs.add(_Notif(
              title: '🎯 A $diff pts del siguiente',
              body: 'En $communityName estás cerca de subir un puesto. 🙌',
            ));
          }
        }
      }

      // Enviar todas las notificaciones de esta comunidad
      for (final n in notifs) {
        await _show(n.title, n.body);
        sent++;
      }

      // Actualizar baseline de esta comunidad (aunque no haya notificado)
      await prefs.setInt(posKey, myPos ?? prevPos ?? 0);
      await prefs.setInt(ptsKey, myPts);
    }

    // Recordatorio si no hubo nada que notificar
    if (sent == 0) {
      await _maybeSendReminder(prefs);
    }

    // Persistencia global solo en modo normal
    if (!immediateMode && sent > 0) {
      await prefs.setInt('lns_last_notified_ms', DateTime.now().millisecondsSinceEpoch);
      final String dKey = _formatDayKey(DateTime.now());
      final int dCount = prefs.getInt('lns_day_count_$dKey') ?? 0;
      await prefs.setInt('lns_day_count_$dKey', dCount + sent);
    }
  }

  Future<void> _show(String title, String body) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    _autoId++;
    await _plugin.show(_autoId, title, body, details);
  }

  Future<void> sendTest({String title = '🔔 Prueba de notificaciones', String body = 'Si ves esto, las notificaciones locales funcionan.'}) async {
    if (!_permissionGranted) {
      final ok = await ensurePermission();
      if (!ok) return;
    }
    await _show(title, body);
  }

  Future<void> _maybeSendReminder(SharedPreferences prefs) async {
    final lastMs = prefs.getInt('lns_last_reminder_ms') ?? 0;
    final now = DateTime.now();
    if (lastMs > 0) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (now.difference(last) < reminderInterval) {
        return; // aún no toca
      }
    }
    // Rotar mensajes
    int idx = prefs.getInt('lns_reminder_index') ?? 0;
    final msg = reminderMessages[idx % reminderMessages.length];
    await _show('🔔 Recordatorio', msg);
    await prefs.setInt('lns_last_reminder_ms', now.millisecondsSinceEpoch);
    await prefs.setInt('lns_reminder_index', (idx + 1) % reminderMessages.length);
  }

  bool _isInQuietHours(DateTime now) {
    if (!enableQuietHours) return false;
    if (quietStartHour < quietEndHour) {
      return now.hour >= quietStartHour && now.hour < quietEndHour;
    } else {
      return now.hour >= quietStartHour || now.hour < quietEndHour;
    }
  }

  String _formatDayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  Map<String, dynamic> _findMeAndPosition(List<Map<String, dynamic>> usuarios) {
    // Intentar marca del backend
    Map<String, dynamic>? yo = usuarios.firstWhere(
      (u) => u['es_usuario_actual'] == true || u['es_actual'] == true,
      orElse: () => {},
    );

    if (yo.isNotEmpty) {
      final pos = yo['posicion'] is int ? yo['posicion'] as int : null;
      final pts = (yo['puntaje'] ?? 0) as int;
      if (pos != null && pos > 0) return {'posicion': pos, 'puntos': pts};

      final ordenados = [...usuarios]..sort(
        (a, b) => (b['puntaje'] ?? 0).compareTo(a['puntaje'] ?? 0),
      );
      final idx = ordenados.indexWhere((u) => identical(u, yo));
      return {'posicion': idx >= 0 ? idx + 1 : null, 'puntos': pts};
    }

    return {'posicion': null, 'puntos': 0};
  }
}

class _Notif {
  final String title;
  final String body;
  _Notif({required this.title, required this.body});
}
