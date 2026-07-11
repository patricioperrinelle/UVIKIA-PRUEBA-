// lib/5_modulos/modulo_billetera/componentes/modal_agregar_cuenta_bancaria.dart

import 'package:flutter/material.dart';

import '../../../2_tema/colores_app.dart';
import '../../../2_tema/estilos_texto.dart';
import '../../../2_tema/dimensiones_app.dart';
import '../../../4_componentes_globales/formularios/campo_texto_cristal.dart';
import '../../../4_componentes_globales/botones/boton_accion_principal.dart';
import '../controladores/controlador_cuentas_bancarias.dart';

class ModalAgregarCuentaBancaria extends StatefulWidget {
  final ControladorCuentasBancarias controlador;

  const ModalAgregarCuentaBancaria({
    super.key,
    required this.controlador,
  });

  static void mostrar(BuildContext context, ControladorCuentasBancarias controlador) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalAgregarCuentaBancaria(controlador: controlador),
    );
  }

  @override
  State<ModalAgregarCuentaBancaria> createState() => _ModalAgregarCuentaBancariaState();
}

class _ModalAgregarCuentaBancariaState extends State<ModalAgregarCuentaBancaria> {
  final TextEditingController _cbuCtrl = TextEditingController();
  final TextEditingController _aliasCtrl = TextEditingController();
  final TextEditingController _bancoCtrl = TextEditingController();
  final TextEditingController _titularCtrl = TextEditingController();
  final TextEditingController _cuitCtrl = TextEditingController();

  @override
  void dispose() {
    _cbuCtrl.dispose();
    _aliasCtrl.dispose();
    _bancoCtrl.dispose();
    _titularCtrl.dispose();
    _cuitCtrl.dispose();
    super.dispose();
  }

  void _intentarGuardar() {
    FocusScope.of(context).unfocus(); // Ocultar teclado

    final String cbu = _cbuCtrl.text.trim();
    final String alias = _aliasCtrl.text.trim();

    // Validamos que haya puesto al menos uno de los dos
    if (cbu.isEmpty && alias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un CBU/CVU o un Alias.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: ColoresApp.advertenciaAmarillo,
        ),
      );
      return;
    }

    // Si solo puso el Alias, inyectamos un comodín para que la Base de Datos no rechace la operación
    final String cbuFinal = cbu.isEmpty ? 'SIN_CBU' : cbu;

    // 🚨 MUTACIÓN ESTRICTA
    widget.controlador.agregarCuentaBancaria(
      cbuCvu: cbuFinal,
      aliasBancario: alias,
      bancoProveedor: _bancoCtrl.text.trim(),
      titularCuenta: _titularCtrl.text.trim(),
      cuitDniTitular: _cuitCtrl.text.trim(),
      onSuccess: () {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta bancaria vinculada exitosamente.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: ColoresApp.primarioVerde,
          ),
        );
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: ColoresApp.errorRojo,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final insets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      // Elevamos el ListenableBuilder para que PopScope reaccione en tiempo real
      child: ListenableBuilder(
        listenable: widget.controlador,
        builder: (context, _) {
          return PopScope(
            // 🚨 ESCUDO ANTI-FUGA: No permite cerrar el modal si está guardando
            canPop: !widget.controlador.isSubmitting,
            child: Container(
              decoration: BoxDecoration(
                color: tema.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const Text('Agregar cuenta bancaria', style: EstilosTextoApp.h2, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Text('Ingresá los datos de tu cuenta para recibir pagos.', style: EstilosTextoApp.cuerpoRegular, textAlign: TextAlign.center),
                      const SizedBox(height: 32),

                      CampoTextoCristal(
                        labelText: 'CBU o CVU (22 dígitos) *',
                        hintText: 'Ingresá tu CBU o CVU',
                        controller: _cbuCtrl,
                        iconoPrefix: Icons.numbers_rounded,
                        tecladoNumerico: true,
                      ),
                      const SizedBox(height: 16),

                      CampoTextoCristal(
                        labelText: 'Alias bancario',
                        hintText: 'Ej: lucas.martinez',
                        controller: _aliasCtrl,
                        iconoPrefix: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 16),

                      CampoTextoCristal(
                        labelText: 'Banco proveedor',
                        hintText: 'Seleccioná tu banco o billetera',
                        controller: _bancoCtrl,
                        iconoPrefix: Icons.account_balance_rounded,
                      ),
                      const SizedBox(height: 16),

                      CampoTextoCristal(
                        labelText: 'Titular de la cuenta',
                        hintText: 'Nombre completo del titular',
                        controller: _titularCtrl,
                        iconoPrefix: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 16),

                      CampoTextoCristal(
                        labelText: 'CUIT / DNI',
                        hintText: 'Ingresá tu CUIT o DNI',
                        controller: _cuitCtrl,
                        iconoPrefix: Icons.badge_outlined,
                        tecladoNumerico: true,
                      ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColoresApp.terciarioMorado.withOpacity(0.05),
                          borderRadius: DimensionesApp.radioTarjetas,
                          border: Border.all(color: ColoresApp.terciarioMorado.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: ColoresApp.terciarioMorado),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Esta información está protegida y encriptada. Solo la usamos para procesar tus pagos.',
                                style: EstilosTextoApp.cuerpoPequeno.copyWith(color: ColoresApp.terciarioMorado),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 🚨 ESCUDO ANTI-DOBLE TAP
                      BotonAccionPrincipal(
                        texto: 'Guardar Cuenta',
                        isLoading: widget.controlador.isSubmitting,
                        onPressed: _intentarGuardar,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}