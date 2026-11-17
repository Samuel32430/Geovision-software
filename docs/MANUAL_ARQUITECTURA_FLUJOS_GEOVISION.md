# ARQUITECTURA TÉCNICA INTEGRAL Y FLUJO FULLSTACK: SISTEMA ÓPTICA GEOVISION
## Módulos de Atención al Paciente en Consulta y Seguridad / Control de Acceso (RBAC)

---

## 1. INTRODUCCIÓN Y FICHA TÉCNICA DEL SISTEMA

### 1.1. Resumen Ejecutivo
El sistema **GeoVision** es una plataforma empresarial orientada al sector oftálmico y de venta óptica. Su propósito es digitalizar, centralizar y optimizar dos macroprocesos críticos:
1. **La Atención al Paciente en Consulta Oftalmológica / Optometría:** Abarca desde la filiación del paciente, consulta de su expediente clínico y antecedentes refractivos, registro del examen visual (mediciones de Ojo Derecho y Ojo Izquierdo con control dioptrico estricto), hasta la configuración técnica y física de lentes (material del cristal, tratamientos de protección visual y monturas) con emisión y exportación de la receta médica en formato PDF.
2. **La Seguridad, Autenticación y Control de Acceso Basado en Roles (RBAC):** Garantiza la confidencialidad, integridad y trazabilidad mediante autenticación sin estado (Stateless) con tokens criptográficos JWT (HMAC-SHA256), autorización multinivel en Backend y Frontend, gestión de cuentas de usuario, asignación matricial de roles y permisos unitarios por módulo, auditoría de accesos y recuperación asistida de credenciales por correo electrónico.

### 1.2. Ficha Técnica Tecnológica

| Componente | Tecnología / Estándar | Versión / Detalle | Responsabilidad Principal |
| :--- | :--- | :--- | :--- |
| **Frontend** | Angular | 17+ (Standalone Components) | Interfaz reactiva SPA, control de navegación, gestión de estado con Signals y RxJS. |
| **Lenguaje Frontend** | TypeScript / HTML5 / CSS3 | 5.x / CSS nativo modular | Tipado estático riguroso en cliente, ergonomía visual y accesibilidad. |
| **Backend** | Spring Boot | 3.x (Java 17 LTS) | Arquitectura RESTful en capas, inyección de dependencias y lógica transaccional. |
| **Seguridad Backend**| Spring Security | 6.x + JJWT (Java JWT) | Filtro de inspección JWT, autenticación en SecurityContext y autorización con `@PreAuthorize`. |
| **Persistencia / ORM**| Spring Data JPA / Hibernate | 6.x | Mapeo objeto-relacional, consultas JPQL optimizadas y control de concurrencia pesimista. |
| **Mapeo de Datos** | MapStruct | 1.5.x | Conversión segura y de alto rendimiento en tiempo de compilación entre Entidades JPA y DTOs. |
| **Motor de Base de Datos** | Oracle Database | 19c Enterprise | Persistencia relacional, integridad referencial, índices únicos y precisión temporal. |
| **Generación Documental** | Apache PDFBox | 3.x | Construcción programática en memoria y streaming de recetas médicas en PDF. |
| **Metodología y Modelado** | UML 2.5 / RUP / Peter Chen | Draw.io XML | Diagramas de Secuencia temporal, Clases de Análisis (BCE), Clases de Diseño y Modelo Chen. |

---

## 2. ARQUITECTURA GENERAL DEL SISTEMA: DESACOPLAMIENTO Y COMUNICACIÓN

### 2.1. Paradigma Arquitectónico
El sistema implementa una **Arquitectura Desacoplada SPA (Single Page Application) + API RESTful Stateless**:
* **Frontend Autónomo:** Compilado como un paquete de recursos estáticos (HTML, JS, CSS) servidos al navegador. No mantiene estado de sesión en el servidor web.
* **Backend Sin Estado (Stateless):** La sesión del usuario no se aloja en memoria del servidor (`HttpSession` desactivada mediante `SessionCreationPolicy.STATELESS`). Cada petición HTTP entrante es completamente autónoma y debe demostrar su identidad y privilegios adjuntando una firma criptográfica en el encabezado `Authorization: Bearer <token>`.
* **Seguridad Transversal Perimetral:** Tanto el cliente web como la API REST aplican validaciones redundantes de seguridad (Defensa en Profundidad). El frontend adapta la interfaz ocultando o deshabilitando elementos según los permisos del usuario; sin embargo, la seguridad formal reside de forma inexpugnable en el backend mediante filtros de servlet e inspección de autoridades a nivel de método.

### 2.2. Protocolo de Comunicación y Flujo de Intercambio
1. **Canal de Transporte:** Protocolo HTTP/1.1 o HTTP/2 sobre TLS/HTTPS.
2. **Formato de Carga Útil (Payload):** JSON (`application/json;charset=UTF-8`) para peticiones y respuestas, y `application/pdf` para descarga de documentos médicos.
3. **Control de Origen Cruzado (CORS):** Gestionado centralizadamente en `CorsConfig.java` dentro de la cadena de seguridad de Spring. Permite peticiones de orígenes específicos (`http://localhost:4200`, `http://localhost:5173`, etc.), habilita credenciales (`allowCredentials=true`) y responde inmediatamente a las peticiones pre-vuelo `OPTIONS` del navegador sin exigir token de autenticación.
4. **Respuestas de Error Homogéneas:** Todo fallo de negocio o validación devuelve un formato estandarizado JSON procesado por `GlobalExceptionHandler`:
   * `codigo`: Código numérico HTTP.
   * `mensaje`: Descripción clara y sanitizada del error (sin exponer detalles internos de SQL ni trazas de excepción).
   * `fecha`: Marca de tiempo en formato ISO.
   * `errores`: Diccionario campo-error en caso de fallos de validación en formularios.

---

## 3. ARQUITECTURA DEL FRONTEND (ANGULAR 17+)

### 3.1. Estructura de Directorios y Modularización
La aplicación cliente se organiza bajo una estructura modular basada en características (*Feature-driven Architecture*), sin uso de módulos tradicionales (`NgModule`), aprovechando los componentes independientes (*Standalone Components*):

```
geovisionFrontEnd/src/app/
├── core/                                # Servicios singleton transversales y utilitarios globales
│   ├── auth/                           # Gestión de autenticación, sesión y token JWT
│   │   ├── auth-service.ts             # Peticiones HTTP de login y logout al backend
│   │   ├── sesion-service.ts           # Estado reactivo de la sesión en memoria y sessionStorage
│   │   └── auth.model.ts               # Interfaces TypeScript de credenciales y usuario
│   ├── guards/                         # Guardias de enrutamiento angular
│   │   └── auth-guard.ts               # Protección contra accesos no autenticados
│   ├── interceptors/                   # Interceptores funcionales HTTP
│   │   └── auth-interceptor.ts         # Inyección del Bearer token y captura de errores 401
│   ├── models/                         # Modelos genéricos de respuesta (ej. PaginaResponse<T>)
│   └── utils/                          # Manejo estandarizado de excepciones HTTP
├── layout/                             # Estructura visual de la aplicación (Shell)
│   └── main-layout/                    # Barra lateral de navegación, avatar y header dinámico
├── features/                           # Módulos funcionales del sistema
│   ├── auth/                           # Vistas de autenticación (Login, Recuperación)
│   ├── atencion-paciente-consulta/     # MÓDULO: ATENCIÓN AL PACIENTE
│   │   ├── components/                 # Subcomponentes (medidas-form, montura-selector, ficha)
│   │   ├── models/                     # Interfaces de Paciente, Examen, Medida, Lente
│   │   ├── pages/                      # Páginas enrutables (list, form, historial, examen, configurar)
│   │   ├── services/                   # Servicios HTTP (PacienteService, RecetaService, CatalogoOpticoService)
│   │   └── cambios-paciente-guard.ts   # Guardia CanDeactivate para evitar pérdida de datos
│   ├── seguridad/                      # MÓDULO: SEGURIDAD Y CONTROL DE ACCESO
│   │   ├── roles/                      # Gestión de roles y matriz de permisos
│   │   ├── usuarios/                   # Tabla de usuarios del sistema
│   │   ├── usuario-form/               # Edición de usuario existente
│   │   ├── usuario-nuevo/              # Creación de usuario (con o sin persona vinculada)
│   │   ├── seguridad-access.ts         # Guardia RBAC y servicio de permisos de seguridad
│   │   └── seguridad-api.ts            # Servicio HTTP consumidor de endpoints administrativos
│   ├── inicio/                         # Pantalla principal (Dashboard)
│   └── ventas/                         # Módulo comercial de caja y cobranza
└── shared/                             # Componentes y estilos reutilizables (Icono, Modales, Avisos)
```

### 3.2. Gestión Reactiva del Estado de Sesión (`SesionService`)
El frontend no consulta el estado de la sesión haciendo peticiones continuas al servidor. Utiliza un servicio reactivo centralizado:
1. **Almacenamiento Local Seguro:** Al autenticarse satisfactoriamente, el objeto de sesión se serializa en el `sessionStorage` del navegador bajo la clave `geovision.sesion.v1`. El uso de `sessionStorage` asegura que el token no persista tras cerrar la pestaña del navegador, mitigando riesgos de acceso residual en terminales compartidas de la clínica.
2. **Angular Signals (`signal`, `computed`):**
   * `estado = signal<Sesion | null>(null)`: Señal primitiva que almacena el token, datos del usuario, roles y permisos.
   * `actual = this.estado.asReadonly()`: Exposición de solo lectura del estado para evitar mutaciones externas indebidas.
   * `nombre = computed(...)`: Computa reactivamente el nombre a mostrar (nombre completo o username).
   * `iniciales = computed(...)`: Calcula en tiempo real las iniciales del usuario para el avatar visual (ej. "SV" para Samuel Vilca).
3. **Decodificación Preventiva de Expiración (UX):** El servicio decodifica la sección intermedia (Payload Base64URL) del token JWT exclusivamente para leer el reclamo `exp` (expiración) y establecer un temporizador JavaScript (`setTimeout`). Cuando el tiempo expira, la sesión se limpia proactivamente y el usuario es redirigido al login sin esperar a que una petición falle. La validez técnica del token siempre la determina el Backend.

### 3.3. Intercepción y Transporte Seguro (`authInterceptor`)
El interceptor HTTP funcional actúa como un embudo transparente para todas las peticiones salientes:
* **Filtro de Dominio:** Comprueba si la URL destino corresponde al prefijo del API (`environment.apiUrl`).
* **Exclusión de Login:** La petición a `/auth/login` no lleva encabezado de autorización.
* **Inyección de Token:** Para todas las demás peticiones, si existe un token vigente en `SesionService`, clona la petición agregando:
  ```http
  Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
  ```
* **Manejo Centralizado de Expiración (Error 401):** Si el backend rechaza una petición con código `401 Unauthorized`, el interceptor detecta que la sesión caducó, ejecuta `sesion.limpiar()` y redirige al usuario a `/login` adjuntando los parámetros de consulta `?expirada=1&returnUrl=<ruta_donde_estaba>`.

### 3.4. Guardias de Navegación (`Guards`)
El enrutador de Angular protege las rutas utilizando guardias basadas en funciones:
* **`authGuard` (`CanActivateFn`):** Verifica si `SesionService.token()` tiene valor. Si no existe sesión activa, bloquea el paso y redirige a `/login` guardando la URL intentada en `returnUrl`.
* **`seguridadGuard` (`CanActivateFn`):** Ubicado en `seguridad-access.ts`. Evalúa si el usuario autenticado posee el permiso `SEGURIDAD_ADMINISTRAR` o pertenece a los roles `ADMIN` o `ADMINISTRADOR`. Si no cumple la condición, redirige silenciosamente al usuario hacia `/inicio`.
* **`cambiosPacienteGuard` / `cambiosSeguridadGuard` (`CanDeactivateFn`):** Se activan cuando el usuario intenta cambiar de ruta o pulsar el botón "Atrás" del navegador teniendo un formulario clínico o de usuario con datos modificados y no guardados. Despliega un modal de confirmación impidiendo la pérdida accidental de datos clínicos ingresados.

### 3.5. Menú Dinámico y Adaptación RBAC (`MainLayout`)
La plantilla de la barra lateral (`main-layout.html`) implementa renderizado condicional mediante las nuevas directivas de control de flujo de Angular (`@if`):
* Opciones generales como "Inicio / Dashboard" y "Atención de pacientes en consulta" están disponibles para el personal clínico y asistencial.
* La sección **SEGURIDAD & SISTEMA** está condicionada a `@if (accesoSeguridad.permitido())`. Los enlaces "Gestión de Usuarios" y "Roles y Permisos" solo se renderizan en el DOM si el token contiene los privilegios de administración.
* El pie de la barra lateral muestra el avatar generado con las iniciales, el rol principal del usuario y un botón de cierre de sesión seguro que solicita confirmación antes de ejecutar el logout en servidor y cliente.

---

## 4. ARQUITECTURA DEL BACKEND (SPRING BOOT 3 + ORACLE 19C)

### 4.1. Patrón Arquitectónico en Capas Estricto
El backend sigue una arquitectura por capas desacoplada con inversión de dependencias:

```
geovisionBackEnd/src/main/java/pe/edu/upeu/geovisionBackEnd/
├── config/              # Configuraciones del framework (SecurityConfig, CorsConfig, JacksonConfig)
├── security/            # Componentes de seguridad JWT y carga de usuarios
│   ├── JwtAuthenticationFilter.java      # Filtro OncePerRequestFilter para validación del token
│   ├── JwtService.java                   # Utilidades de firma, generación y lectura de claims
│   ├── UsuarioDetailsService.java        # Carga de usuario y agregación de roles y permisos
│   ├── RestAuthenticationEntryPoint.java # Respuesta 401 en formato JSON
│   └── RestAccessDeniedHandler.java      # Respuesta 403 en formato JSON
├── controller/          # Capa de presentación REST (Controladores HTTP)
│   ├── AuthController.java               # Endpoints públicos de login y recuperación; logout
│   ├── UsuarioController.java            # Endpoints de administración de cuentas de usuario
│   ├── RolController.java                # Endpoints de administración de roles
│   ├── PermisoController.java            # Endpoints de consulta de permisos
│   ├── PacienteController.java           # Endpoints de gestión de pacientes
│   ├── RecetaController.java             # Endpoints de examen visual, receta y configuración de lente
│   └── CatalogoOpticoController.java     # Endpoints de cristales, tratamientos y monturas
├── service/             # Capa de Lógica de Negocio (Interfaces y Servicios)
│   ├── service/                          # Contratos e interfaces públicas
│   └── impl/                             # Implementaciones de servicios de negocio (@Service)
│       ├── AuthServiceImpl.java          # Lógica de login, cambio de clave y recuperación
│       ├── UsuarioServiceImpl.java       # Altas, bajas lógicas, asignación de roles
│       ├── RolServiceImpl.java           # Asignación matricial de permisos a roles
│       ├── PacienteServiceImpl.java      # Gestión de pacientes, bloqueos y auditoría
│       ├── RecetaServiceImpl.java        # Lógica clínica de exámenes, lentes y medidas
│       ├── RecetaPdfServiceImpl.java     # Generación del PDF de receta con PDFBox
│       └── CatalogoOpticoServiceImpl.java# Consulta de materiales, tratamientos y stock
├── mapper/              # Mapeadores MapStruct para conversión DTO <-> Entidad
├── repository/          # Capa de persistencia (Spring Data JPA)
├── entity/              # Entidades mapeadas a tablas Oracle 19c
├── enums/               # Enumeraciones de dominio (EstadoGeneralEnum, ModuloEnum, TipoLogEnum)
├── dto/                 # Objetos de Transferencia de Datos (DTO) y validación Bean Validation
├── util/                # Validadores de dominio clínico (OpticaValidator)
└── exception/           # Manejador global de excepciones (@RestControllerAdvice)
```

### 4.2. Flujo de una Petición HTTP en la Cadena de Seguridad
Cada petición HTTP recibida por Spring Boot atraviesa la cadena de filtros configurada en `SecurityConfig`:

1. **CorsFilter:** Inspecciona si la petición proviene de un origen web autorizado y gestiona las peticiones de preflight `OPTIONS`.
2. **SessionManagement:** Se establece en `STATELESS`. No se generan cookies `JSESSIONID`.
3. **JwtAuthenticationFilter:**
   * Examina el encabezado `Authorization`.
   * Si no inicia con `Bearer `, deja pasar la petición (será rechazada en el paso de autorización si la ruta es privada).
   * Si contiene el token, invoca a `JwtService.extraerUsername(token)`.
   * Llama a `UsuarioDetailsService.loadUserByUsername(username)`.
   * Valida si el usuario y el empleado vinculado se encuentran en estado `ACTIVO`.
   * Construye un objeto `UsernamePasswordAuthenticationToken` con la lista consolidada de autoridades (`ROLE_<ROL>` y nombres de permisos unitarios) y lo almacena en `SecurityContextHolder.getContext().setAuthentication(...)`.
4. **AuthorizationFilter (Control de Rutas y Métodos):**
   * Comprueba si la ruta solicitada coincide con las `RUTAS_PUBLICAS` (`/api/v1/auth/login`, `/api/v1/auth/recuperar-password`, etc.).
   * Para rutas administrativas (`/api/v1/usuarios/**`, `/api/v1/roles/**`), verifica si el usuario posee la autoridad `SEGURIDAD_ADMINISTRAR` o el rol `ADMINISTRADOR`.
   * A nivel de controlador, la anotación `@EnableMethodSecurity` evalúa las directivas `@PreAuthorize("hasAuthority('...')")` antes de permitir la ejecución del método.
5. **Manejo de Violaciones:**
   * Si no hay token o es inválido: `RestAuthenticationEntryPoint` responde `401 Unauthorized` en JSON.
   * Si el usuario está autenticado pero no tiene el permiso necesario: `RestAccessDeniedHandler` responde `403 Forbidden` en JSON.

### 4.3. Lógica Transaccional y Bloqueos de Concurrencia
Para garantizar la integridad estricta en una clínica con múltiples recepcionistas y consultorios trabajando simultáneamente:
* **Lecturas No Bloqueantes:** Todos los métodos de consulta de solo lectura aplican `@Transactional(readOnly = true)`, optimizando las sesiones de Hibernate y evitando *dirty checks* innecesarios.
* **Bloqueo Pesimista en Base de Datos (`PESSIMISTIC_WRITE`):**
  * En `PacienteServiceImpl`, al actualizar o registrar un paciente se invoca `personaRepository.findByIdForUpdate(id)`, ejecutando en Oracle:
    ```sql
    SELECT * FROM PERSONA WHERE ID_PERSONA = ? FOR UPDATE;
    ```
    Esto previene que dos usuarios modifiquen los datos filiatorios o registren dos pacientes sobre la misma persona al mismo tiempo.
  * En `RecetaServiceImpl.configurarLente`, se bloquea la receta con `recetaRepository.findByIdForUpdate(idReceta)` y se verifica que no esté vinculada a una venta en la tabla `VENTA`. Si la receta ya fue facturada en caja, se aborta la configuración lanzando `ReglaNegocioException`.
* **Alineación Temporal con Oracle DATE:** Las fechas se truncan a precisión de segundos (`.withNano(0)`), evitando discrepancias entre la memoria de Java y el tipo `DATE` de Oracle 19c.

---

## 5. MÓDULO DE SEGURIDAD Y CONTROL DE ACCESO (DETALLE INTEGRAL)

### 5.1. Casos de Uso Implementados

| Caso de Uso | Identificador | Actor | Endpoint Backend | Componente Frontend |
| :--- | :---: | :--- | :--- | :--- |
| **Iniciar Sesión** | CUS15 | Todos los Roles | `POST /api/v1/auth/login` | `features/auth/pages/login/login.ts` |
| **Cerrar Sesión** | CUS16 | Todos los Roles | `POST /api/v1/auth/logout` | `SesionService.limpiar()` / `MainLayout` |
| **Registrar y Modificar Usuarios** | CUS17 | Administrador | `POST /api/v1/usuarios`<br>`PUT /api/v1/usuarios/{id}`<br>`PATCH /api/v1/usuarios/{id}/estado` | `features/seguridad/usuarios/usuarios.ts`<br>`features/seguridad/usuario-form/usuario-form.ts` |
| **Asignar Roles y Permisos** | CUS18 | Administrador | `PUT /api/v1/usuarios/{id}/roles`<br>`PUT /api/v1/roles/{id}/permisos` | `features/seguridad/roles/roles.ts`<br>`features/seguridad/roles/roles-dialog.ts` |
| **Recuperar Contraseña** | CUS19 | Usuario General | `POST /api/v1/auth/recuperar-password`<br>`GET /api/v1/auth/validar-token`<br>`POST /api/v1/auth/reset-password` | Formulario público de recuperación y reset en `features/auth` |

### 5.2. Ciclo de Vida de la Autenticación (CUS15 e Iniciar Sesión)
1. **Entrada de Credenciales:** El usuario ingresa en la pantalla de login su identificador (nombre de usuario o correo electrónico) y su contraseña en texto plano.
2. **Envío y Validación Previa:** El frontend valida que los campos no estén vacíos y despacha la petición POST mediante `AuthService.login()`.
3. **Autenticación en Spring Security:**
   * `AuthController` delega en `AuthServiceImpl.login(LoginRequestDTO)`.
   * Se invoca a `AuthenticationManager.authenticate(...)`.
   * El `DaoAuthenticationProvider` llama a `UsuarioDetailsService.loadUserByUsername(...)`, el cual busca en la base de datos Oracle si existe un usuario con dicho nombre o correo:
     ```sql
     SELECT u FROM Usuario u WHERE LOWER(u.nombre) = LOWER(:termino) OR LOWER(u.correo) = LOWER(:termino)
     ```
   * Se evalúa si la cuenta de usuario está activa (`usuario.getEstado() == ACTIVO`) y si el empleado asociado está activo.
   * Si la contraseña cifrada almacenada con BCrypt no coincide, se atrapa la excepción `AuthenticationException`, se registra el incidente como `INTENTO_FALLIDO` en la tabla `USUARIO_LOG` y se retorna error 401 con el mensaje "Nombre de usuario o contraseña incorrectos".
4. **Generación de Token JWT:**
   * Si las credenciales son válidas, `JwtService.generarToken(...)` construye el JWT:
     * **Header:** Algoritmo `HS256`, Tipo `JWT`.
     * **Payload (Claims):**
       * `sub`: Nombre de usuario.
       * `authorities`: Lista de strings conteniendo los roles (`ROLE_ADMINISTRADOR`, `ROLE_OPTOMETRA`, etc.) y todos los permisos asociados a dichos roles (`PACIENTES_LEER`, `PACIENTES_REGISTRAR`, `RECETAS_REGISTRAR`, etc.).
       * `iat`: Fecha y hora de emisión.
       * `exp`: Fecha y hora de caducidad (8 horas / 480 minutos por defecto).
     * **Firma:** Creada con clave criptográfica secreta Base64 mediante `Keys.hmacShaKeyFor`.
5. **Auditoría de Acceso:** Se inserta inmediatamente un registro de tipo `LOGIN` en la tabla `USUARIO_LOG`.
6. **Respuesta al Cliente:** El backend devuelve un `LoginResponseDTO` con el token Bearer, datos del usuario, roles y permisos.
7. **Recepción en Frontend:** `AuthService` recibe la respuesta y `SesionService.iniciar(...)` almacena la sesión en `sessionStorage`, activa las señales reactivas de UI y redirige al Dashboard o a la ruta solicitada originalmente (`returnUrl`).

### 5.3. Modelo RBAC (Control de Acceso Basado en Roles) y Permisos de Granularidad Fina
El sistema no ata los permisos a las pantallas de forma rígida, sino que implementa una estructura relacional desacoplada:
* **Usuario (`USUARIO`):** Cuenta de acceso vinculada a un empleado de la clínica.
* **Rol (`ROL`):** Perfil de trabajo funcional (ej. `ADMINISTRADOR`, `OPTOMETRA`, `RECEPCIONISTA`, `VENDEDOR`).
* **Permiso (`PERMISO`):** Atribución atómica sobre una acción del sistema (ej. `PACIENTES_LEER`, `PACIENTES_REGISTRAR`, `PACIENTES_GESTIONAR`, `EXAMENES_REGISTRAR`, `RECETAS_REGISTRAR`, `SEGURIDAD_ADMINISTRAR`, `VENTAS_REGISTRAR`).
* **Relaciones N:M:**
  * Un usuario puede tener uno o múltiples roles (`USUARIO_ROL`).
  * Un rol agrupa un conjunto dinámico de permisos (`ROL_PERMISO`).
* **Matriz Visual en Frontend:** En la vista de Roles (`roles.ts`), el administrador puede seleccionar cualquier rol y activar/desactivar checkboxes de permisos organizados por módulo (`Atención al Paciente`, `Ventas`, `Inventario`, `Seguridad`). Al guardar, se ejecuta `PUT /api/v1/roles/{id}/permisos` enviando la lista de IDs de permisos seleccionados.

### 5.4. Flujo de Recuperación de Contraseña (CUS19)
1. **Solicitud:** El usuario ingresa su correo en la pantalla de recuperación. Se envía `POST /api/v1/auth/recuperar-password`.
2. **Validación y Generación de Token Temporal:** `AuthServiceImpl` busca la cuenta asociada. Si está activa, genera un token JWT especial con tiempo de vida estricto de **15 minutos** y un reclamo diferenciador:
   ```json
   { "purpose": "PASSWORD_RESET", "sub": "usuario@geovision.pe", "exp": 1700000000 }
   ```
   *Nota de seguridad:* Si un atacante intenta utilizar este token para autenticar una petición a un endpoint de la API, el filtro `JwtAuthenticationFilter` lo rechazará porque el método `extraerUsername()` valida que los tokens con `purpose != null` no son válidos para acceso general.
3. **Envío de Email:** `EmailServiceImpl` compone un mensaje de correo con el enlace que incluye el token como parámetro.
4. **Validación de Enlace:** Al hacer clic en el correo, la vista de recuperación consulta `GET /api/v1/auth/validar-token?token=...` para asegurar que el token no ha expirado antes de mostrar los campos de cambio de contraseña.
5. **Restablecimiento:** El usuario ingresa la nueva clave. Se valida que cumpla con los estándares de seguridad (no superar 72 bytes por límite de BCrypt y coincidencia de confirmación). El backend actualiza la clave cifrada con BCrypt, registra el evento `CAMBIO_PASSWORD` en `USUARIO_LOG` y anula el proceso.

---

## 6. MÓDULO DE ATENCIÓN AL PACIENTE EN CONSULTA (DETALLE INTEGRAL)

### 6.1. Casos de Uso Implementados

| Caso de Uso | Identificador | Actor Principal | Endpoint Backend | Componente Frontend |
| :--- | :---: | :--- | :--- | :--- |
| **Registrar Paciente** | CUS01 | Recepcionista / Optómetra | `POST /api/v1/pacientes` | `pages/paciente-form/paciente-form.ts` |
| **Consultar Historial Clínico** | CUS02 | Recepcionista / Optómetra | `GET /api/v1/pacientes/{id}`<br>`GET /api/v1/recetas/paciente/{id}/historial` | `pages/paciente-historial/paciente-historial.ts`<br>`pages/paciente-perfil/paciente-perfil.ts` |
| **Registrar Examen Visual** | CUS03 | Optómetra | `POST /api/v1/recetas/examen-visual` | `pages/examen-visual/examen-visual.ts`<br>`components/medidas-form/medidas-form.ts` |
| **Configurar Lente y Emitir Receta** | CUS04 | Optómetra | `POST /api/v1/recetas/{idReceta}/lentes`<br>`GET /api/v1/recetas/{idReceta}/pdf` | `pages/configurar-lentes/configurar-lentes.ts`<br>`components/montura-selector/montura-selector.ts` |

### 6.2. CUS01: Registro y Filiación de Pacientes
1. **Captura de Datos:** La interfaz `paciente-form` recopila: Tipo de documento (DNI, Carnet de Extranjería, Pasaporte), Número de documento (exactamente 8 dígitos numéricos para DNI), Nombres, Apellidos, Sexo, Teléfono, Correo Electrónico, Dirección y Fecha de Nacimiento.
2. **Validación en Cliente y Servidor:**
   * El cliente previene el envío si el formulario tiene errores reactivos (`Validators.required`, `Validators.pattern`).
   * En el backend, el DTO `PacienteRequestDTO` está blindado con anotaciones Bean Validation (`@NotNull`, `@NotBlank`, `@Size`).
3. **Lógica de Persistencia y Separación Persona / Paciente:**
   * El sistema modela la herencia/especialización: una `PERSONA` contiene los atributos biográficos universales, y un `PACIENTE` representa el rol clínico que esa persona asume en la empresa.
   * Si la persona ya existía en la base de datos (por ejemplo, como cliente o empleado), se vincula su `idPersona`. Si es nueva, se valida primero que el número de documento no esté duplicado:
     ```java
     if (personaRepository.existsByNumeroDocumento(documento)) {
         throw new ReglaNegocioException("El documento ya está registrado; seleccione la persona existente");
     }
     ```
   * Se guarda la `Persona` y luego se crea la entidad `Paciente` asociada a dicha persona y al usuario autenticado que realiza el registro (`actor`).
4. **Auditoría Transaccional:** Se registra automáticamente una entrada en la tabla `PACIENTE_LOG` con la referencia al paciente y al empleado/usuario que ejecutó la operación.

### 6.3. CUS02: Consulta de Historial Clínico Oftalmológico
1. **Búsqueda Dinámica:** En `paciente-list`, el usuario puede ingresar texto en el campo de búsqueda. El servicio invoca `GET /api/v1/pacientes?termino=...&estado=1&page=0&size=10`.
2. **Búsqueda Optimizada con Caracteres Especiales:** En `PacienteServiceImpl`, los comodines SQL (`%`, `_`, `!`) son sanitizados para evitar inyecciones o lecturas no deseadas. La consulta busca coincidencias por documento de identidad o concatenación de nombres y apellidos.
3. **Visualización de la Ficha Clínica:** Al seleccionar un paciente, la ruta `/pacientes/:id/historial` carga:
   * **Datos Generales:** Mostrados mediante el componente `paciente-ficha` (edad calculada, documento, teléfono, estado activo/inactivo).
   * **Historial de Recetas Paginado:** Invocación a `GET /api/v1/recetas/paciente/{id}/historial`.
   * **Detalle Refracción:** Cada receta muestra su fecha, el optómetra responsable y la tabla de mediciones de OD y OI. Si la receta ya cuenta con lentes configurados, muestra el material del cristal, tratamientos y montura asociada.

### 6.4. CUS03: Examen Visual y Mediciones Refractivas
1. **Ergonomía de Captura:** La vista `examen-visual` utiliza el subcomponente `medidas-form`, el cual presenta dos columnas simétricas correspondientes a la práctica médica: **Ojo Derecho (OD)** y **Ojo Izquierdo (OI)**.
2. **Campos Oftálmicos Especializados:**
   * **Esfera (SPH):** Rango dioptrico de corrección de miopía o hipermetropía (valores de -25.00 a +25.00).
   * **Cilindro (CYL):** Corrección de astigmatismo (valores de -10.00 a +10.00).
   * **Eje (AXIS):** Ángulo de inclinación del astigmatismo (0° a 180°).
   * **Adición (ADD):** Graduación para visión cercana / presbicia (valores de +0.75 a +4.00).
   * **Distancia Pupilar (DP):** Distancia anatómica milimétrica entre centros pupilares.
3. **Validación de Reglas de Negocio Clínico (`OpticaValidator`):**
   * El servicio valida que ningún valor fraccionario vulnere el estándar de fabricación óptica mundial: **las dioptrías deben ser múltiplos exactos de 0.25**:
     ```java
     if (valor != null && valor.remainder(new BigDecimal("0.25")).compareTo(BigDecimal.ZERO) != 0) {
         throw new ReglaNegocioException("El valor de " + campo + " debe ser múltiplo de 0.25");
     }
     ```
   * Si el usuario ingresa cilindro sin eje, o un eje fuera de 0° - 180°, la petición es rechazada de inmediato.
4. **Persistencia Atómica Relacional:** La inserción de un examen visual es una sola transacción que distribuye los datos en 3 tablas:
   * Inserta en `RECETA` (marcando `esExterno = 0`, fecha y empleado optómetra).
   * Inserta dos registros en `MEDIDA_OJO` (uno para OD y otro para OI con sus esferas, cilindros, ejes y adiciones).
   * Inserta en `MEDIDA` uniendo ambos ojos bajo la receta clínica creada.

### 6.5. CUS04: Configuración de Lentes Ópticos y Emisión de Receta en PDF
1. **Flujo de Configuración Técnica (`configurar-lentes.ts`):** Una vez que la receta tiene sus medidas registradas, el optómetra pasa a la etapa de configuración del lente:
   * **Paso 1: Selección del Material del Cristal:** Carga desde `CatalogoOpticoService.materiales()` las opciones disponibles: Orgánico (CR-39), Policarbonato, Alto Índice (1.67, 1.74), Mineral (Vidrio), etc.
   * **Paso 2: Selección de Tratamientos:** Carga `CatalogoOpticoService.tratamientos()` y permite selección múltiple: Antirreflejo básico, Antirreflejo multicapa (Crizal), Filtro de Luz Azul (Blue Defense), Fotocromático (Transitions), Protección UV400.
   * **Paso 3: Selección de Montura:** Mediante el componente `montura-selector`, consulta el stock del catálogo en tiempo real. Permite elegir una montura de inventario (validando que tenga `stock > 0`) o marcar que el paciente trae "Montura propia".
   * **Paso 4: Cálculo de Importes:** Se calcula el subtotal técnico del trabajo.
2. **Validación de Bloqueo de Venta:** En `RecetaServiceImpl`, antes de insertar la configuración del lente se valida:
   ```java
   if (ventaRepository.existsByRecetaIdReceta(idReceta)) {
       throw new ReglaNegocioException("No se puede configurar una receta que ya está vinculada a una venta");
   }
   ```
   Esto evita que un optómetra altere materiales o precios de una receta que ya fue cancelada o cobrada en caja.
3. **Persistencia en Modelo Físico:** Se almacena el registro principal en la tabla `LENTE` y se asocian los registros N:M en `LENTE_TRATAMIENTO_CRISTAL` y `LENTE_MEDIDA`.
4. **Generación Programática de PDF con Apache PDFBox (`RecetaPdfServiceImpl`):**
   * Endpoint: `GET /api/v1/recetas/{idReceta}/pdf`.
   * El servicio genera el documento PDF en memoria (`ByteArrayOutputStream`), sin escribir archivos temporales en disco.
   * **Estructura del PDF:**
     * Cabecera oficial: Razón social de la óptica, RUC, dirección y teléfono cargados dinámicamente desde `ConfiguracionEmpresa`.
     * Título y Tipo de Receta: Identificador médico y tipo (Examen interno o prescripción externa).
     * Filiación del Paciente: Nombre completo, número de documento y fecha de emisión.
     * Nombre del profesional optómetra responsable.
     * Tabla clínica de refracción: Filas OD y OI con Esfera, Cilindro, Eje, Adición y DP.
     * Especificaciones del lente configurado: Material de cristal, montura (código, marca y modelo o montura propia) y lista de tratamientos aplicados.
     * Espacio de firma y sello del optómetra.
   * **Streaming HTTP:** Se retorna un `ResponseEntity<byte[]>` con encabezados:
     * `Content-Type: application/pdf`
     * `Content-Disposition: attachment; filename="receta-{id}.pdf"`
     * `Cache-Control: no-store`

---

## 7. MODELO DE DATOS Y PERSISTENCIA (ORACLE 19C)

### 7.1. Estructura de Tablas del Módulo de Seguridad

```
   +-------------------+          +-------------------+          +-------------------+
   |      PERSONA      | 1      1 |     EMPLEADO      | 1      1 |      USUARIO      |
   +-------------------+----------+-------------------+----------+-------------------+
   | PK id_persona     |          | PK id_persona (FK)|          | PK id_usuario     |
   |    numero_doc     |          |    id_cargo (FK)  |          | FK id_persona     |
   |    nombres        |          |    sueldo         |          |    nombre (user)  |
   |    apellidos      |          |    fecha_ingreso  |          |    correo         |
   |    correo         |          |    estado         |          |    password       |
   |    telefono       |          +-------------------+          |    estado         |
   +-------------------+                                         +---------+---------+
                                                                           | 1
                                                                           |
                                                                           | N
                                                                 +---------+---------+
                                                                 |    USUARIO_LOG    |
                                                                 +-------------------+
                                                                 | PK id_usuario_log |
                                                                 | FK id_usuario     |
                                                                 |    tipo_log       |
                                                                 |    fecha_registro |
                                                                 +-------------------+

   +-------------------+          +-------------------+          +-------------------+
   |      USUARIO      | 1      N |    USUARIO_ROL    | N      1 |        ROL        |
   +-------------------+----------+-------------------+----------+-------------------+
                                  | PK,FK id_usuario  |          | PK id_rol         |
                                  | PK,FK id_rol      |          |    nombre         |
                                  +-------------------+          |    descripcion    |
                                                                 +---------+---------+
                                                                           | 1
                                                                           | N
                                                                 +---------+---------+
                                                                 |    ROL_PERMISO    |
                                                                 +-------------------+
                                                                 | PK,FK id_rol      |
                                                                 | PK,FK id_permiso  |
                                                                 +---------+---------+
                                                                           | N
                                                                           | 1
                                                                 +---------+---------+
                                                                 |      PERMISO      |
                                                                 +-------------------+
                                                                 | PK id_permiso     |
                                                                 |    nombre         |
                                                                 |    modulo         |
                                                                 +-------------------+
```

### 7.2. Estructura de Tablas del Módulo de Atención al Paciente

```
   +-------------------+ 1      1 +-------------------+ 1      N +-------------------+
   |      PERSONA      +----------+     PACIENTE      +----------+    PACIENTE_LOG   |
   +-------------------+          +-------------------+          +-------------------+
   | PK id_persona     |          | PK id_persona (FK)|          | PK id_paciente_log|
   |    numero_doc     |          | FK id_usuario (FK)|          | FK id_paciente(FK)|
   |    nombres        |          |    estado         |          | FK id_usuario (FK)|
   |    apellidos      |          +---------+---------+          |    fecha_registro |
   +-------------------+                    | 1                  +-------------------+
                                            |
                                            | N
                                  +---------+---------+
                                  |      RECETA       |
                                  +-------------------+
                                  | PK id_receta      |
                                  | FK id_paciente(FK)|
                                  | FK id_empleado(FK)|
                                  |    es_externo     |
                                  |    fecha_registro |
                                  +----+-----------+--+
                                       | 1         | 1
                         +-------------+           +-------------+
                         | N                                     | N
               +---------+---------+                   +---------+---------+
               |      MEDIDA       |                   |       LENTE       |
               +-------------------+                   +-------------------+
               | PK id_medida      |                   | PK id_lente       |
               | FK id_receta (FK) |                   | FK id_receta (FK) |
               | FK id_ojo_der (FK)|                   | FK id_material(FK)|
               | FK id_ojo_izq (FK)|                   | FK id_producto(FK)|
               |    distancia_p    |                   |    sub_total      |
               +---------+---------+                   +----+----------+---+
                         |                                  |          |
            +------------+------------+                     |          |
            |                         |                     |          |
            | 1                       | 1                   | N        | N
  +---------+---------+     +---------+---------+     +-----+-----+  +-+---------+
  |  MEDIDA_OJO (OD)  |     |  MEDIDA_OJO (OI)  |     |LENTE_TRAT |  |LENTE_MED  |
  +-------------------+     +-------------------+     +-----------+  +-----------+
  | PK id_medida_ojo  |     | PK id_medida_ojo  |     |PK,FK lente|  |PK,FK lente|
  |    esfera         |     |    esfera         |     |PK,FK trat |  |PK,FK med  |
  |    cilindro       |     |    cilindro       |     +-----+-----+  +-----------+
  |    eje            |     |    eje            |           |
  |    adicion        |     |    adicion        |           | N
  +-------------------+     +-------------------+           | 1
                                                      +-----+-----+
                                                      |TRATAMIENTO|
                                                      +-----------+
                                                      |PK id_trat |
                                                      |   nombre  |
                                                      +-----------+
```

---

## 8. GUÍA PEDAGÓGICA PARA EXPOSITORES Y DEFENSA DEL PROYECTO

Si debes explicar o defender este sistema ante un jurado evaluador, docente o directivo técnico, utiliza la siguiente estructura recomendada de 4 bloques:

### Bloque 1: Visión de Negocio y Justificación (2 minutos)
* **El Problema:** Las ópticas tradicionales manejan recetas en papel o en sistemas desconectados de la facturación y el inventario, lo que provoca errores en la graduación de lentes, falta de historial clínico del paciente y nula trazabilidad de accesos.
* **La Solución:** GeoVision unifica la consulta optométrica con el control comercial y de seguridad, garantizando que ninguna receta se altere tras facturarse y que cada acción clínica quede auditada.

### Bloque 2: Arquitectura y Decisiones Tecnológicas Clave (3 minutos)
* **¿Por qué Angular 17+ Standalone y Signals?**
  * Elimina la sobrecarga de módulos (`NgModule`).
  * Las señales (`Signals`) ofrecen reactividad granular sin sobrecargar la zona de Angular (`NgZone`), optimizando la velocidad de renderizado de tablas clínicas.
* **¿Por qué Spring Boot 3 y Arquitectura Stateless?**
  * Desacoplamiento total: la API puede atender a la web de Angular, aplicaciones móviles o terminales de consulta sin cambiar una sola línea de lógica.
  * Escalabilidad: al no almacenar sesiones en memoria, se pueden tener múltiples instancias de backend balanceadas con el mismo token JWT.
* **¿Por qué Oracle 19c y Bloqueos Pesimistas (`SELECT FOR UPDATE`)?**
  * La consistencia médica y financiera no admite carreras de concurrencia (*race conditions*). Si dos usuarios intentan vincular un paciente al mismo tiempo, el bloqueo pesimista en base de datos serializa la transacción de forma atómica.

### Bloque 3: Demostración del Flujo Operativo en Vivo (4 minutos)
1. **Inicio de Sesión:** Mostrar el login de un Optómetra vs un Administrador. Explicar cómo el interceptor almacena el JWT y cómo el menú lateral cambia dinámicamente según los permisos devueltos.
2. **Atención al Paciente:**
   * Buscar un paciente en `paciente-list` y abrir su historial clínico.
   * Crear un nuevo Examen Visual: ingresar medidas de OD y OI demostrando la validación de múltiplos de 0.25 (regla clínica).
   * Configurar el Lente: seleccionar material de cristal, tratamientos y montura.
   * Generar el PDF: presionar el botón de descarga y mostrar el documento generado al vuelo con Apache PDFBox.
3. **Módulo de Seguridad:**
   * Ingresar como Administrador a la matriz de Roles y Permisos.
   * Demostrar que los permisos están agrupados por módulos de negocio y que al asignar o revocar un permiso, el backend protege inmediatamente el endpoint con `@PreAuthorize`.

### Bloque 4: Preguntas Frecuentes de Jurados Técnicos y Respuestas Clave

* **Pregunta 1: ¿Por qué eligieron JWT en lugar de sesiones tradicionales con cookies (`JSESSIONID`)?**
  * *Respuesta:* Por el principio de arquitectura Stateless. JWT permite que el servidor no gaste memoria en sesiones de usuario. Todo lo necesario para saber quién es el usuario y qué puede hacer viene en el Payload firmado. Si el backend se reinicia, ningún usuario pierde su sesión.
* **Pregunta 2: Si el JWT viaja en cada petición, ¿cómo evitan que un atacante suplante al usuario si intercepta el token?**
  * *Respuesta:* Primero, mediante el uso obligatorio de HTTPS que cifra todo el canal de transporte. Segundo, el token está firmado con HMAC-SHA256 usando una clave secreta que solo el servidor conoce; si alguien altera una sola letra del payload, la firma se invalida y el `JwtAuthenticationFilter` rechaza la petición con error 401. Tercero, el tiempo de expiración es corto (8 horas) y los tokens de recuperación solo duran 15 minutos con un propósito específico (`purpose: PASSWORD_RESET`).
* **Pregunta 3: ¿Qué ocurre si dos recepcionistas intentan registrar al mismo paciente al mismo tiempo?**
  * *Respuesta:* La capa de servicio implementa dos niveles de defensa: validación programática con `personaRepository.findByIdForUpdate` (bloqueo pesimista) y una restricción única (`UNIQUE CONSTRAINT`) a nivel de base de datos en Oracle 19c sobre la columna `NUMERO_DOCUMENTO`. Una transacción confirma y la otra recibe una excepción sanitizada de conflicto (409 / Regla de Negocio).
* **Pregunta 4: ¿Cómo manejan el desacoplamiento entre las entidades de la base de datos y la interfaz gráfica?**
  * *Respuesta:* Mediante el patrón DTO (*Data Transfer Object*) y MapStruct. Ninguna entidad JPA de Oracle se expone directamente a los controladores REST. Esto protege la base de datos de ataques de asignación masiva (*Mass Assignment*) y permite versionar los contratos de API sin alterar el esquema físico.

---

*Documento técnico elaborado y compilado para el sistema óptico GeoVision.*
