# GeoVision Software

Sistema integral de gestión óptica y optometría con arquitectura desacoplada: Frontend SPA en **Angular 22**, Backend API REST en **Spring Boot 4 / Java 21**, y Base de Datos **Oracle Database 23c / 19c**.

---

## 📁 Estructura del Repositorio

```text
geovision-software/
├── geovisionBackEnd/      # Microservicio / API REST en Spring Boot 4 + Java 21
│   ├── database/          # Scripts DDL, DML y procedimientos PL/SQL
│   ├── src/               # Código fuente Java (controladores, servicios, seguridad JWT)
│   ├── Dockerfile         # Dockerfile para contenedorización del backend
│   └── pom.xml            # Configuración Maven y dependencias
│
├── geovisionFrontEnd/     # Aplicación web SPA en Angular 22 + TailwindCSS
│   ├── src/               # Componentes, servicios, guardias, interceptores
│   ├── Dockerfile         # Dockerfile multietapa con servidor Nginx
│   └── package.json       # Dependencias NPM y scripts de compilación
│
├── docs/                  # Documentación técnica, ADRs y entregables
├── docker-compose.yml     # Orquestación de Oracle DB, Backend y Frontend
└── README.md              # Documentación principal del proyecto
```

---

## 🚀 Despliegue Rápido con Docker Compose

El proyecto está listo para ejecutarse en contenedores mediante `docker compose`:

```bash
# Levantar todos los servicios (Oracle DB, Backend y Frontend)
docker compose up --build -d

# Ver registros en tiempo real
docker compose logs -f

# Detener los servicios
docker compose down
```

### Puertos de los Servicios:
- **Frontend (Web):** [http://localhost](http://localhost) (Puerto 80)
- **Backend (API REST):** [http://localhost:8080](http://localhost:8080)
- **Base de Datos Oracle:** Puerto `1522` (Mapeado internamente a `1521`, servicio `FREEPDB1`)

---

## 💻 Ejecución en Entorno Local (Desarrollo)

### 1. Base de Datos Oracle
Asegúrate de contar con una instancia Oracle disponible o levántala con Docker:
```bash
docker compose up oracle-db -d
```

### 2. Backend (Spring Boot)
Requiere **Java 21** y **Maven**:
```bash
cd geovisionBackEnd
./mvnw clean spring-boot:run
```

### 3. Frontend (Angular)
Requiere **Node.js 20+**:
```bash
cd geovisionFrontEnd
npm install
npm start
```
El frontend estará disponible en [http://localhost:4200](http://localhost:4200).

---

## 🛠️ Tecnologías Principales

- **Frontend:** Angular 22, TypeScript, TailwindCSS, Lucide Icons, RxJS.
- **Backend:** Java 21, Spring Boot 4, Spring Security 6, JWT, Spring Data JPA, Hibernate, Mercado Pago SDK.
- **Base de Datos:** Oracle Database (PL/SQL, Triggers, Funciones y Procedimientos Almacenados).
- **Infraestructura:** Docker, Docker Compose, Nginx.
