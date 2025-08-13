import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/scoring_config.dart';

// Enum local (sin plugins)
enum CallState { RINGING, OFFHOOK, IDLE }

// Canal nativo para estados de llamada (Android)
const EventChannel _callStateChannel =
    EventChannel('com.example.ruta_map_frontend/call_state');

// ✅ Canal nativo para UsageStats (apps abiertas)
const MethodChannel _usageChannel =
    MethodChannel('com.example.ruta_map_frontend/usage_stats');

class DistractionSummary {
  final int appsAbiertas;
  final int llamadasContestadas;
  final int llamadasRechazadasONoContestadas;
  final int deltaPuntos;
  final String motivo;

  const DistractionSummary({
    required this.appsAbiertas,
    required this.llamadasContestadas,
    required this.llamadasRechazadasONoContestadas,
    required this.deltaPuntos,
    required this.motivo,
  });

  bool get hayCambios => deltaPuntos != 0;
}

class DistractionMonitorService {
  DistractionMonitorService._();
  static final DistractionMonitorService instance = DistractionMonitorService._();

  bool _sessionActiva = false;
  DateTime? _bgStart; // se mantiene por compatibilidad, pero no penalizamos “otras apps”
  int _deltaAcumuladoSesion = 0;

  // Llamadas
  StreamSubscription<dynamic>? _callStateSub;
  CallState? _lastCallState;
  bool _hayLlamadaEntrante = false;
  bool _fueContestada = false;
  int _llamadasContestadasTotal = 0;
  int _llamadasNoContestadasTotal = 0;

  // Para no duplicar reportes entre regresos
  int _contestadasReportadas = 0;
  int _noContestadasReportadas = 0;

  Future<void> startSession() async {
    _reset();
    _sessionActiva = true;

    if (!Platform.isAndroid) return;
    await _asegurarPermisos();

    // Sugerir permiso de uso una vez al iniciar sesión (no obligatorio)
    try {
      final hasUsage = await _hasUsagePermission();
      if (hasUsage != true) {
        print('ℹ️ Acceso al uso no concedido. Abriendo ajustes…');
        await _openUsageSettings();
      }
    } catch (_) {}

    // Escuchar estados de llamada desde Android (EventChannel)
    _callStateSub?.cancel();
    _callStateSub = _callStateChannel.receiveBroadcastStream().listen((dynamic s) {
      final v = (s?.toString() ?? '').toUpperCase();
      if (v == 'RINGING') _procesarTransicionLlamada(CallState.RINGING);
      if (v == 'OFFHOOK') _procesarTransicionLlamada(CallState.OFFHOOK);
      if (v == 'IDLE') _procesarTransicionLlamada(CallState.IDLE);
    }, onError: (e) {
      print('❌ call_state stream error: $e');
    });
  }

  Future<void> stopSession() async {
    _sessionActiva = false;
    await _callStateSub?.cancel();
    _callStateSub = null;
  }

  void markBackgroundStart() {
    if (!_sessionActiva) return;
    _bgStart = DateTime.now(); // se mantiene por compatibilidad (no penalizamos apps)
  }

  Future<DistractionSummary> summarizeOnForeground() async {
    if (!_sessionActiva) {
      return const DistractionSummary(
        appsAbiertas: 0,
        llamadasContestadas: 0,
        llamadasRechazadasONoContestadas: 0,
        deltaPuntos: 0,
        motivo: '',
      );
    }

    // Llamadas (deltas)
    final nuevasContestadas = _llamadasContestadasTotal - _contestadasReportadas;
    final nuevasNoContestadas = _llamadasNoContestadasTotal - _noContestadasReportadas;
    _contestadasReportadas = _llamadasContestadasTotal;
    _noContestadasReportadas = _llamadasNoContestadasTotal;

    // Apps abiertas durante background
    int appsAbiertas = 0;
    if (_bgStart != null && Platform.isAndroid) {
      try {
        final hasUsage = await _hasUsagePermission();
        if (hasUsage == true) {
          appsAbiertas = await _contarAppsAbiertasEntre(_bgStart!, DateTime.now());
        } else {
          print('ℹ️ Sin permiso de uso: no se contabilizan apps.');
        }
      } catch (e) {
        print('❌ Error consultando UsageStats: $e');
      } finally {
        _bgStart = null;
      }
    }

    // Tope por regreso
    final appsPenalizadas = appsAbiertas > 0
        ? (appsAbiertas > ScoringConfig.maxAppsPorRegreso
            ? ScoringConfig.maxAppsPorRegreso
            : appsAbiertas)
        : 0;

    int delta = 0;
    delta += nuevasContestadas * ScoringConfig.llamadaContestada;
    delta += nuevasNoContestadas * ScoringConfig.llamadaRechazadaONoContestada;
    delta += appsPenalizadas * ScoringConfig.puntosPorAppAjena;

    // Tope acumulado por sesión (negativo)
    final futuroAcumulado = _deltaAcumuladoSesion + delta;
    if (futuroAcumulado < ScoringConfig.maxPenalizacionAppsSesion) {
      final restante = ScoringConfig.maxPenalizacionAppsSesion - _deltaAcumuladoSesion;
      delta = restante;
    }
    _deltaAcumuladoSesion += delta;

    final motivoParts = <String>[];
    if (appsPenalizadas > 0) motivoParts.add('${appsPenalizadas} app(s) abiertas');
    if (nuevasContestadas > 0) motivoParts.add('$nuevasContestadas llamada(s) contestada(s)');
    if (nuevasNoContestadas > 0) motivoParts.add('$nuevasNoContestadas llamada(s) rechazadas/no contestadas');

    return DistractionSummary(
      appsAbiertas: appsAbiertas,
      llamadasContestadas: nuevasContestadas,
      llamadasRechazadasONoContestadas: nuevasNoContestadas,
      deltaPuntos: delta,
      motivo: motivoParts.isEmpty ? '' : motivoParts.join(' • '),
    );
  }

  // ✅ Bridging a Android
  Future<bool?> _hasUsagePermission() async {
    try {
      return await _usageChannel.invokeMethod<bool>('hasPermission');
    } catch (_) {
      return false;
    }
  }

  Future<void> _openUsageSettings() async {
    try {
      await _usageChannel.invokeMethod('openSettings');
    } catch (_) {}
  }

  Future<int> _contarAppsAbiertasEntre(DateTime start, DateTime end) async {
    try {
      final count = await _usageChannel.invokeMethod<int>('queryForegroundCount', {
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
      });
      return count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _asegurarPermisos() async {
    final phonePerm = await Permission.phone.status;
    if (!phonePerm.isGranted) {
      await Permission.phone.request();
    }
  }

  void _procesarTransicionLlamada(CallState state) {
    if (state == CallState.RINGING) {
      _hayLlamadaEntrante = true;
      _fueContestada = false;
    } else if (state == CallState.OFFHOOK) {
      if (_hayLlamadaEntrante) _fueContestada = true;
    } else if (state == CallState.IDLE) {
      if (_hayLlamadaEntrante) {
        if (_fueContestada) {
          _llamadasContestadasTotal++;
        } else {
          _llamadasNoContestadasTotal++;
        }
      }
      _hayLlamadaEntrante = false;
      _fueContestada = false;
    }
    _lastCallState = state;
  }

  void _reset() {
    _bgStart = null;
    _deltaAcumuladoSesion = 0;
    _hayLlamadaEntrante = false;
    _fueContestada = false;
    _llamadasContestadasTotal = 0;
    _llamadasNoContestadasTotal = 0;
    _contestadasReportadas = 0;
    _noContestadasReportadas = 0;
    _lastCallState = null;
  }
}