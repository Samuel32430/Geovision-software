# INFORME TÉCNICO DE ARQUITECTURA E IMPLEMENTACIÓN FULLSTACK: 7 CASOS DE USO - ITERACIÓN 2 - SISTEMA ÓPTICA GEOVISION

**Fecha de Emisión:** Noviembre 2026  
**Proyecto:** Sistema de Gestión Comercial y Clínica Oftalmológica - GeoVision  
**Tecnologías:** Java 17, Spring Boot 3, Oracle 19c, Angular 17+, TypeScript, Draw.io, UML / RUP  
**Autor:** Antigravity AI Assistant & Equipo de Desarrollo GeoVision  

---

## 1. RESUMEN EJECUTIVO

El presente informe técnico detalla el estado integral de análisis, diseño arquitectónico e implementación funcional de los **7 Casos de Uso centrales de la Iteración 2** del sistema **GeoVision**, abarcando de forma exhaustiva los módulos de **Ventas** (3 casos de uso) y **Elaboración de Orden de Trabajo - BUC03** (4 casos de uso).

### Objetivo de la Iteración 2
El objetivo principal de la Iteración 2 es **completar y articular el ciclo comercial, financiero y de manufactura de la óptica**, enlazando la atención clínica consolidada en la Iteración 1 con:
1. **La gestión unificada de ventas y cobranza (Módulo de Ventas):** Permitir el registro integral de ventas de mostrador (productos y servicios directos al 100%) y ventas bajo receta médica oftálmica, validando la regla de anticipo mínimo del 25% (`RN-VE07`), la fecha estimada de entrega (`RN-VE08`), el descuento transaccional de stock con auditoría en kardex (`MOVIMIENTO_STOCK_LOG`) y la emisión de comprobantes internos correlativos (Boleta/Factura). Asimismo, permite la administración de cuentas por cobrar para amortizar o liquidar saldos deudores (`CUS07`) y la consulta auditada del historial comercial con filtros avanzados (`CUS08`).
2. **La manufactura, control técnico y entrega en taller (Módulo BUC03):** Automatizar el flujo de confección de lentes graduados mediante la generación de la hoja de ruta técnica (`ORDEN_TRABAJO`), controlando el despacho y retorno hacia laboratorios ópticos externos (`CU09`), la verificación obligatoria de calidad por lensometría computarizada frente a tolerancias paramétricas institucionales (`CU10`), la notificación directa al paciente vía WhatsApp (`CU11`) y la entrega física en mostrador bajo la regla inviolable de **saldo cero** (`CU12`), impidiendo la salida del lente si existe deuda pendiente en caja.

El desarrollo ha seguido una metodología formal orientada a objetos basada en **RUP (Rational Unified Process)**, con arquitectura en capas en el Backend (**Spring Boot 3 REST** con persistencia en **Oracle 19c**) junto a un Frontend desacoplado en **Angular 17+** con componentes independientes (*standalone components*), servicios reactivos RxJS y control de acceso basado en roles (**RBAC**).

Asimismo, se acompaña la entrega de los modelos visuales en formato **Draw.io**, incluyendo los Diagramas de Secuencia, Diagramas de Clases de Análisis (BCE), Diagramas de Clases de Diseño Técnico y el Modelo Entidad-Relación en Oracle 19c.

> **Apertura a Cambios y Extensibilidad (+3 Casos de Uso):**  
> El informe y la arquitectura del sistema quedan explícitamente estructurados sobre estos **7 casos de uso base**, manteniendo total flexibilidad para incorporar los **3 casos de uso adicionales** que el equipo determine para completar el alcance final de la iteración.

---

## 2. MATRIZ DE CASOS DE USO IMPLEMENTADOS (ITERACIÓN 2)

| Código | Módulo | Caso de Uso | Actor Principal | Backend (Spring Boot) | Frontend (Angular) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **CUS06** | Ventas | Registrar Venta | Vendedor / Cajero | `VentaController` | `nueva-venta.ts` |
| **CUS07** | Ventas | Revisar Pago Pendiente | Vendedor / Cajero | `PagoPendienteController` | `pagos-pendientes.ts` |
| **CUS08** | Ventas | Consultar Historial Ventas | Vendedor / Administrador | `VentaHistorialController` | `venta-historial.ts` |
| **CU09** | Elaboración de Orden de Trabajo | Elaboración de Orden de Trabajo (Generación, Envío y Recepción) | Técnico de Taller / Vendedor | `OrdenTrabajoController` | `orden-lista.ts` / `orden-detalle.ts` |
| **CU10** | Elaboración de Orden de Trabajo | Control de Calidad (Lensometría) | Encargado de Calidad / Optómetra | `ControlCalidadController` | `orden-detalle.ts` |
| **CU11** | Elaboración de Orden de Trabajo | Notificación al Paciente | Técnico de Taller / Vendedor | `NotificacionOrdenController` | `orden-detalle.ts` |
| **CU12** | Elaboración de Orden de Trabajo | Entrega de Pedido | Vendedor / Entregador | `OrdenTrabajoController` | `orden-detalle.ts` |

---

## 3. DETALLE DE IMPLEMENTACIÓN CASO POR CASO

### 3.1. CUS06 - REGISTRAR VENTA
* **Objetivo:** Registrar de forma unificada una transacción comercial en la óptica, combinando en una sola operación la venta de productos de catálogo, servicios profesionales o lentes con receta médica oftálmica, calculando importes, procesando pagos completos o anticipos (efectivo, tarjeta con POS o código QR dinámico), descontando existencias en inventario y generando el comprobante interno de venta.
* **Actor Principal:** Vendedor.
* **Implementación Backend:**
  * **Controlador REST:** `VentaController.java` (`POST /api/v1/ventas`). Endpoint auxiliar de consulta: `GET /api/v1/ventas/{id}`.
  * **Servicio:** `VentaServiceImpl.java` -> Método transaccional `@Transactional(rollbackFor = Exception.class) registrarVenta(VentaRegistroRequestDTO)`.
  * **Validaciones y Reglas de Negocio:**
    * *RN-VE01:* Permite la venta combinada de productos físicos, cristales oftálmicos configurados y servicios profesionales en la misma orden.
    * *RN-VE02 / RN-VE03:* Toda venta que involucre confección de lentes debe asociarse obligatoriamente a un paciente y a una receta médica válida perteneciente a dicho paciente.
    * *RN-VE05:* Bloqueo pesimista de stock (`productoRepository.findByIdForUpdate`) validando que la existencia física sea suficiente (`stock >= cantidad solicitada`).
    * *RN-VE06:* En ventas de productos sin receta o servicios directos, el cobro inicial debe ser por el 100% del total.
    * *RN-VE07:* En ventas con receta médica, se permite registrar un adelanto inicial no menor al 25% del total de la orden.
    * *RN-VE08:* Si la venta registra un adelanto parcial, es obligatorio consignar la fecha estimada de entrega del trabajo de óptica.
    * *RN-VE09:* Las ventas con saldo deudor se registran automáticamente en estado `PENDIENTE`.
    * *RN-VE12:* En cobros realizados con tarjeta (débito/crédito) o transferencia, es obligatorio registrar el número de operación o voucher emitido por el terminal bancario.
    * *RN-VE13:* Cada monto de pago debe ser mayor a cero y la sumatoria no puede exceder el total de la venta.
  * **Persistencia y Base de Datos (Oracle 19c):**
    * Inserción en la tabla cabecera `VENTA`.
    * Generación de comprobante correlativo en `COMPROBANTE_PAGO` con numeración secuencial (`FN_GENERAR_CORRELATIVO_COMPROBANTE`).
    * Inserción de líneas de detalle en `PRODUCTO_VENDIDO` y `SERVICIO_VENDIDO`.
    * Inserción del registro de cobro en `PAGO`.
    * Descuento de stock en `PRODUCTO` y registro de auditoría en `MOVIMIENTO_STOCK_LOG` con motivo `VENTA`.
* **Implementación Frontend:**
  * **Componentes:** `nueva-venta.ts` / `nueva-venta.html`.
  * **Modales de Apoyo:** `receta-asociada-modal.ts` (asociación de receta oftálmica), `qr-pago-modal.ts` (soporte de cobro digital QR), `venta-exitosa-modal.ts` (constancia de comprobante generado).
  * **Lógica UI:** Carrito reactivo con cálculo automático de totales, desglose de IGV, validación de anticipo mínimo en tiempo real y habilitación condicional del campo de fecha de entrega.
  * **Servicio:** `venta.service.ts` que consume el endpoint REST mediante `HttpClient`.
* **Modelado UML:**
  * **Secuencia:** Vendedor selecciona cliente, productos y receta -> GUI envía `POST /api/v1/ventas` -> `VentaController` delega a `VentaService` -> Bloqueo pesimista de productos y receta -> Inserción atómica en VENTA, COMPROBANTE, DETALLES y PAGO -> Actualización de stock y kardex -> Retorno de `VentaResponseDTO`.
  * **Análisis (BCE):** Vendedor -> Boundary: `NuevaVentaGUI` -> Control: `ControladorVenta` -> Entities: `Venta`, `DetalleVenta`, `Pago`, `Producto`, `Kardex`.
  * **Diseño:** Clase formal `VentaController` con método `registrarVenta(@Valid @RequestBody VentaRegistroRequestDTO)` y mapeo desacoplado con `VentaMapper`.

---

### 3.2. CUS07 - REVISAR PAGO PENDIENTE
* **Objetivo:** Permitir al vendedor o cajero buscar y listar las ventas que quedaron con saldo adeudado tras un anticipo inicial, revisar el balance de pagos acumulados y registrar el cobro final o abonos para liquidar la deuda, actualizando el estado de la venta a cancelada (`PAGADA`).
* **Actor Principal:** Vendedor.
* **Implementación Backend:**
  * **Controlador REST:** `PagoPendienteController.java` (`GET /api/v1/ventas/pagos-pendientes`, `GET /api/v1/ventas/pagos-pendientes/{idVenta}`, `POST /api/v1/ventas/pagos-pendientes`).
  * **Servicio:** `PagoPendienteServiceImpl.java` -> Métodos `listarVentasConPagosPendientes(termino)`, `obtenerSaldoPendientePorVenta(idVenta)` y `registrarPagoPendiente(PagoRegistroRequestDTO)`.
  * **Validaciones y Reglas de Negocio:**
    * *RN-VE10:* El caso de uso aplica exclusivamente a ventas que registren saldo pendiente (`estado == PENDIENTE`).
    * *RN-VE13:* El monto a cobrar no puede ser negativo, ni cero, ni exceder el saldo restante actual de la venta (`monto <= saldoPendiente`).
    * *RN-VE14:* Una vez cancelado el 100% del saldo, la venta cambia su estado financiero a `PAGADA` y no admite nuevos registros de cobro.
    * Bloqueo concurrente sobre la venta mediante `ventaRepository.findByIdForUpdate(idVenta)` para garantizar integridad en cobros simultáneos.
  * **Persistencia y Base de Datos (Oracle 19c):**
    * Consulta optimizada mediante la vista `VW_VENTAS_SALDOS_PENDIENTES` y la función `FN_CALCULAR_SALDO_VENTA`.
    * Inserción de la transacción en la tabla `PAGO`.
    * Actualización del estado en `VENTA` respaldado por el trigger `TRG_ACTUALIZAR_ESTADO_VENTA_PAGO` y procedimiento `SP_REGISTRAR_PAGO_PENDIENTE`.
* **Implementación Frontend:**
  * **Componentes:** `pagos-pendientes.ts` / `pagos-pendientes.html`.
  * **Modal:** `registrar-abono-modal.ts` para capturar el importe de abono, método de pago y número de voucher bancario.
  * **Lógica UI:** Grilla interactiva con búsqueda en tiempo real por DNI, paciente o comprobante, badges visuales con el saldo pendiente y botón de liquidación rápida.
  * **Servicio:** `pago-pendiente.service.ts`.
* **Modelado UML:**
  * **Secuencia:** Vendedor busca venta deudora -> GUI muestra saldo pendiente -> Vendedor abre modal y registra pago -> `PagoPendienteController` valida montos -> Inserta PAGO -> Si saldo es cero, actualiza VENTA a PAGADA -> Refresca bandeja.
  * **Análisis (BCE):** Vendedor -> Boundary: `PagosPendientesGUI` -> Control: `ControladorPagoPendiente` -> Entities: `Venta`, `Pago`.
  * **Diseño:** Clase formal `PagoPendienteController` con método `registrarPagoPendiente(@Valid @RequestBody PagoRegistroRequestDTO)`.

---

### 3.3. CUS08 - CONSULTAR HISTORIAL VENTAS
* **Objetivo:** Permitir al personal comercial y administrativo consultar, auditar y hacer seguimiento de las operaciones de venta registradas internamente en el sistema, visualizando el estado general, comprobantes emitidos y el detalle exhaustivo de productos, servicios, pagos y recetas asociadas.
* **Actor Principal:** Vendedor / Administrador.
* **Implementación Backend:**
  * **Controlador REST:** `VentaHistorialController.java` (`GET /api/v1/ventas/historial`, `GET /api/v1/ventas/historial/{idVenta}/detalle`).
  * **Servicio:** `VentaHistorialServiceImpl.java` -> Métodos `buscarHistorialVentas(...)` y `obtenerDetalleModalVenta(idVenta)`.
  * **Criterios de Búsqueda y Filtros:**
    * Búsqueda por término (DNI o nombre de paciente, número de comprobante).
    * Filtro por estado de venta (`PAGADA`, `PENDIENTE`, `ANULADA`).
    * Filtro cronológico por rango de fechas (`fechaInicio` y `fechaFin`).
    * Paginación y ordenamiento mediante `Pageable` de Spring Data.
  * **Reglas:** *RN-VE15:* La consulta del historial tiene carácter estrictamente informativo y no permite alterar importes ni transacciones ya consolidadas.
* **Implementación Frontend:**
  * **Componentes:** `venta-historial.ts` / `venta-historial.html`.
  * **Modal:** `venta-detalle-modal.ts` con desglose de ítems facturados, montos unitarios, auditoría de abonos y receta óptica.
  * **Lógica UI:** Barra de filtros con debounce reactivo, badges semánticos de estado comercial y modal con vista imprimible.
  * **Servicio:** `venta.service.ts`.
* **Modelado UML:**
  * **Secuencia:** Usuario aplica filtros en la tabla de historial -> Backend ejecuta consulta paginada sobre `VENTA` -> Usuario hace clic en "Ver Detalle" -> Invoca `/api/v1/ventas/historial/{id}/detalle` y renderiza el modal.
  * **Análisis (BCE):** Usuario -> Boundary: `VentaHistorialGUI` -> Control: `ControladorVentaHistorial` -> Entities: `Venta`, `ComprobantePago`.

---

### 3.4. CU09 - ELABORACIÓN DE ORDEN DE TRABAJO (GENERACIÓN, ENVÍO Y RECEPCIÓN)
* **Objetivo:** Gestionar el ciclo de manufactura del lente óptico desde su creación técnica a partir de una venta con receta confirmada, controlando el despacho físico hacia el laboratorio óptico externo seleccionado y la recepción formal del producto terminado en la clínica.
* **Actor Principal:** Técnico de Taller / Vendedor.
* **Implementación Backend:**
  * **Controlador REST:** `OrdenTrabajoController.java`:
    * `GET /api/v1/ordenes-trabajo/ventas-pendientes` (ventas con lentes sin OT).
    * `POST /api/v1/ordenes-trabajo` (generación de la OT).
    * `GET /api/v1/ordenes-trabajo` (listado con filtros y paginación).
    * `GET /api/v1/ordenes-trabajo/{id}` (detalle de la orden).
    * `GET /api/v1/ordenes-trabajo/laboratorios` (catálogo de laboratorios externos).
    * `POST /api/v1/ordenes-trabajo/envios` (salida a laboratorio externo).
    * `PUT /api/v1/ordenes-trabajo/envios/{idEnvio}/recepcion` (retorno del pedido montado).
  * **Servicio:** `OrdenTrabajoServiceImpl.java` -> Métodos `pendientes()`, `generar()`, `listar()`, `obtener()`, `laboratorios()`, `enviar()` y `recibir()`.
  * **Validaciones de Negocio:**
    * *Detección de Pendientes:* Identifica ventas vigentes (`PENDIENTE` o `PAGADA`) asociadas a una receta cuyos lentes aún no posean registro en `ORDEN_TRABAJO`.
    * *Unicidad y Medidas:* Valida que el lente no cuente con una OT previa y que disponga de mediciones clínicas completas (`ComparadorLensometria.validarOriginal`).
    * *Transición de Envío:* Solo se pueden enviar órdenes en estado `PENDIENTE` o `CONTROL_CALIDAD_RECHAZADO` (reenvío por calibración). Pasa a estado `ENVIADO_LABORATORIO`.
    * *Transición de Recepción:* Exige que la orden se encuentre en `ENVIADO_LABORATORIO`. Registra `fechaRecepcion = LocalDateTime.now()` y transiciona la OT a `RECIBIDO_LABORATORIO`.
  * **Persistencia:** Tablas `ORDEN_TRABAJO`, `ENVIO_LABORATORIO`, `LABORATORIO` y bloqueo pesimista en receta y venta (`ventasOrden.bloquear`).
* **Implementación Frontend:**
  * **Componentes:** `orden-lista.ts` (Tab "Ventas Pendientes" y Tab "Órdenes de Trabajo") y `orden-detalle.ts` (sección Envíos y Recepción).
  * **Lógica UI:** Grilla con selector de estado, buscador predictivo de pacientes, modal para selección de laboratorio óptico con fecha estimada, y botón de confirmación de recepción.
  * **Servicio:** `orden-api.ts`.
* **Modelado UML:**
  * **Secuencia:** Técnico consulta ventas pendientes -> Presiona "Generar OT" -> Backend inserta `ORDEN_TRABAJO` (PENDIENTE) -> Técnico registra envío a laboratorio con fecha estimada -> OT pasa a `ENVIADO_LABORATORIO` -> Al arribar paquete, técnico registra recepción -> OT pasa a `RECIBIDO_LABORATORIO`.
  * **Análisis (BCE):** Técnico -> Boundary: `OrdenTrabajoGUI` -> Control: `ControladorOrdenTrabajo` -> Entities: `OrdenTrabajo`, `EnvioLaboratorio`, `Laboratorio`, `Lente`.

---

### 3.5. CU10 - CONTROL DE CALIDAD (LENSOMETRÍA)
* **Objetivo:** Ejecutar la inspección técnica obligatoria de los lentes ópticos recibidos del laboratorio mediante un lensómetro digital, contrastando los valores físicos obtenidos frente a la prescripción médica original y las tolerancias paramétricas institucionales para aprobar el trabajo o rechazarlo para reproceso.
* **Actor Principal:** Encargado de Calidad / Optómetra / Técnico.
* **Implementación Backend:**
  * **Controlador REST:** `ControlCalidadController.java` (`GET /api/v1/control-calidad/pendientes`, `GET /api/v1/control-calidad/politica`, `POST /api/v1/control-calidad`).
  * **Servicio:** `ControlCalidadServiceImpl.java` -> Métodos `pendientes(pageable)`, `politica()` y `registrar(ControlCalidadRequestDTO, usuario)`.
  * **Reglas de Calidad y Tolerancias:**
    * Se utiliza `ComparadorLensometria.java` y `PoliticaCalidad.java` para evaluar las diferencias absolutas entre las medidas de la receta clínica y las medidas tomadas en el taller.
    * Valida margen de desviación de **Esfera** y **Cilindro** (dioptrías), **Eje** (grados angulares), **Distancia Pupilar (DP)** y **Prisma** para ambos ojos (OD y OI).
    * *Preservación Clínica:* Las medidas tomadas en el lensómetro se persisten en la tabla `MEDIDA` asociadas a `id_envio_laboratorio`, asegurando que la receta médica original del paciente jamás sea sobrescrita.
    * *Resolución de Estados:* Si la lensometría cumple con las tolerancias, `aprobado = 1` y la orden transiciona a `LISTO_ENTREGA`. Si excede las tolerancias, `aprobado = 0` y la orden transiciona a `CONTROL_CALIDAD_RECHAZADO`, habilitando un nuevo envío a laboratorio.
* **Implementación Frontend:**
  * **Componentes:** `orden-detalle.ts` (Panel de Control de Calidad).
  * **Lógica UI:** Formulario simétrico y ergonómico para captura de mediciones OD y OI con precarga de las tolerancias configuradas en la política de calidad y dictamen visual de resultado.
  * **Servicio:** `orden-api.ts` -> `politica()` y `controlar()`.
* **Modelado UML:**
  * **Secuencia:** Operador captura medidas de lensometría en GUI -> `POST /api/v1/control-calidad` -> `ControlCalidadService` compara contra la receta -> Inserta medidas de control de taller en `MEDIDA` -> Actualiza `ENVIO_LABORATORIO` con resultado -> Actualiza OT a `LISTO_ENTREGA` o `CONTROL_CALIDAD_RECHAZADO`.
  * **Análisis (BCE):** Encargado Calidad -> Boundary: `ControlCalidadGUI` -> Control: `ControladorControlCalidad` -> Entities: `EnvioLaboratorio`, `Medida`, `PoliticaCalidad`.

---

### 3.6. CU11 - NOTIFICACIÓN AL PACIENTE
* **Objetivo:** Notificar de manera inmediata al paciente que sus lentes graduados han superado satisfactoriamente el control de calidad técnico y se encuentran listos para ser recogidos en la clínica, utilizando integración directa con la API de WhatsApp Web.
* **Actor Principal:** Técnico de Taller / Vendedor.
* **Implementación Backend:**
  * **Controlador REST:** `NotificacionOrdenController.java` (`GET /api/v1/ordenes-trabajo/{idOrden}/notificaciones`, `POST .../whatsapp`, `POST .../whatsapp/confirmar`, `POST .../sms`).
  * **Servicio:** `NotificacionOrdenServiceImpl.java` -> Métodos `consultarEstado()`, `prepararWhatsApp()`, `confirmarWhatsApp()`, `enviarSms()`.
  * **Reglas de Comunicación:**
    * La orden debe encontrarse en estado `LISTO_ENTREGA`.
    * Se verifica que el paciente cuente con número telefónico válido (9 dígitos).
    * Construcción de enlace seguro normalizado: `https://wa.me/{telefono}?text={mensaje_url_encoded}` con mensaje institucional personalizado.
    * Registro de auditoría: al confirmarse el envío, se actualiza el campo `ORDEN_TRABAJO.FECHA_NOTIFICACION` con la fecha y hora exacta del contacto.
* **Implementación Frontend:**
  * **Componentes:** `orden-detalle.ts` (Sección de Notificación al Paciente).
  * **Lógica UI:** Tarjeta informativa que visualiza si el paciente ya fue notificado. Proporciona el botón "Notificar por WhatsApp", que abre la conversación en WhatsApp Web/Móvil y solicita la confirmación de la entrega del mensaje.
  * **Servicio:** `orden-api.ts` -> `whatsapp()`.
* **Modelado UML:**
  * **Secuencia:** Operador pulsa "Notificar por WhatsApp" -> Backend genera URL wa.me normalizada -> Frontend abre pestaña en navegador -> Operador pulsa confirmar -> Backend sella `FECHA_NOTIFICACION` en la base de datos.
  * **Análisis (BCE):** Operador -> Boundary: `NotificacionGUI` -> Control: `ControladorNotificacion` -> Entities: `OrdenTrabajo`, `Paciente`.

---

### 3.7. CU12 - ENTREGA DE PEDIDO
* **Objetivo:** Registrar formalmente la entrega física de los lentes ópticos terminados al paciente en ventanilla, aplicando una regla de negocio de cierre financiero estricta que exige que la orden tenga control de calidad aprobado y que la venta no registre ningún saldo deudor (regla de saldo pendiente igual a S/ 0.00).
* **Actor Principal:** Vendedor / Entregador.
* **Implementación Backend:**
  * **Controlador REST:** `OrdenTrabajoController.java` (`POST /api/v1/ordenes-trabajo/entrega`).
  * **Servicio:** `OrdenTrabajoServiceImpl.java` -> Método transaccional `entregar(EntregaPedidoRequestDTO, usuario)`.
  * **Validaciones de Cierre Inviolables:**
    * La orden debe encontrarse en estado `LISTO_ENTREGA` y no haber sido entregada previamente (`fechaEntrega == null`).
    * El último envío debe contar con control de calidad aprobado (`aprobado == 1`) y medidas de lensometría persistidas.
    * **Validación de Saldo Cero:** Se calcula dinámicamente el saldo de la venta vinculada (`venta.total - SUM(pagos)`). Si el saldo es mayor a cero (`saldo > 0`), el sistema aborta la operación y lanza:  
      `ReglaNegocioException("No se puede entregar: el saldo pendiente debe ser exactamente cero. Saldo: " + saldo)`.
    * Si el saldo es igual a 0.00, se autoriza la entrega, la orden pasa a estado `ENTREGADO`, se registra `FECHA_ENTREGA = LocalDateTime.now()` y se consigna el usuario responsable de la entrega en `DESCRIPCION`.
* **Implementación Frontend:**
  * **Componentes:** `orden-detalle.ts` (Sección Entrega de Pedido).
  * **Lógica UI:** Semáforo financiero visual: si la venta registra saldo deudor, se muestra una alerta indicando que el paciente debe liquidar primero su cuenta en Caja y se bloquea el botón de entrega. Si el saldo es S/ 0.00, se habilita el botón de entrega física.
  * **Servicio:** `orden-api.ts` -> `entregar()`.
* **Modelado UML:**
  * **Secuencia:** Vendedor solicita entrega -> `OrdenTrabajoController` delega a `OrdenTrabajoService` -> Bloqueo concurrente de venta y orden -> Verificación de calidad aprobada y saldo == 0 -> Si existe deuda, rechaza entrega -> Si saldo == 0, sella fecha de entrega y estado `ENTREGADO`.
  * **Análisis (BCE):** Vendedor -> Boundary: `EntregaPedidoGUI` -> Control: `ControladorOrdenTrabajo` -> Entities: `OrdenTrabajo`, `Venta`, `Pago`.

---

## 4. ADAPTABILIDAD Y ALCANCE PREVISTO (+3 CASOS DE USO)

El informe técnico y la arquitectura del sistema han sido diseñados de forma modular sobre estos **7 Casos de Uso centrales**, dejando el terreno preparado para que el equipo pueda definir e incorporar hasta **3 casos de uso adicionales** en etapas posteriores según las necesidades del proyecto o los requerimientos de evaluación.

---

## 5. CONCLUSIONES

1. **Coherencia y Fidelidad Técnica:** Cada uno de los 7 Casos de Uso modelados en RUP refleja con total exactitud las clases `@RestController`, `@Service`, `@Repository` de Spring Boot 3, los componentes standalone de Angular 17+ y las tablas relacionales de Oracle 19c (`VENTA`, `DETALLE_VENTA`, `PAGO`, `COMPROBANTE_PAGO`, `MOVIMIENTO_STOCK_LOG`, `ORDEN_TRABAJO`, `ENVIO_LABORATORIO`).
2. **Integración Total entre Clínica, Caja y Taller:** La Iteración 2 cierra con éxito el ciclo operativo de la óptica: la prescripción médica generada en la Iteración 1 se factura bajo reglas financieras estrictas en el módulo de Ventas (anticipos y control de saldos) y se transforma en una orden de trabajo trazable hasta la entrega física del producto al paciente.
3. **Mecanismos de Control y Seguridad Inviolables:** Se garantizan dos compuertas de seguridad críticas: la imposibilidad de marcar un lente como listo sin un control de lensometría que cumpla con la política de calidad, y el bloqueo estricto de la entrega del pedido si el paciente registra cualquier saldo pendiente de pago.
