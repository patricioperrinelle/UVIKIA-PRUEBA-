// lib/5_modulos/modulo_chat_mensajes/controladores/controlador_chat.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../servicios/servicio_chat_supabase.dart';
import '../../../3_modelos/modelo_chat_mensaje.dart';

class ControladorChat extends ChangeNotifier with WidgetsBindingObserver {
  String trabajoId = '';
  String miId = '';
  String contraparteId = '';
  
  Function(String codigoSys, bool esCargaInicial)? onMensajeSistemaDetectado;

  static final Map<String, List<ModeloMensaje>> _memoriaChats = {};

  List<ModeloMensaje> mensajes = [];
  bool isLoading = false;
  bool isChatExpanded = false;
  int unreadMessages = 0;

  final TextEditingController inputController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();
  
  final Set<String> _mensajesSistemaProcesados = {}; 
  static final Set<String> _mensajesNotificadosGlobal = {};
  
  bool _isFirstChatLoad = true;
  bool _isObserverAdded = false;

  Timer? _watchdogTimer; 
  Timer? _debounceTimer; 
  Timer? _reconnectTimer;
  RealtimeChannel? _chatChannel;

  ControladorChat({this.onMensajeSistemaDetectado});

  void inicializar({
    required String pTrabajoId,
    required String pMiId,
    required String pContraparteId,
    bool iniciarExpandido = false,
  }) {
    if (!_isObserverAdded) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverAdded = true;
    }

    trabajoId = pTrabajoId;
    miId = pMiId;
    contraparteId = pContraparteId;
    isChatExpanded = iniciarExpandido;
    
    // 1. Carga instantánea de memoria RAM estática (si existe)
    mensajes = _memoriaChats[trabajoId] ?? [];
    isLoading = mensajes.isEmpty; 
    _mensajesSistemaProcesados.clear();
    
    _isFirstChatLoad = true;
    
    Future.microtask(() => notifyListeners());

    _cargarHistorialSWR();
    _iniciarMotorReactivoLocal();
  }

  // 🛡️ Método centralizado para respaldar RAM en Disco Duro
  Future<void> _guardarCacheSWR() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataCruda = mensajes.map((m) => m.toJson()).toList();
      await prefs.setString('chat_cache_$trabajoId', jsonEncode(dataCruda));
    } catch (_) {}
  }

  Future<void> _cargarHistorialSWR() async {
    // 2. Carga desde Disco Persistente
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('chat_cache_$trabajoId');
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        // 🛠️ FIX ARQUITECTÓNICO: Mapeo estricto para evitar TypeErrors en Android/iOS al decodificar JSON
        final List<Map<String, dynamic>> listaSegura = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _procesarListaMensajes(listaSegura, esParcheEnVivo: false);
      }
    } catch (_) {}

    // 3. Fetch de red
    try {
      final listaCruda = await ServicioChatSupabase.obtenerHistorialMensajes(trabajoId);
      
      // 🛡️ Barrera Anti-Destrucción: Evita que un micro-corte limpie la caché
      if (listaCruda.isEmpty && mensajes.isNotEmpty) {
        throw Exception("Falso positivo de red. Conservando caché offline del chat.");
      }
      
      _procesarListaMensajes(listaCruda, esParcheEnVivo: false);
    } catch (e) {
      debugPrint('[SWR] Fallo red en Chat. UI sobrevive con caché local.');
    } finally {
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cargarHistorialSWR();
      _iniciarMotorReactivoLocal(); 
    } else if (state == AppLifecycleState.paused) {
      _watchdogTimer?.cancel();
      _limpiarCanal(); 
    }
  }

  void _reiniciarWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 120), () {
      _cargarHistorialSWR();
    });
  }

  Future<void> _limpiarCanal() async {
    if (_chatChannel != null) {
      try {
        await _chatChannel!.unsubscribe();
        await Supabase.instance.client.removeChannel(_chatChannel!);
      } catch (e) {}
      _chatChannel = null;
    }
  }

  void _iniciarMotorReactivoLocal() async {
    await _limpiarCanal(); 

    _chatChannel = Supabase.instance.client.channel('chat_live_$trabajoId');

    _chatChannel!
      .onPostgresChanges(
        event: PostgresChangeEvent.insert, 
        schema: 'public', 
        table: 'mensajes', 
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'trabajo_id', value: trabajoId.toString()), 
        callback: _manejarEventoRealtime
      )
      .subscribe((RealtimeSubscribeStatus status, [Object? error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _reiniciarWatchdog();
        } else if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
          if (_reconnectTimer?.isActive ?? false) return; 
          _reconnectTimer = Timer(const Duration(seconds: 5), () {
            _cargarHistorialSWR(); 
            _iniciarMotorReactivoLocal(); 
          });
        }
      });
  }

  void _manejarEventoRealtime(dynamic payload) {
    _reiniciarWatchdog();
    
    final record = payload.newRecord as Map<String, dynamic>?;
    if (record != null) {
      final String msgId = record['id']?.toString() ?? '';
      final String textoReal = record['texto']?.toString() ?? '';
      bool yaExiste = mensajes.any((m) => m.id == msgId);
      
      if (!yaExiste) {
        mensajes.removeWhere((m) => m.id.startsWith('temp_') && m.texto == textoReal);
        _procesarListaMensajes([record], esParcheEnVivo: true);
        return; 
      }
    }

    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _cargarHistorialSWR();
    });
  }

  @override
  void dispose() {
    if (_isObserverAdded) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _watchdogTimer?.cancel();
    _debounceTimer?.cancel();
    _reconnectTimer?.cancel();
    _limpiarCanal();
    inputController.dispose();
    inputFocusNode.dispose();
    super.dispose();
  }

  void toggleExpandido(bool expandido) {
    isChatExpanded = expandido;
    if (expandido) {
      unreadMessages = 0;
      _marcarComoLeidosDB();
    }
    notifyListeners();
  }

  void _procesarListaMensajes(List<Map<String, dynamic>> listaCruda, {bool esParcheEnVivo = false}) async {
    final List<ModeloMensaje> listaFiltrada = esParcheEnVivo ? List.from(mensajes) : [];
    int nuevosNoLeidos = 0;
    bool dispararAlarma = false;
    String? ultimoSys;

    for (var row in listaCruda) {
      final String msgId = row['id']?.toString() ?? '';
      final String emisorId = row['emisor_id']?.toString() ?? '';
      final String receptorId = row['receptor_id']?.toString() ?? '';
      final String texto = row['texto']?.toString() ?? '';
      final bool leido = row['leido'] == true;

      bool relevante = (emisorId == miId && receptorId == contraparteId) || 
                       (emisorId == contraparteId && receptorId == miId);
      
      if (!relevante && receptorId != 'null' && receptorId.isNotEmpty) continue;

      if (texto.startsWith('SYS_')) {
        if (_isFirstChatLoad) {
           if (ultimoSys == null) ultimoSys = texto; 
           _mensajesSistemaProcesados.add(msgId);
        } else {
           if (!_mensajesSistemaProcesados.contains(msgId)) {
             _mensajesSistemaProcesados.add(msgId);
             onMensajeSistemaDetectado?.call(texto, false); 
           }
        }
        try { 
          if (esParcheEnVivo) { listaFiltrada.insert(0, ModeloMensaje.fromJson(row)); } 
          else { listaFiltrada.add(ModeloMensaje.fromJson(row)); }
        } catch(_) {}
        continue;
      }

      try { 
         if (esParcheEnVivo) { listaFiltrada.insert(0, ModeloMensaje.fromJson(row)); } 
         else { listaFiltrada.add(ModeloMensaje.fromJson(row)); }
      } catch(_) {}

      if (emisorId != miId && !leido) {
        nuevosNoLeidos++;
        if (!_mensajesNotificadosGlobal.contains(msgId)) {
          dispararAlarma = true;
          _mensajesNotificadosGlobal.add(msgId);
        }
      }
    }

    if (_isFirstChatLoad && ultimoSys != null) {
       Future.microtask(() => onMensajeSistemaDetectado?.call(ultimoSys!, true));
    }
    _isFirstChatLoad = false;

    // 🛡️ SINCRONÍA ABSOLUTA (Memoria RAM + Disco)
    mensajes = listaFiltrada;
    _memoriaChats[trabajoId] = mensajes; 
    _guardarCacheSWR(); 

    isLoading = false;

    if (isChatExpanded) {
      unreadMessages = 0;
      if (nuevosNoLeidos > 0) _marcarComoLeidosDB();
    } else {
      if (!esParcheEnVivo) unreadMessages = nuevosNoLeidos; 
      else unreadMessages += nuevosNoLeidos;
      if (dispararAlarma) _ejecutarAlarmaSonora();
    }
    notifyListeners();
  }

  Future<void> enviarMensaje(BuildContext context) async {
    final texto = inputController.text.trim();
    if (texto.isEmpty || contraparteId.isEmpty) return;
    inputController.clear(); 
    
    final mensajeFalso = ModeloMensaje(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      trabajoId: trabajoId, emisorId: miId, receptorId: contraparteId,
      texto: texto, fecha: DateTime.now().toIso8601String(), leido: false
    );
    
    // UI Optimista -> Guardar en RAM y en Disco de forma atómica
    mensajes.insert(0, mensajeFalso);
    _memoriaChats[trabajoId] = mensajes; 
    _guardarCacheSWR(); 
    notifyListeners();

    try {
      await ServicioChatSupabase.enviarMensajeTexto(trabajoId: trabajoId, emisorId: miId, receptorId: contraparteId, texto: texto);
      await Supabase.instance.client.from('notificaciones').insert({
        'usuario_id': contraparteId, 'trabajo_id': trabajoId, 'titulo': 'Nuevo Mensaje', 'mensaje': texto, 'tipo': 'mensaje',
      });
    } catch (e) {
      // Rollback si falla la red -> Guardar rollback en RAM y Disco
      mensajes.removeWhere((m) => m.id == mensajeFalso.id); 
      _memoriaChats[trabajoId] = mensajes; 
      _guardarCacheSWR(); 
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _marcarComoLeidosDB() async {
    if (contraparteId.isEmpty) return;
    await ServicioChatSupabase.marcarMensajesComoLeidos(trabajoId: trabajoId, miId: miId, contraparteId: contraparteId);
  }

  Future<void> _ejecutarAlarmaSonora() async {
    try {
      FlutterRingtonePlayer().playNotification();
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) Vibration.vibrate(duration: 300);
    } catch (_) {}
  }
}