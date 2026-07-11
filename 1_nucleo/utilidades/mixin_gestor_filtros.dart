// lib/1_nucleo/utilidades/mixin_gestor_filtros.dart

mixin MixinGestorFiltros {
  String palabraClave = '';
  String provinciaFiltro = '';
  String localidadFiltro = '';
  String categoriaFiltro = '';

  void dispararBusquedaAntiWipeout();

  void aplicarPaqueteFiltros(Map<String, String> paquete) {
    palabraClave = paquete['palabraClave'] ?? '';
    provinciaFiltro = paquete['provincia'] ?? '';
    localidadFiltro = paquete['localidad'] ?? '';
    categoriaFiltro = paquete['categoria'] ?? '';
    dispararBusquedaAntiWipeout();
  }

  void limpiarPalabraClave() { palabraClave = ''; dispararBusquedaAntiWipeout(); }
  void limpiarProvincia() { provinciaFiltro = ''; dispararBusquedaAntiWipeout(); }
  void limpiarLocalidad() { localidadFiltro = ''; dispararBusquedaAntiWipeout(); }
  void limpiarCategoria() { categoriaFiltro = ''; dispararBusquedaAntiWipeout(); }

  void limpiarFiltros() {
    palabraClave = ''; provinciaFiltro = ''; localidadFiltro = ''; categoriaFiltro = '';
    dispararBusquedaAntiWipeout();
  }
}
