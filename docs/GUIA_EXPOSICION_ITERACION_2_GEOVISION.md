# GUÍA DEL EXPOSITOR: SUSTENTACIÓN ITERACIÓN 2 — GEOVISION
## Análisis y Diseño de Sistemas de Información (RUP / UML)

**Proyecto:** GeoVision — Sistema de Gestión Comercial, Clínica Oftalmológica y Manufactura Óptica  
**Institución:** Universidad Peruana Unión (UPeU) — E.P. Ingeniería de Sistemas  
**Alcance:** Iteración 2 — 7 Casos de Uso del Sistema (CUS05, CUS06, CUS08, CUS09, CUS12, CUS13, CUS19)  

---

### Diapositiva 1: Portada
* **Tiempo sugerido:** 1 minuto
* **Objetivo:** Introducir el proyecto y situar el marco académico y profesional.
* **Guion del expositor:**
  > "Buenas tardes, profesor(a) y miembros del jurado. Hoy presentamos el desarrollo de la **Iteración 2** del sistema **GeoVision**, una plataforma integral orientada a la gestión comercial, clínica oftalmológica y manufactura óptica. Nuestra exposición está rigurosamente enfocada en la disciplina del **Análisis y Diseño de Sistemas**, demostrando cómo hemos aplicado la metodología RUP y el estándar UML 2.5 para modelar y resolver de raíz los problemas operativos y de negocio en una óptica moderna."

---

### Diapositiva 2: Contexto Empresarial y Problemática del Negocio
* **Tiempo sugerido:** 2 minutos
* **Objetivo:** Demostrar conocimiento profundo del dominio del negocio y justificar la necesidad del software.
* **Guion del expositor:**
  > "En el sector óptico peruano existe una problemática crítica: la desconexión total entre las áreas de almacén, caja y taller. En muchas ópticas, las ventas se anotan en talonarios o planillas aisladas, lo que origina tres dolores graves:
  > 1. **Fugas financieras:** Se entregan anteojos a pacientes que aún mantienen saldos deudores tras pagar un anticipo.
  > 2. **Riesgos clínicos:** No existe un control de calidad objetivo que verifique con lensometría si el cristal graduado cumple exactamente la receta médica.
  > 3. **Quiebres de stock y parálisis:** Desconocimiento de existencias reales de monturas y lunas, y demoras críticas cuando los usuarios olvidan sus credenciales de acceso."

---

### Diapositiva 3: Justificación y Objetivo de la Iteración 2
* **Tiempo sugerido:** 2 minutos
* **Objetivo:** Justificar con criterio de ingeniería de software la selección de los 7 casos de uso.
* **Guion del expositor:**
  > "¿Por qué seleccionamos exactamente estos 7 casos de uso para la Iteración 2? Porque conforman un **circuito cerrado autosostenible**:
  > - **Abastecimiento (CUS12 y CUS13):** Sin catálogo de productos ni recepción física con kardex, no hay inventario disponible.
  > - **Ventas y Finanzas (CUS05 y CUS06):** Procesamos la venta con receta, cobramos el anticipo reglamentario del 25% y amortizamos la deuda hasta el saldo cero.
  > - **Taller y Calidad (CUS08 y CUS09):** Trasladamos la prescripción a una orden de trabajo y la sometemos a calibración por lensometría computarizada.
  > - **Seguridad y Continuidad (CUS19):** Brindamos autoservicio seguro para que ningún colaborador quede bloqueado operativamente por olvido de contraseña."

---

### Diapositiva 4: Metodología de Desarrollo: RUP y Modelado UML 2.5
* **Tiempo sugerido:** 1.5 minutos
* **Objetivo:** Explicar el marco metodológico sin caer en detalles de código.
* **Guion del expositor:**
  > "Hemos adoptado el Proceso Unificado Racional (RUP), ubicándonos en la fase de Elaboración avanzada y Construcción. RUP se caracteriza por ser guiado por casos de uso, centrado en la arquitectura, e iterativo e incremental. Utilizamos UML 2.5 no como un simple dibujo documental, sino como una herramienta de especificación rigurosa que garantiza trazabilidad bidireccional entre la necesidad del cliente y el diseño técnico del sistema."

---

### Diapositiva 5: Modelo del Negocio: Alcance de los 7 Casos de Uso
* **Tiempo sugerido:** 2 minutos
* **Objetivo:** Detallar el alcance funcional por áreas del negocio.
* **Guion del expositor:**
  > "Estructuralmente, la Iteración 2 abarca 4 macroprocesos:
  > 1. **Módulo de Catálogo e Inventario:** `CUS12` gestiona monturas, cristales y tratamientos con atributos técnicos; `CUS13` realiza el ingreso de stock al almacén actualizando el kardex en tiempo real.
  > 2. **Módulo Comercial:** `CUS05` procesa ventas de mostrador y ventas complejas bajo receta; `CUS06` permite al cajero buscar ventas pendientes de cobro y registrar pagos o cancelaciones.
  > 3. **Módulo de Taller Óptico:** `CUS08` emite la orden de trabajo para manufactura y despacho a laboratorio; `CUS09` registra el control de calidad por lensometría.
  > 4. **Módulo de Seguridad:** `CUS19` permite al usuario restablecer su clave mediante un mecanismo de token seguro."

---

### Diapositiva 6: Políticas y Reglas de Negocio Críticas
* **Tiempo sugerido:** 2 minutos
* **Objetivo:** Mostrar cómo las políticas de la empresa están protegidas por el diseño del software.
* **Guion del expositor:**
  > "El corazón del análisis reside en las reglas de negocio, diseñadas para ser inviolables:
  > - `RN-VE07`: En ventas con receta médica es obligatorio un anticipo mínimo del 25% del total.
  > - `RN-VE08`: Si queda saldo pendiente, es obligatorio consignar la fecha estimada de entrega.
  > - `RN-VE14`: La venta solo pasa a estado `PAGADA` cuando el saldo deudor es exactamente cero.
  > - `RN-OT01 y RN-OT02`: La orden de trabajo exige receta válida y medidas completas; el control de calidad contrasta las medidas del lensómetro contra las tolerancias institucionales sin sobrescribir la receta clínica original.
  > - `RN-INV01`: Cada transacción descuenta inventario físico de forma atómica y deja traza en el log de kardex.
  > - `RN-SEG01`: Los tokens de recuperación expiran en un plazo determinado y son de un solo uso."

---

### Diapositiva 7: Análisis del Sistema: Clases de Análisis (Patrón BCE)
* **Tiempo sugerido:** 2 minutos
* **Objetivo:** Demostrar dominio del patrón Boundary-Control-Entity.
* **Guion del expositor:**
  > "Aplicando el patrón BCE de RUP, desacoplamos la interfaz, la lógica y los datos:
  > - Las clases **Boundary** encapsulan los formularios y pantallas (`VentaGUI`, `PagosPendientesGUI`, `OrdenTrabajoGUI`, `LensometriaGUI`, `CatalogoGUI`, `StockGUI`, `RecuperarPasswordGUI`).
  > - Las clases de **Control** orquestan los flujos de negocio sin atarse a tecnologías visuales (`ControladorVenta`, `ControladorCobranza`, `ControladorOT`, etc.).
  > - Las clases de **Entidad** representan la información medular del dominio (`Venta`, `Pago`, `OrdenTrabajo`, `MedidaCalidad`, `Producto`, `Kardex`, `Usuario`)."

---

### Diapositiva 8: Dinámica del Sistema: Diagramas de Secuencia Clave
* **Tiempo sugerido:** 2 minutos
* **Objetivo:** Explicar cómo interactúan los objetos a lo largo del tiempo.
* **Guion del expositor:**
  > "Los diagramas de secuencia modelan la dinámica transaccional:
  > - En la **Venta**, el Vendedor interactúa con el Boundary, el Controlador aplica bloqueos de concurrencia pesimista sobre el stock y la receta, y coordina la persistencia atómica de la cabecera, los ítems y el comprobante.
  > - En el **Control de Calidad**, el operador ingresa los valores del lensómetro digital; el sistema evalúa la desviación diótrica contra las tolerancias permitidas y determina de forma automática si la orden se aprueba o se envía a reproceso en laboratorio."

---

### Diapositiva 9: Diseño de Arquitectura de Software: Fullstack Desacoplado
* **Tiempo sugerido:** 1.5 minutos
* **Objetivo:** Explicar la arquitectura sin entrar en sintaxis de programación.
* **Guion del expositor:**
  > "Diseñamos una arquitectura Cliente-Servidor Desacoplada:
  > - Un **Frontend SPA (Single Page Application)** en Angular 17+ basado en componentes independientes, que gestiona el estado reactivo con RxJS y garantiza una experiencia de usuario ágil.
  > - Un **Backend RESTful Stateless** en Spring Boot 3 estructurado en capas estrictas: controladores de API, capa transaccional de servicios de negocio y repositorios de persistencia.
  > - Seguridad transversal perimetral con tokens criptográficos JWT y autorización basada en roles (RBAC)."

---

### Diapositiva 10: Diseño de Persistencia y Base de Datos en Oracle 19c
* **Tiempo sugerido:** 2 minutos
* **Objetivo:** Resaltar la robustez del modelo de datos empresarial.
* **Guion del expositor:**
  > "Para la persistencia seleccionamos un motor empresarial de primer nivel: **Oracle Database 19c**.
  > - El modelo relacional consta de 35 tablas normalizadas que garantizan integridad referencial absoluta.
  > - Implementamos lógica reactiva en el motor mediante **Triggers** para la actualización de saldos y descuento de existencias, junto con **Procedimientos Almacenados y Funciones PL/SQL** para operaciones transaccionales críticas.
  > - Aplicamos vistas analíticas para consultar saldos pendientes e índices B-Tree en todas las claves foráneas para impedir bloqueos concurrentes."

---

### Diapositiva 11: Evaluación de la Iteración 2, Conclusiones y Logros
* **Tiempo sugerido:** 1.5 minutos
* **Objetivo:** Cerrar con firmeza demostrando el cumplimiento de metas y valor entregado.
* **Guion del expositor:**
  > "En conclusión, la Iteración 2 ha cumplido al 100% sus objetivos de ingeniería:
  > 1. Articulamos el ciclo completo de la óptica: desde el ingreso al almacén hasta el control de calidad en taller.
  > 2. Eliminamos las fugas de dinero mediante el control estricto de anticipos y liquidaciones de saldo.
  > 3. Aseguramos la salud visual del paciente mediante calibración objetiva de tolerancias diótricas.
  > 4. Establecemos una base arquitectónica sólida y extensible, lista para la incorporación de reportes analíticos e inteligencia de negocios.
  > Muchas gracias. Quedamos atentos a sus preguntas."
