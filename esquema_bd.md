# ESQUEMA MAESTRO DE LA BASE DE DATOS (SUPABASE / POSTGRESQL)

🚨 REGLA ESTRICTA PARA LA IA:
Este archivo contiene la estructura real y exacta de las tablas de la base de datos de producción. Cuando debas escribir consultas SQL en los "servicios" o parsear "modelos" (fromJson/toJson), DEBES usar estrictamente los nombres de tablas y columnas que aparecen aquí abajo. Queda ABSOLUTAMENTE PROHIBIDO inventar o asumir nombres de tablas o propiedades.

| Tabla                      | Columna                          | Tipo de Dato             | Permite Nulos | Es Llave Primaria |
| -------------------------- | -------------------------------- | ------------------------ | ------------- | ----------------- |
| cuentas_bancarias_usuarios | id                               | uuid                     | NO            | SI (PK)           |
| cuentas_bancarias_usuarios | usuario_id                       | uuid                     | NO            |                   |
| cuentas_bancarias_usuarios | cbu_cvu                          | character varying        | NO            |                   |
| cuentas_bancarias_usuarios | alias_bancario                   | character varying        | YES           |                   |
| cuentas_bancarias_usuarios | banco_proveedor                  | character varying        | YES           |                   |
| cuentas_bancarias_usuarios | titular_cuenta                   | character varying        | YES           |                   |
| cuentas_bancarias_usuarios | cuit_dni_titular                 | character varying        | YES           |                   |
| cuentas_bancarias_usuarios | es_activa                        | boolean                  | NO            |                   |
| cuentas_bancarias_usuarios | fecha_eliminacion                | timestamp with time zone | YES           |                   |
| cuentas_bancarias_usuarios | fecha_alta                       | timestamp with time zone | NO            |                   |
| disputas                   | id                               | uuid                     | NO            | SI (PK)           |
| disputas                   | trabajo_id                       | uuid                     | NO            |                   |
| disputas                   | puja_id                          | uuid                     | YES           |                   |
| disputas                   | reportador_id                    | uuid                     | NO            |                   |
| disputas                   | reportado_id                     | uuid                     | NO            |                   |
| disputas                   | motivo                           | text                     | YES           |                   |
| disputas                   | descripcion                      | text                     | YES           |                   |
| disputas                   | categoria                        | text                     | YES           |                   |
| disputas                   | solucion_esperada                | text                     | YES           |                   |
| disputas                   | estado                           | text                     | YES           |                   |
| disputas                   | evidencia_urls                   | ARRAY                    | YES           |                   |
| disputas                   | historial_mediacion              | jsonb                    | YES           |                   |
| disputas                   | fecha_creacion                   | timestamp with time zone | YES           |                   |
| favoritos                  | id                               | uuid                     | NO            | SI (PK)           |
| favoritos                  | cliente_id                       | uuid                     | NO            |                   |
| favoritos                  | profesional_id                   | uuid                     | NO            |                   |
| favoritos                  | created_at                       | timestamp with time zone | NO            |                   |
| favoritos_catalogo         | usuario_id                       | uuid                     | NO            | SI (PK)           |
| favoritos_catalogo         | servicio_id                      | uuid                     | NO            | SI (PK)           |
| favoritos_catalogo         | created_at                       | timestamp with time zone | YES           |                   |
| mensajes                   | id                               | uuid                     | NO            | SI (PK)           |
| mensajes                   | trabajo_id                       | uuid                     | YES           |                   |
| mensajes                   | emisor_id                        | uuid                     | YES           |                   |
| mensajes                   | texto                            | text                     | NO            |                   |
| mensajes                   | fecha                            | timestamp with time zone | YES           |                   |
| mensajes                   | leido                            | boolean                  | YES           |                   |
| mensajes                   | receptor_id                      | uuid                     | YES           |                   |
| notificaciones             | id                               | uuid                     | NO            | SI (PK)           |
| notificaciones             | usuario_id                       | uuid                     | YES           |                   |
| notificaciones             | titulo                           | text                     | NO            |                   |
| notificaciones             | mensaje                          | text                     | NO            |                   |
| notificaciones             | tipo                             | text                     | YES           |                   |
| notificaciones             | leida                            | boolean                  | YES           |                   |
| notificaciones             | fecha_creacion                   | timestamp with time zone | YES           |                   |
| notificaciones             | trabajo_id                       | uuid                     | YES           |                   |
| notificaciones             | rol_destino                      | text                     | YES           |                   |
| perfiles                   | id                               | uuid                     | NO            | SI (PK)           |
| perfiles                   | apodo                            | text                     | YES           |                   |
| perfiles                   | bio                              | text                     | YES           |                   |
| perfiles                   | oficios                          | text                     | YES           |                   |
| perfiles                   | foto_url                         | text                     | YES           |                   |
| perfiles                   | fotos_portafolio                 | ARRAY                    | YES           |                   |
| perfiles                   | rating                           | double precision         | YES           |                   |
| perfiles                   | cantidad_resenas                 | integer                  | YES           |                   |
| perfiles                   | horarios                         | text                     | YES           |                   |
| perfiles                   | precio_base                      | text                     | YES           |                   |
| perfiles                   | tiempo_respuesta                 | text                     | YES           |                   |
| perfiles                   | experiencia                      | text                     | YES           |                   |
| perfiles                   | garantia                         | text                     | YES           |                   |
| perfiles                   | precio_hora                      | numeric                  | YES           |                   |
| perfiles                   | experiencia_anos                 | text                     | YES           |                   |
| perfiles                   | garantia_dias                    | text                     | YES           |                   |
| perfiles                   | servicios_detalle                | text                     | YES           |                   |
| perfiles                   | habilidades                      | text                     | YES           |                   |
| perfiles                   | resena_destacada_id              | uuid                     | YES           |                   |
| perfiles                   | zona_trabajo                     | text                     | YES           |                   |
| perfiles                   | fcm_token                        | text                     | YES           |                   |
| perfiles                   | mp_access_token                  | text                     | YES           |                   |
| perfiles                   | mp_refresh_token                 | text                     | YES           |                   |
| perfiles                   | mp_public_key                    | text                     | YES           |                   |
| perfiles                   | strikes                          | integer                  | YES           |                   |
| perfiles                   | telefono                         | text                     | YES           |                   |
| perfiles                   | es_profesional                   | boolean                  | YES           |                   |
| perfiles                   | rating_cliente                   | numeric                  | YES           |                   |
| perfiles                   | cantidad_resenas_cliente         | integer                  | YES           |                   |
| perfiles                   | miembro_desde                    | timestamp with time zone | YES           |                   |
| perfiles                   | score_confiabilidad_pro          | numeric                  | YES           |                   |
| perfiles                   | puntualidad                      | numeric                  | YES           |                   |
| perfiles                   | asistencia                       | numeric                  | YES           |                   |
| perfiles                   | jornadas_completadas             | numeric                  | YES           |                   |
| perfiles                   | cancelaciones_pro                | numeric                  | YES           |                   |
| perfiles                   | jornadas_realizadas              | integer                  | YES           |                   |
| perfiles                   | recomendacion_clientes           | numeric                  | YES           |                   |
| perfiles                   | score_confiabilidad_cliente      | numeric                  | YES           |                   |
| perfiles                   | cancelaciones_cliente            | numeric                  | YES           |                   |
| perfiles                   | tiempo_respuesta_minutos         | integer                  | YES           |                   |
| perfiles                   | disputas_abiertas                | numeric                  | YES           |                   |
| perfiles                   | trabajos_publicados              | integer                  | YES           |                   |
| perfiles                   | trabajadores_contratados         | integer                  | YES           |                   |
| perfiles                   | recomendacion_trabajadores       | numeric                  | YES           |                   |
| perfiles                   | rating_profesional               | numeric                  | YES           |                   |
| perfiles                   | cantidad_resenas_profesional     | integer                  | YES           |                   |
| perfiles                   | dni                              | text                     | YES           |                   |
| perfiles                   | codigo_compartible               | text                     | YES           |                   |
| perfiles                   | fecha_nacimiento                 | date                     | YES           |                   |
| perfiles                   | email                            | text                     | YES           |                   |
| perfiles                   | ciudad                           | text                     | YES           |                   |
| perfiles                   | localidad                        | text                     | YES           |                   |
| perfiles                   | barrio                           | text                     | YES           |                   |
| perfiles                   | habilidad_principal              | text                     | YES           |                   |
| perfiles                   | habilidades_secundarias          | jsonb                    | YES           |                   |
| perfiles                   | habilidades_especiales           | jsonb                    | YES           |                   |
| perfiles                   | certificaciones                  | jsonb                    | YES           |                   |
| perfiles                   | promedio_estrellas               | numeric                  | YES           |                   |
| pujas                      | id                               | uuid                     | NO            | SI (PK)           |
| pujas                      | trabajo_id                       | uuid                     | NO            |                   |
| pujas                      | profesional_id                   | uuid                     | NO            |                   |
| pujas                      | monto                            | numeric                  | NO            |                   |
| pujas                      | mensaje                          | text                     | YES           |                   |
| pujas                      | estado                           | text                     | YES           |                   |
| pujas                      | creado_en                        | timestamp with time zone | YES           |                   |
| pujas                      | coordenadas_llegada              | text                     | YES           |                   |
| pujas                      | checkin_hora                     | timestamp with time zone | YES           |                   |
| pujas                      | rechazado_por_cliente            | boolean                  | YES           |                   |
| pujas                      | notificacion_leida_cliente       | boolean                  | YES           |                   |
| pujas                      | notificacion_leida_pro           | boolean                  | YES           |                   |
| pujas                      | codigo_checkin                   | text                     | YES           |                   |
| pujas                      | codigo_checkout                  | text                     | YES           |                   |
| pujas                      | contrato_timestamp               | timestamp with time zone | YES           |                   |
| pujas                      | checkout_hora                    | timestamp with time zone | YES           |                   |
| pujas                      | cliente_califico_puja            | boolean                  | YES           |                   |
| pujas                      | pro_califico_puja                | boolean                  | YES           |                   |
| reportes                   | id                               | uuid                     | NO            | SI (PK)           |
| reportes                   | denunciante_id                   | uuid                     | NO            |                   |
| reportes                   | denunciado_id                    | uuid                     | NO            |                   |
| reportes                   | motivo                           | text                     | NO            |                   |
| reportes                   | fecha                            | timestamp with time zone | NO            |                   |
| resenas                    | id                               | uuid                     | NO            | SI (PK)           |
| resenas                    | trabajo_id                       | uuid                     | YES           |                   |
| resenas                    | evaluador_id                     | uuid                     | YES           |                   |
| resenas                    | evaluado_id                      | uuid                     | YES           |                   |
| resenas                    | rating                           | numeric                  | NO            |                   |
| resenas                    | comentario                       | text                     | NO            |                   |
| resenas                    | fecha_creacion                   | timestamp with time zone | YES           |                   |
| resenas                    | evaluador_nombre                 | text                     | YES           |                   |
| resenas                    | evaluador_avatar                 | text                     | YES           |                   |
| resenas                    | rol_evaluado                     | text                     | YES           |                   |
| servicios_catalogo         | id                               | uuid                     | NO            | SI (PK)           |
| servicios_catalogo         | profesional_id                   | uuid                     | YES           |                   |
| servicios_catalogo         | categoria                        | text                     | YES           |                   |
| servicios_catalogo         | titulo                           | text                     | NO            |                   |
| servicios_catalogo         | descripcion                      | text                     | YES           |                   |
| servicios_catalogo         | imagenes                         | ARRAY                    | YES           |                   |
| servicios_catalogo         | modalidad                        | text                     | YES           |                   |
| servicios_catalogo         | radio_cobertura_km               | integer                  | YES           |                   |
| servicios_catalogo         | zonas_cobertura_descripcion      | text                     | YES           |                   |
| servicios_catalogo         | direccion_local                  | text                     | YES           |                   |
| servicios_catalogo         | referencia_direccion_local       | text                     | YES           |                   |
| servicios_catalogo         | capacidad_simultanea             | integer                  | YES           |                   |
| servicios_catalogo         | tiempo_minimo_anticipacion_horas | integer                  | YES           |                   |
| servicios_catalogo         | tipos_contrato_soportados        | ARRAY                    | YES           |                   |
| servicios_catalogo         | usa_productos_premium            | boolean                  | YES           |                   |
| servicios_catalogo         | profesional_verificado           | boolean                  | YES           |                   |
| servicios_catalogo         | niveles                          | jsonb                    | YES           |                   |
| servicios_catalogo         | reglas_disponibilidad            | jsonb                    | YES           |                   |
| servicios_catalogo         | activo                           | boolean                  | YES           |                   |
| servicios_catalogo         | created_at                       | timestamp with time zone | YES           |                   |
| servicios_catalogo         | duracion_estimada                | text                     | YES           |                   |
| servicios_catalogo         | extras_opcionales                | jsonb                    | YES           |                   |
| servicios_catalogo         | preguntas_frecuentes             | jsonb                    | YES           |                   |
| servicios_catalogo         | estado                           | text                     | NO            |                   |
| servicios_catalogo         | etiquetas_confianza              | jsonb                    | YES           |                   |
| servicios_catalogo         | adicionales_presupuesto          | jsonb                    | YES           |                   |
| servicios_catalogo         | ciudad                           | text                     | YES           |                   |
| servicios_catalogo         | localidad                        | text                     | YES           |                   |
| tarjetas_guardadas         | id                               | uuid                     | NO            | SI (PK)           |
| tarjetas_guardadas         | usuario_id                       | uuid                     | YES           |                   |
| tarjetas_guardadas         | token_tarjeta                    | text                     | NO            |                   |
| tarjetas_guardadas         | payment_method_id                | text                     | NO            |                   |
| tarjetas_guardadas         | issuer_id                        | text                     | YES           |                   |
| tarjetas_guardadas         | payer_email                      | text                     | YES           |                   |
| tarjetas_guardadas         | apodo                            | text                     | NO            |                   |
| tarjetas_guardadas         | last_four                        | text                     | NO            |                   |
| tarjetas_guardadas         | card_name                        | text                     | YES           |                   |
| tarjetas_guardadas         | fecha_creacion                   | timestamp with time zone | YES           |                   |
| trabajos                   | id                               | uuid                     | NO            | SI (PK)           |
| trabajos                   | cliente_id                       | uuid                     | NO            |                   |
| trabajos                   | titulo                           | text                     | NO            |                   |
| trabajos                   | descripcion                      | text                     | NO            |                   |
| trabajos                   | fecha_hora                       | timestamp with time zone | NO            |                   |
| trabajos                   | estado                           | text                     | YES           |                   |
| trabajos                   | creado_en                        | timestamp with time zone | YES           |                   |
| trabajos                   | profesional_solicitado_id        | uuid                     | YES           |                   |
| trabajos                   | cliente_inicia                   | boolean                  | YES           |                   |
| trabajos                   | pro_inicia                       | boolean                  | YES           |                   |
| trabajos                   | cliente_finaliza                 | boolean                  | YES           |                   |
| trabajos                   | pro_finaliza                     | boolean                  | YES           |                   |
| trabajos                   | inicio_tarea                     | timestamp with time zone | YES           |                   |
| trabajos                   | fin_tarea                        | timestamp with time zone | YES           |                   |
| trabajos                   | duracion_segundos                | integer                  | YES           |                   |
| trabajos                   | cancelado_por_id                 | uuid                     | YES           |                   |
| trabajos                   | cliente_califico                 | boolean                  | YES           |                   |
| trabajos                   | pro_califico                     | boolean                  | YES           |                   |
| trabajos                   | metodo_pago                      | text                     | YES           |                   |
| trabajos                   | mp_card_token                    | text                     | YES           |                   |
| trabajos                   | mp_payment_id                    | text                     | YES           |                   |
| trabajos                   | mp_preference_id                 | text                     | YES           |                   |
| trabajos                   | precio_final_acordado            | text                     | YES           |                   |
| trabajos                   | cantidad_pujas                   | integer                  | YES           |                   |
| trabajos                   | created_at                       | timestamp with time zone | YES           |                   |
| trabajos                   | tipo_oferta                      | text                     | YES           |                   |
| trabajos                   | vacantes                         | integer                  | YES           |                   |
| trabajos                   | sueldo_base                      | numeric                  | YES           |                   |
| trabajos                   | telefono_contacto                | text                     | YES           |                   |
| trabajos                   | requisitos                       | text                     | YES           |                   |
| trabajos                   | precio                           | text                     | YES           |                   |
| trabajos                   | imagenes                         | jsonb                    | YES           |                   |
| trabajos                   | localidad                        | text                     | YES           |                   |
| trabajos                   | ubicacion_exacta                 | text                     | YES           |                   |
| trabajos                   | oficio                           | text                     | YES           |                   |
| trabajos                   | dificultad                       | text                     | YES           |                   |
| trabajos                   | hora_fin                         | text                     | YES           |                   |
| trabajos                   | metadata_reprogramacion          | jsonb                    | YES           |                   |
| trabajos                   | profesional_asignado_id          | text                     | YES           |                   |
| trabajos                   | servicio_catalogo_id             | text                     | YES           |                   |
| trabajos                   | codigo_checkin                   | text                     | YES           |                   |
| trabajos                   | codigo_checkout                  | text                     | YES           |                   |
| trabajos                   | coordenadas_llegada              | text                     | YES           |                   |
| trabajos                   | adicionales_presupuesto          | jsonb                    | YES           |                   |
| trabajos                   | estado_negociacion               | text                     | YES           |                   |
| trabajos                   | categoria                        | text                     | YES           |                   |
| trabajos                   | ciudad                           | text                     | YES           |                   |
| trabajos                   | fecha_vencimiento                | timestamp with time zone | YES           |                   |
| trabajos_guardados         | usuario_id                       | uuid                     | NO            | SI (PK)           |
| trabajos_guardados         | trabajo_id                       | uuid                     | NO            | SI (PK)           |
| trabajos_guardados         | created_at                       | timestamp with time zone | YES           |                   |
| wallet_transactions        | id                               | uuid                     | NO            | SI (PK)           |
| wallet_transactions        | wallet_id                        | uuid                     | NO            |                   |
| wallet_transactions        | monto                            | numeric                  | NO            |                   |
| wallet_transactions        | tipo_operacion                   | USER-DEFINED             | NO            |                   |
| wallet_transactions        | estado                           | USER-DEFINED             | NO            |                   |
| wallet_transactions        | llave_idempotencia               | character varying        | NO            |                   |
| wallet_transactions        | referencia_trabajo_id            | uuid                     | YES           |                   |
| wallet_transactions        | metadata                         | jsonb                    | NO            |                   |
| wallet_transactions        | created_at                       | timestamp with time zone | NO            |                   |
| wallet_transactions        | updated_at                       | timestamp with time zone | NO            |                   |
| wallet_transactions        | liquidado_admin                  | boolean                  | NO            |                   |
| wallets                    | id                               | uuid                     | NO            | SI (PK)           |
| wallets                    | usuario_id                       | uuid                     | YES           |                   |
| wallets                    | tipo_wallet                      | USER-DEFINED             | NO            |                   |
| wallets                    | saldo                            | numeric                  | NO            |                   |
| wallets                    | created_at                       | timestamp with time zone | NO            |                   |
| wallets                    | updated_at                       | timestamp with time zone | NO            |                   |