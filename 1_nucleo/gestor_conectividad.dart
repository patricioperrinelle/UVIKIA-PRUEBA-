// lib/1_nucleo/gestor_conectividad.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'gestor_sincronizacion_offline.dart';

// =================================================================
// WRAPPER GLOBAL (Conectividad + Cierre de Teclados)
// =================================================================

class GlobalConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const GlobalConnectivityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<GlobalConnectivityWrapper> createState() => _GlobalConnectivityWrapperState();
}

class _GlobalConnectivityWrapperState extends State<GlobalConnectivityWrapper> {
  bool _hasConnection = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionState);
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionState(results);
  }

  void _updateConnectionState(List<ConnectivityResult> results) {
    final bool hasConn = !results.contains(ConnectivityResult.none);
    
    // Disparar sincronización si vuelve el internet
    if (!_hasConnection && hasConn) {
      OfflineSyncManager().processQueue();
    }

    if (_hasConnection != hasConn && mounted) {
      setState(() => _hasConnection = hasConn);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        textDirection: TextDirection.ltr,
        children:[
          widget.child,
          
          // Banner UX no intrusivo y passthrough de toques
          if (!_hasConnection)
            IgnorePointer( // Permite clickear la AppBar que quede detrás
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const[
                        Icon(Icons.wifi_off_rounded, color: Color(0xFFFFC107), size: 14), // Warning Yellow
                        SizedBox(width: 8),
                        Text(
                          'Modo Offline: Datos guardados', 
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, decoration: TextDecoration.none, fontFamily: 'Manrope'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}