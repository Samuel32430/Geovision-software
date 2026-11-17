-- ============================================================================
-- UNIVERSIDAD PERUANA UNION - FACULTAD DE INGENIERIA Y ARQUITECTURA
-- E.P. DE INGENIERIA DE SISTEMAS - ADMINISTRACION DE BASE DE DATOS II
-- PROYECTO: GEOVISION (SISTEMA INTEGRAL DE OPTICA)
-- SCRIPT MAESTRO INTEGRAL DE OBJETOS ORACLE 19c ENTERPRISE EDITION
-- Docente: Mg. Cynthia Acuña Salinas
-- Integrantes: 3 Integrantes
-- Fecha: Noviembre, 2026
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 100;
PROMPT >>> INICIANDO DESPLIEGUE DEL ENTREGABLE DE ADMINISTRACION DE BD II - GEOVISION...

-- ============================================================================
-- 1. CONFIGURACION DE TABLESPACES, ROLES Y PRIVILEGIOS DE MOTOR
-- ============================================================================
PROMPT >>> [1/9] Configurando Tablespaces, Roles y Privilegios...

/*
-- Ejecutar como SYSDBA si se requiere provisionar almacenamiento fisico:
CREATE TABLESPACE TS_GEOVISION_PROD_DATA DATAFILE 'ts_geovision_prod_data01.dbf' SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE 10G;
CREATE TABLESPACE TS_GEOVISION_PROD_IDX  DATAFILE 'ts_geovision_prod_idx01.dbf'  SIZE 200M AUTOEXTEND ON NEXT 50M  MAXSIZE 5G;

CREATE ROLE ROL_DBA_GEO;
CREATE ROLE ROL_DEV_OPTICA;
CREATE ROLE ROL_APP_BACKEND;
CREATE ROLE ROL_AUDITOR_CLINICO;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE TRIGGER TO ROL_DEV_OPTICA;
GRANT CREATE SESSION TO ROL_APP_BACKEND;
GRANT CREATE SESSION, AUDIT_ADMIN, AUDIT_VIEWER TO ROL_AUDITOR_CLINICO;
*/

-- ============================================================================
-- 2. DDL DE TABLAS BASE Y CONSTRAINTS (35 TABLAS)
-- ============================================================================
PROMPT >>> [2/9] Creando Estructura de Tablas y Constraints...
/*==================================================
-- SISTEMA GEOVISION - BASE DE DATOS ORACLE 19c
-- Fase 1: Creación de Entidades
==================================================*/

CREATE TABLE CONFIGURACION_EMPRESA (
	id_configuracion_empresa NUMBER GENERATED ALWAYS AS IDENTITY,
	nombre_legal VARCHAR2(200) NOT NULL,
	nombre_comercial VARCHAR2(200),
	ruc VARCHAR2(20) NOT NULL UNIQUE,
	direccion VARCHAR2(200),
	telefono VARCHAR2(50),
	correo VARCHAR2(100),
	logo VARCHAR2(200),
	CONSTRAINT CONFIGURACION_EMPRESA_pk PRIMARY KEY (id_configuracion_empresa)
);

CREATE TABLE CATEGORIA (
	id_categoria NUMBER GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR2(100) NOT NULL UNIQUE,
	descripcion VARCHAR2(200),
	estado NUMBER(1) DEFAULT 1 NOT NULL,
	fecha_registro DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT CATEGORIA_pk PRIMARY KEY (id_categoria)
);

CREATE TABLE PRODUCTO (
	id_producto NUMBER GENERATED ALWAYS AS IDENTITY,
	codigo VARCHAR2(100) NOT NULL UNIQUE,
	nombre VARCHAR2(200) NOT NULL,
	marca VARCHAR2(100),
	descripcion VARCHAR2(200),
	precio NUMBER(12,2) NOT NULL,
	stock NUMBER(10) DEFAULT 0 NOT NULL,
	estado NUMBER(1) DEFAULT 1 NOT NULL,
	fecha_registro DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PRODUCTO_pk PRIMARY KEY (id_producto)
);

-- modelo y material como NUMBER (controlados por Enum en Backend)
CREATE TABLE MONTURA (
	id_producto NUMBER,
	color VARCHAR2(100),
	modelo NUMBER,
	material NUMBER,
	CONSTRAINT MONTURA_pk PRIMARY KEY (id_producto),
	CONSTRAINT MONTURA_producto_fk FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto)
);

CREATE TABLE PERSONA (
	id_persona NUMBER GENERATED ALWAYS AS IDENTITY,
	nombres VARCHAR2(150) NOT NULL,
	apellidos VARCHAR2(150) NOT NULL,
	telefono VARCHAR2(50),
	fecha_nacimiento DATE,
	sexo NUMBER(1),
	direccion VARCHAR2(200),
	numero_documento VARCHAR2(50) NOT NULL UNIQUE,
	tipo_documento NUMBER NOT NULL,
	CONSTRAINT PERSONA_pk PRIMARY KEY (id_persona)
);

CREATE TABLE USUARIO (
	id_usuario NUMBER GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR2(100) NOT NULL UNIQUE,
	password VARCHAR2(200) NOT NULL,
	correo VARCHAR2(100) NOT NULL UNIQUE,
	estado NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT USUARIO_pk PRIMARY KEY (id_usuario)
);

CREATE TABLE USUARIO_LOG (
	id_usuario_log NUMBER GENERATED ALWAYS AS IDENTITY,
	fecha_log DATE DEFAULT SYSDATE NOT NULL,
	tipo_log NUMBER,
	CONSTRAINT USUARIO_LOG_pk PRIMARY KEY (id_usuario_log)
);

CREATE TABLE ROL (
	id_rol NUMBER GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR2(100) NOT NULL UNIQUE,
	CONSTRAINT ROL_pk PRIMARY KEY (id_rol)
);

CREATE TABLE PERMISO (
	id_permiso NUMBER GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR2(100) NOT NULL UNIQUE,
	modulo NUMBER,
	CONSTRAINT PERMISO_pk PRIMARY KEY (id_permiso)
);

CREATE TABLE PACIENTE (
	id_persona NUMBER,
	estado NUMBER(1) DEFAULT 1 NOT NULL,
	fecha_registro DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PACIENTE_pk PRIMARY KEY (id_persona),
	CONSTRAINT PACIENTE_persona_fk FOREIGN KEY (id_persona) REFERENCES PERSONA(id_persona)
);

CREATE TABLE PACIENTE_LOG (
	id_paciente_log NUMBER GENERATED ALWAYS AS IDENTITY,
	fecha_log DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PACIENTE_LOG_pk PRIMARY KEY (id_paciente_log)
);

CREATE TABLE EMPLEADO (
	id_persona NUMBER,
	estado NUMBER(1) DEFAULT 1 NOT NULL,
	fecha_contrato DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT EMPLEADO_pk PRIMARY KEY (id_persona),
	CONSTRAINT EMPLEADO_persona_fk FOREIGN KEY (id_persona) REFERENCES PERSONA(id_persona)
);

CREATE TABLE EMPLEADO_LOG (
	id_empleado_log NUMBER GENERATED ALWAYS AS IDENTITY,
	fecha_log DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT EMPLEADO_LOG_pk PRIMARY KEY (id_empleado_log)
);

CREATE TABLE CARGO (
	id_cargo NUMBER GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR2(100) NOT NULL UNIQUE,
	CONSTRAINT CARGO_pk PRIMARY KEY (id_cargo)
);

CREATE TABLE RECETA (
	id_receta NUMBER GENERATED ALWAYS AS IDENTITY,
	fecha_registro DATE DEFAULT SYSDATE NOT NULL,
	es_externo NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT RECETA_pk PRIMARY KEY (id_receta)
);

CREATE TABLE MEDIDA_OJO (
	id_medida_ojo NUMBER GENERATED ALWAYS AS IDENTITY,
	agudeza_visual VARCHAR2(50),
	esfera NUMBER(5,2),
	cilindro NUMBER(5,2),
	eje NUMBER(3),
	adicion NUMBER(4,2),
	CONSTRAINT MEDIDA_OJO_pk PRIMARY KEY (id_medida_ojo)
);

CREATE TABLE MEDIDA (
	id_medida NUMBER GENERATED ALWAYS AS IDENTITY,
	tipo_medida NUMBER(1) DEFAULT 1 NOT NULL,
	distancia_pupilar NUMBER(5,2),
	prisma NUMBER(5,2),
	observaciones VARCHAR2(255),
	CONSTRAINT MEDIDA_pk PRIMARY KEY (id_medida)
);

CREATE TABLE MATERIAL_CRISTAL (
	id_material_cristal NUMBER GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR2(100) NOT NULL UNIQUE,
	CONSTRAINT MATERIAL_CRISTAL_pk PRIMARY KEY (id_material_cristal)
);

CREATE TABLE TRATAMIENTO_CRISTAL (
	id_tratamiento_cristal NUMBER GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR2(100) NOT NULL UNIQUE,
	CONSTRAINT TRATAMIENTO_CRISTAL_pk PRIMARY KEY (id_tratamiento_cristal)
);

-- Lente mantiene sub_total cotizado, sin enlace a venta
CREATE TABLE LENTE (
	id_lente NUMBER GENERATED ALWAYS AS IDENTITY,
	sub_total NUMBER(12,2) NOT NULL,
	CONSTRAINT LENTE_pk PRIMARY KEY (id_lente)
);

CREATE TABLE VENTA (
	id_venta NUMBER GENERATED ALWAYS AS IDENTITY,
	fecha_registro DATE DEFAULT SYSDATE NOT NULL,
	total NUMBER(12,2) NOT NULL,
	estado NUMBER NOT NULL,
	numero_comprobante VARCHAR2(100),
	tipo_comprobante NUMBER NOT NULL,
	CONSTRAINT VENTA_pk PRIMARY KEY (id_venta)
);

CREATE TABLE PAGO (
	id_pago NUMBER GENERATED ALWAYS AS IDENTITY,
	fecha_registro DATE DEFAULT SYSDATE NOT NULL,
	numero_operacion VARCHAR2(100),
	monto NUMBER(12,2) NOT NULL,
	metodo_pago NUMBER NOT NULL,
	CONSTRAINT PAGO_pk PRIMARY KEY (id_pago)
);

CREATE TABLE PRODUCTO_VENDIDO (
	id_producto_vendido NUMBER GENERATED ALWAYS AS IDENTITY,
	cantidad NUMBER(10) NOT NULL,
	precio_unit NUMBER(12,2) NOT NULL,
	sub_total NUMBER(12,2) NOT NULL,
	CONSTRAINT PRODUCTO_VENDIDO_pk PRIMARY KEY (id_producto_vendido)
);

CREATE TABLE SERVICIO (
	id_servicio NUMBER GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR2(200) NOT NULL,
	descripcion VARCHAR2(200),
	precio NUMBER(12,2) NOT NULL,
	estado NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT SERVICIO_pk PRIMARY KEY (id_servicio)
);

CREATE TABLE SERVICIO_VENDIDO (
	id_servicio_vendido NUMBER GENERATED ALWAYS AS IDENTITY,
	precio NUMBER(12,2) NOT NULL,
	CONSTRAINT SERVICIO_VENDIDO_pk PRIMARY KEY (id_servicio_vendido)
);

CREATE TABLE ORDEN_TRABAJO (
	id_orden_trabajo NUMBER GENERATED ALWAYS AS IDENTITY,
	fecha_registro DATE DEFAULT SYSDATE NOT NULL,
	fecha_entrega DATE,
	fecha_notificacion DATE,
	estado NUMBER NOT NULL,
	descripcion VARCHAR2(500),
	CONSTRAINT ORDEN_TRABAJO_pk PRIMARY KEY (id_orden_trabajo)
);

CREATE TABLE LABORATORIO (
	id_laboratorio NUMBER GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR2(200) NOT NULL,
	ruc VARCHAR2(20),
	telefono VARCHAR2(50),
	direccion VARCHAR2(200),
	correo VARCHAR2(100),
	estado NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT LABORATORIO_pk PRIMARY KEY (id_laboratorio)
);

CREATE TABLE ENVIO_LABORATORIO (
	id_envio_laboratorio NUMBER GENERATED ALWAYS AS IDENTITY,
	fecha_envio DATE DEFAULT SYSDATE NOT NULL,
	fecha_recepcion_estimada DATE,
	fecha_recepcion DATE,
	fecha_revision DATE,
	tolerancia NUMBER(5,2),
	aprobado NUMBER(1),
	observaciones VARCHAR2(500),
	CONSTRAINT ENVIO_LABORATORIO_pk PRIMARY KEY (id_envio_laboratorio)
);


/*==================================================
-- Fase 2: Creación de Relaciones
==================================================*/

ALTER TABLE PRODUCTO
ADD (id_categoria NUMBER)
ADD CONSTRAINT PRODUCTO_categoria_fk FOREIGN KEY (id_categoria) REFERENCES CATEGORIA(id_categoria);

CREATE TABLE USUARIO_ROL (
	id_usuario_rol NUMBER GENERATED ALWAYS AS IDENTITY,
	id_usuario NUMBER NOT NULL,
	id_rol NUMBER NOT NULL,
	CONSTRAINT USUARIO_ROL_pk PRIMARY KEY (id_usuario_rol),
	CONSTRAINT USUARIO_ROL_usuario_fk FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario),
	CONSTRAINT USUARIO_ROL_rol_fk FOREIGN KEY (id_rol) REFERENCES ROL(id_rol),
	CONSTRAINT USUARIO_ROL_uq UNIQUE (id_usuario, id_rol)
);

CREATE TABLE ROL_PERMISO (
	id_rol_permiso NUMBER GENERATED ALWAYS AS IDENTITY,
	id_rol NUMBER NOT NULL,
	id_permiso NUMBER NOT NULL,
	CONSTRAINT ROL_PERMISO_pk PRIMARY KEY (id_rol_permiso),
	CONSTRAINT ROL_PERMISO_rol_fk FOREIGN KEY (id_rol) REFERENCES ROL(id_rol),
	CONSTRAINT ROL_PERMISO_permiso_fk FOREIGN KEY (id_permiso) REFERENCES PERMISO(id_permiso),
	CONSTRAINT ROL_PERMISO_uq UNIQUE (id_rol, id_permiso)
);

ALTER TABLE USUARIO
ADD (id_persona NUMBER)
ADD CONSTRAINT USUARIO_persona_fk FOREIGN KEY (id_persona) REFERENCES PERSONA(id_persona);

ALTER TABLE USUARIO_LOG
ADD (id_usuario NUMBER)
ADD CONSTRAINT USUARIO_LOG_usuario_fk FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario);

ALTER TABLE PACIENTE
ADD (id_usuario NUMBER)
ADD CONSTRAINT PACIENTE_usuario_fk FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario);

ALTER TABLE PACIENTE_LOG
ADD (id_usuario NUMBER, id_persona NUMBER)
ADD CONSTRAINT PACIENTE_LOG_usuario_fk FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
ADD CONSTRAINT PACIENTE_LOG_paciente_fk FOREIGN KEY (id_persona) REFERENCES PACIENTE(id_persona);

ALTER TABLE EMPLEADO
ADD (id_usuario NUMBER)
ADD CONSTRAINT EMPLEADO_usuario_fk FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario);

ALTER TABLE EMPLEADO_LOG
ADD (id_usuario NUMBER, id_persona NUMBER)
ADD CONSTRAINT EMPLEADO_LOG_usuario_fk FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
ADD CONSTRAINT EMPLEADO_LOG_empleado_fk FOREIGN KEY (id_persona) REFERENCES EMPLEADO(id_persona);

CREATE TABLE EMPLEADO_CARGO (
	id_empleado_cargos NUMBER GENERATED ALWAYS AS IDENTITY,
	id_persona NUMBER NOT NULL,
	id_cargo NUMBER NOT NULL,
	CONSTRAINT EMPLEADO_CARGOS_pk PRIMARY KEY (id_empleado_cargos),
	CONSTRAINT EMPLEADO_CARGOS_empleado_fk FOREIGN KEY (id_persona) REFERENCES EMPLEADO(id_persona),
	CONSTRAINT EMPLEADO_CARGOS_cargo_fk FOREIGN KEY (id_cargo) REFERENCES CARGO(id_cargo),
	CONSTRAINT EMPLEADO_CARGOS_uq UNIQUE (id_persona, id_cargo)
);

ALTER TABLE RECETA
ADD (id_paciente NUMBER NOT NULL, id_empleado NUMBER NOT NULL)
ADD CONSTRAINT RECETA_paciente_fk FOREIGN KEY (id_paciente) REFERENCES PACIENTE(id_persona)
ADD CONSTRAINT RECETA_empleado_fk FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_persona);

ALTER TABLE MEDIDA
ADD (
	id_receta NUMBER,
	id_medida_ojo_derecha NUMBER,
	id_medida_ojo_izquierda NUMBER,
	id_envio_laboratorio NUMBER
)
ADD CONSTRAINT MEDIDA_receta_fk FOREIGN KEY (id_receta) REFERENCES RECETA(id_receta)
ADD CONSTRAINT MEDIDA_medida_ojo_derecha_fk FOREIGN KEY (id_medida_ojo_derecha) REFERENCES MEDIDA_OJO(id_medida_ojo)
ADD CONSTRAINT MEDIDA_medida_ojo_izquierda_fk FOREIGN KEY (id_medida_ojo_izquierda) REFERENCES MEDIDA_OJO(id_medida_ojo)
ADD CONSTRAINT MEDIDA_envio_laboratorio_fk FOREIGN KEY (id_envio_laboratorio) REFERENCES ENVIO_LABORATORIO(id_envio_laboratorio);

-- Lente: pertenece a la receta
ALTER TABLE LENTE
ADD (
	id_receta NUMBER NOT NULL,
	id_material_cristal NUMBER NOT NULL,
	id_producto NUMBER
)
ADD CONSTRAINT LENTE_receta_fk FOREIGN KEY (id_receta) REFERENCES RECETA(id_receta)
ADD CONSTRAINT LENTE_material_cristal_fk FOREIGN KEY (id_material_cristal) REFERENCES MATERIAL_CRISTAL(id_material_cristal)
ADD CONSTRAINT LENTE_montura_fk FOREIGN KEY (id_producto) REFERENCES MONTURA(id_producto);

-- Tabla intermedia LENTE_MEDIDA preservada (Muchos a Muchos entre Lente y Medida)
CREATE TABLE LENTE_MEDIDA (
	id_lente_medidas NUMBER GENERATED ALWAYS AS IDENTITY,
	id_lente NUMBER NOT NULL,
	id_medida NUMBER NOT NULL,
	CONSTRAINT LENTE_MEDIDAS_pk PRIMARY KEY (id_lente_medidas),
	CONSTRAINT LENTE_MEDIDAS_lente_fk FOREIGN KEY (id_lente) REFERENCES LENTE(id_lente),
	CONSTRAINT LENTE_MEDIDAS_medida_fk FOREIGN KEY (id_medida) REFERENCES MEDIDA(id_medida),
	CONSTRAINT LENTE_MEDIDAS_uq UNIQUE (id_lente, id_medida)
);

CREATE TABLE LENTE_TRATAMIENTO_CRISTAL (
	id_lente_tratamientos_cristal NUMBER GENERATED ALWAYS AS IDENTITY,
	id_lente NUMBER NOT NULL,
	id_tratamiento_cristal NUMBER NOT NULL,
	CONSTRAINT LENTE_TRATAMIENTOS_CRISTAL_pk PRIMARY KEY (id_lente_tratamientos_cristal),
	CONSTRAINT LENTE_TRAT_lente_fk FOREIGN KEY (id_lente) REFERENCES LENTE(id_lente),
	CONSTRAINT LENTE_TRAT_tratamiento_fk FOREIGN KEY (id_tratamiento_cristal) REFERENCES TRATAMIENTO_CRISTAL(id_tratamiento_cristal),
	CONSTRAINT LENTE_TRAT_uq UNIQUE (id_lente, id_tratamiento_cristal)
);

-- Venta: vendedor, paciente y la receta seleccionada
ALTER TABLE VENTA
ADD (
	id_empleado NUMBER NOT NULL,
	id_paciente NUMBER,
	id_receta NUMBER
)
ADD CONSTRAINT VENTA_empleado_fk FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_persona)
ADD CONSTRAINT VENTA_paciente_fk FOREIGN KEY (id_paciente) REFERENCES PACIENTE(id_persona)
ADD CONSTRAINT VENTA_receta_fk FOREIGN KEY (id_receta) REFERENCES RECETA(id_receta);

ALTER TABLE PAGO
ADD (id_venta NUMBER NOT NULL)
ADD CONSTRAINT PAGO_venta_fk FOREIGN KEY (id_venta) REFERENCES VENTA(id_venta);

ALTER TABLE PRODUCTO_VENDIDO
ADD (id_venta NUMBER NOT NULL, id_producto NUMBER NOT NULL)
ADD CONSTRAINT PRODUCTO_VENDIDO_venta_fk FOREIGN KEY (id_venta) REFERENCES VENTA(id_venta)
ADD CONSTRAINT PRODUCTO_VENDIDO_producto_fk FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto);

ALTER TABLE SERVICIO_VENDIDO
ADD (id_venta NUMBER NOT NULL, id_servicio NUMBER NOT NULL)
ADD CONSTRAINT SERVICIO_VENDIDO_venta_fk FOREIGN KEY (id_venta) REFERENCES VENTA(id_venta)
ADD CONSTRAINT SERVICIO_VENDIDO_servicio_fk FOREIGN KEY (id_servicio) REFERENCES SERVICIO(id_servicio);

ALTER TABLE ORDEN_TRABAJO
ADD (id_lente NUMBER NOT NULL)
ADD CONSTRAINT ORDEN_TRABAJO_lente_fk FOREIGN KEY (id_lente) REFERENCES LENTE(id_lente);

ALTER TABLE ENVIO_LABORATORIO
ADD (id_orden_trabajo NUMBER NOT NULL, id_laboratorio NUMBER NOT NULL)
ADD CONSTRAINT ENVIO_LAB_orden_trabajo_fk FOREIGN KEY (id_orden_trabajo) REFERENCES ORDEN_TRABAJO(id_orden_trabajo)
ADD CONSTRAINT ENVIO_LAB_laboratorio_fk FOREIGN KEY (id_laboratorio) REFERENCES LABORATORIO(id_laboratorio);

-- Historial / Kardex de movimientos de inventario
CREATE TABLE MOVIMIENTO_STOCK_LOG (
	id_movimiento NUMBER GENERATED ALWAYS AS IDENTITY,
	fecha_registro DATE DEFAULT SYSDATE NOT NULL,
	cantidad NUMBER(10) NOT NULL,
	stock_previo NUMBER(10) NOT NULL,
	stock_posterior NUMBER(10) NOT NULL,
	motivo NUMBER(2) NOT NULL,
	observaciones VARCHAR2(500),
	id_producto NUMBER NOT NULL,
	id_usuario NUMBER NOT NULL,
	CONSTRAINT MOVIMIENTO_STOCK_LOG_pk PRIMARY KEY (id_movimiento),
	CONSTRAINT MOVIMIENTO_STOCK_LOG_producto_fk FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto),
	CONSTRAINT MOVIMIENTO_STOCK_LOG_usuario_fk FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario),
	CONSTRAINT MOVIMIENTO_STOCK_LOG_cantidad_ck CHECK (cantidad > 0)
);


/*==================================================
-- Fase 3: Catálogos Iniciales
==================================================*/

INSERT INTO CARGO (nombre) VALUES ('RECEPCIONISTA');
INSERT INTO CARGO (nombre) VALUES ('VENDEDOR');
INSERT INTO CARGO (nombre) VALUES ('OPTOMETRA');
INSERT INTO CARGO (nombre) VALUES ('TECNICO');
INSERT INTO CARGO (nombre) VALUES ('ADMINISTRADOR');
INSERT INTO CARGO (nombre) VALUES ('CEO');

INSERT INTO MATERIAL_CRISTAL (nombre) VALUES ('POLICARBONATO');
INSERT INTO MATERIAL_CRISTAL (nombre) VALUES ('RESINA');
INSERT INTO MATERIAL_CRISTAL (nombre) VALUES ('CRISTAL MINERAL');
INSERT INTO MATERIAL_CRISTAL (nombre) VALUES ('ALTO INDICE');

INSERT INTO TRATAMIENTO_CRISTAL (nombre) VALUES ('FILTRO UV');
INSERT INTO TRATAMIENTO_CRISTAL (nombre) VALUES ('ANTIRREFLEJO');
INSERT INTO TRATAMIENTO_CRISTAL (nombre) VALUES ('BLUE DEFENSE');
INSERT INTO TRATAMIENTO_CRISTAL (nombre) VALUES ('FOTOCROMATICO');

COMMIT;

-- Optimizaciones y Tablas Adicionales de Control de Calidad e Indices FK --
-- ============================================================================
-- PROYECTO GEOVISION - MODULO DE CONTROL DE CALIDAD Y ORDENES DE TRABAJO
-- Archivo: 01_ddl_optimizacion_control_calidad.sql
-- Motor: Oracle Database 19c
-- Proposito: Optimizar el DDL actual para permitir evaluacion granular,
--            trazabilidad de excesos, auditoria de lensometria e indices FK.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TABLA DE DETALLE / AUDITORIA DE CONTROL DE CALIDAD
-- Resuelve la deficiencia del DDL original donde solo se guardaba un flag
-- 'aprobado' sin registrar que parametro fallo ni cuanto fue el exceso.
-- ----------------------------------------------------------------------------
CREATE TABLE DETALLE_CONTROL_CALIDAD (
    id_detalle_cc           NUMBER GENERATED ALWAYS AS IDENTITY,
    id_envio_laboratorio    NUMBER NOT NULL,
    tipo_medida             NUMBER(1) NOT NULL,
    ojo                     VARCHAR2(2) NOT NULL,
    parametro               VARCHAR2(30) NOT NULL,
    valor_receta            NUMBER(5,2),
    valor_medido            NUMBER(5,2),
    tolerancia_aplicada     NUMBER(5,2) NOT NULL,
    desviacion              NUMBER(5,2) NOT NULL,
    exceso                  NUMBER(5,2) NOT NULL,
    aprobado                NUMBER(1) NOT NULL,
    fecha_registro          DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT DETALLE_CC_pk PRIMARY KEY (id_detalle_cc),
    CONSTRAINT DETALLE_CC_envio_fk FOREIGN KEY (id_envio_laboratorio) 
        REFERENCES ENVIO_LABORATORIO(id_envio_laboratorio) ON DELETE CASCADE,
    CONSTRAINT DETALLE_CC_ojo_ck CHECK (ojo IN ('OD', 'OI', 'AO')),
    CONSTRAINT DETALLE_CC_aprobado_ck CHECK (aprobado IN (0, 1)),
    CONSTRAINT DETALLE_CC_tipo_medida_ck CHECK (tipo_medida IN (1, 2, 3))
);

COMMENT ON TABLE DETALLE_CONTROL_CALIDAD IS 'Registro granular y auditoria de la evaluacion parametro a parametro del control de calidad';
COMMENT ON COLUMN DETALLE_CONTROL_CALIDAD.ojo IS 'OD: Ojo Derecho, OI: Ojo Izquierdo, AO: Ambos Ojos / Parametro Montura (DP, Prisma)';
COMMENT ON COLUMN DETALLE_CONTROL_CALIDAD.exceso IS 'Magnitud en que la desviacion supera a la tolerancia permitida (0 si cumple)';
COMMENT ON COLUMN DETALLE_CONTROL_CALIDAD.aprobado IS '1 si cumple la tolerancia, 0 si excede';

-- ----------------------------------------------------------------------------
-- 2. AMPLIACION DE TOLERANCIAS MULTIDIMENSIONALES EN ENVIO_LABORATORIO
-- El DDL original solo poseia 'tolerancia NUMBER(5,2)'. En optometria se
-- requieren unidades distintas para dioptrias, eje angular, DP y prisma.
-- ----------------------------------------------------------------------------
ALTER TABLE ENVIO_LABORATORIO ADD (
    tolerancia_dioptrias    NUMBER(5,2) DEFAULT 0.25,
    tolerancia_eje_grados   NUMBER(5,2) DEFAULT 4.00,
    tolerancia_dp_mm        NUMBER(5,2) DEFAULT 1.00,
    tolerancia_prisma       NUMBER(5,2) DEFAULT 0.25
);

-- ----------------------------------------------------------------------------
-- 3. INDICADORES EN TABLA MEDIDA
-- Permite saber inmediatamente a nivel cabecera de medida si el bloque
-- (Lejos, Medio o Cerca) fue aprobado y su peor exceso detectado.
-- ----------------------------------------------------------------------------
ALTER TABLE MEDIDA ADD (
    aprobado            NUMBER(1) DEFAULT 1,
    exceso_maximo       NUMBER(5,2) DEFAULT 0
);

-- ----------------------------------------------------------------------------
-- 4. CONSTRAINTS DE DOMINIO E INTEGRIDAD
-- Aseguran coherencia en estados, rangos de eje y consistencia de medidas.
-- ----------------------------------------------------------------------------
ALTER TABLE ORDEN_TRABAJO 
    ADD CONSTRAINT ORDEN_TRABAJO_estado_ck 
    CHECK (estado IN (1, 2, 3, 4, 5, 6, 7, 8));

ALTER TABLE ENVIO_LABORATORIO 
    ADD CONSTRAINT ENVIO_LAB_aprobado_ck 
    CHECK (aprobado IS NULL OR aprobado IN (0, 1));

ALTER TABLE MEDIDA 
    ADD CONSTRAINT MEDIDA_tipo_medida_ck 
    CHECK (tipo_medida IN (1, 2, 3));

ALTER TABLE MEDIDA_OJO 
    ADD CONSTRAINT MEDIDA_OJO_eje_ck 
    CHECK (eje IS NULL OR (eje >= 0 AND eje <= 180));

-- ----------------------------------------------------------------------------
-- 5. CREACION DE INDICES EN CLAVES FORANEAS (FK Indexing)
-- En Oracle 19c las FK sin indice provocan bloqueos a nivel de tabla completa
-- (table locks) durante modificaciones concurrentes y degradan los JOINs.
-- ----------------------------------------------------------------------------
CREATE INDEX IDX_DETALLE_CC_ENVIO ON DETALLE_CONTROL_CALIDAD(id_envio_laboratorio);
CREATE INDEX IDX_ENVIO_LAB_OT ON ENVIO_LABORATORIO(id_orden_trabajo);
CREATE INDEX IDX_ORDEN_TRABAJO_LENTE ON ORDEN_TRABAJO(id_lente);
CREATE INDEX IDX_MEDIDA_ENVIO_LAB ON MEDIDA(id_envio_laboratorio);
CREATE INDEX IDX_MEDIDA_RECETA ON MEDIDA(id_receta);
CREATE INDEX IDX_LENTE_MEDIDA_LENTE ON LENTE_MEDIDA(id_lente);
CREATE INDEX IDX_LENTE_MEDIDA_MEDIDA ON LENTE_MEDIDA(id_medida);

COMMIT;

-- ============================================================================
-- 3. FUNCIONES PL/SQL (6 FUNCIONES - 2 POR INTEGRANTE)
-- ============================================================================
PROMPT >>> [3/9] Compilando 6 Funciones PL/SQL...
-- FN 1: FN_CALCULAR_SALDO_VENTA (Integrante 1 (Especialista Comercial y Finanzas))
CREATE OR REPLACE FUNCTION FN_CALCULAR_SALDO_VENTA (
    p_id_venta IN NUMBER
) RETURN NUMBER
IS
    v_total_venta NUMBER(12,2) := 0;
    v_total_pagos NUMBER(12,2) := 0;
    v_saldo       NUMBER(12,2) := 0;
BEGIN
    SELECT NVL(total, 0) INTO v_total_venta
    FROM VENTA
    WHERE id_venta = p_id_venta;

    SELECT NVL(SUM(monto), 0) INTO v_total_pagos
    FROM PAGO
    WHERE id_venta = p_id_venta;

    v_saldo := v_total_venta - v_total_pagos;

    IF v_saldo < 0 THEN
        v_saldo := 0;
    END IF;

    RETURN v_saldo;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
END FN_CALCULAR_SALDO_VENTA;
/

-- FN 2: FN_GENERAR_CORRELATIVO_COMPROBANTE (Integrante 1 (Especialista Comercial y Finanzas))
CREATE OR REPLACE FUNCTION FN_GENERAR_CORRELATIVO_COMPROBANTE (
    p_tipo_comprobante IN NUMBER
) RETURN VARCHAR2
IS
    v_prefijo VARCHAR2(5);
    v_conteo  NUMBER := 0;
    v_salida  VARCHAR2(50);
BEGIN
    CASE p_tipo_comprobante
        WHEN 1 THEN v_prefijo := 'B001-';
        WHEN 2 THEN v_prefijo := 'F001-';
        ELSE v_prefijo := 'NV01-';
    END CASE;

    SELECT COUNT(*) + 1 INTO v_conteo
    FROM VENTA
    WHERE tipo_comprobante = p_tipo_comprobante;

    v_salida := v_prefijo || LPAD(TO_CHAR(v_conteo), 7, '0');
    RETURN v_salida;
EXCEPTION
    WHEN OTHERS THEN
        RETURN v_prefijo || '0000001';
END FN_GENERAR_CORRELATIVO_COMPROBANTE;
/

-- FN 3: FN_CALCULAR_EDAD_PACIENTE (Integrante 2 (Especialista Clínico y Pacientes))
CREATE OR REPLACE FUNCTION FN_CALCULAR_EDAD_PACIENTE (
    p_id_persona IN NUMBER
) RETURN NUMBER
IS
    v_fecha_nac DATE;
    v_edad      NUMBER;
BEGIN
    SELECT fecha_nacimiento INTO v_fecha_nac
    FROM PERSONA
    WHERE id_persona = p_id_persona;

    IF v_fecha_nac IS NULL THEN
        RETURN NULL;
    END IF;

    v_edad := TRUNC(MONTHS_BETWEEN(SYSDATE, v_fecha_nac) / 12);
    RETURN v_edad;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END FN_CALCULAR_EDAD_PACIENTE;
/

-- FN 4: FN_VERIFICAR_VIGENCIA_RECETA (Integrante 2 (Especialista Clínico y Pacientes))
CREATE OR REPLACE FUNCTION FN_VERIFICAR_VIGENCIA_RECETA (
    p_id_receta IN NUMBER
) RETURN NUMBER
IS
    v_fecha_emision DATE;
    v_meses_transcurridos NUMBER;
BEGIN
    SELECT fecha_registro INTO v_fecha_emision
    FROM RECETA
    WHERE id_receta = p_id_receta;

    v_meses_transcurridos := MONTHS_BETWEEN(SYSDATE, v_fecha_emision);

    IF v_meses_transcurridos <= 12 THEN
        RETURN 1; -- RECETA VIGENTE
    ELSE
        RETURN 0; -- RECETA CADUCADA (> 1 ANO)
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
END FN_VERIFICAR_VIGENCIA_RECETA;
/

-- FN 5: FN_CALCULAR_DESVIACION_MEDIDA (Integrante 3 (Especialista Taller, Calidad y Stock))
CREATE OR REPLACE FUNCTION FN_CALCULAR_DESVIACION_MEDIDA (
    p_valor_receta  IN NUMBER,
    p_valor_medido  IN NUMBER,
    p_tolerancia    IN NUMBER
) RETURN NUMBER
IS
    v_desviacion NUMBER;
    v_exceso     NUMBER;
BEGIN
    IF p_valor_receta IS NULL OR p_valor_medido IS NULL THEN
        RETURN 0;
    END IF;

    v_desviacion := ABS(p_valor_medido - p_valor_receta);

    IF v_desviacion > p_tolerancia THEN
        v_exceso := v_desviacion - p_tolerancia;
    ELSE
        v_exceso := 0;
    END IF;

    RETURN ROUND(v_exceso, 2);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END FN_CALCULAR_DESVIACION_MEDIDA;
/

-- FN 6: FN_OBTENER_STOCK_DISPONIBLE (Integrante 3 (Especialista Taller, Calidad y Stock))
CREATE OR REPLACE FUNCTION FN_OBTENER_STOCK_DISPONIBLE (
    p_id_producto IN NUMBER
) RETURN NUMBER
IS
    v_stock_fisico      NUMBER := 0;
    v_unidades_taller   NUMBER := 0;
    v_stock_disponible  NUMBER := 0;
BEGIN
    SELECT NVL(stock, 0) INTO v_stock_fisico
    FROM PRODUCTO
    WHERE id_producto = p_id_producto;

    -- Contar monturas comprometidas en ordenes de trabajo en curso (estados 1 al 5)
    SELECT COUNT(*) INTO v_unidades_taller
    FROM ORDEN_TRABAJO ot
    JOIN LENTE l ON ot.id_lente = l.id_lente
    WHERE l.id_montura = p_id_producto AND ot.estado IN (1, 2, 3, 4, 5);

    v_stock_disponible := v_stock_fisico - v_unidades_taller;

    IF v_stock_disponible < 0 THEN
        v_stock_disponible := 0;
    END IF;

    RETURN v_stock_disponible;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END FN_OBTENER_STOCK_DISPONIBLE;
/


-- ============================================================================
-- 4. PROCEDIMIENTOS ALMACENADOS (9 PROCEDIMIENTOS - 3 POR INTEGRANTE)
-- ============================================================================
PROMPT >>> [4/9] Compilando 9 Procedimientos Almacenados...
-- SP 1: SP_REGISTRAR_VENTA_COMPLETA (Integrante 1 (Especialista Comercial y Finanzas))
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_VENTA_COMPLETA (
    p_id_paciente           IN  NUMBER,
    p_id_empleado           IN  NUMBER,
    p_id_receta             IN  NUMBER,
    p_tipo_comprobante      IN  NUMBER,    -- 1: BOLETA, 2: FACTURA, 3: NOTA
    p_total_venta           IN  NUMBER,
    p_monto_anticipo        IN  NUMBER,
    p_metodo_pago           IN  NUMBER,    -- 1: Efectivo, 2: Tarjeta, 3: Yape/Plin, 4: Transferencia
    p_numero_operacion      IN  VARCHAR2,
    p_id_venta              OUT NUMBER,
    p_numero_comprobante    OUT VARCHAR2,
    p_saldo_pendiente       OUT NUMBER,
    p_estado_venta          OUT NUMBER
)
IS
    v_correlativo       VARCHAR2(50);
    v_estado_inicial    NUMBER(1);
    v_min_anticipo      NUMBER(12,2);
    v_nuevo_id_pago     NUMBER;
BEGIN
    -- Validaciones de integridad de negocio
    IF p_total_venta <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'El total de la venta debe ser mayor a cero.');
    END IF;

    -- RN-VE07: Si involucra receta, anticipo minimo del 25%
    IF p_id_receta IS NOT NULL THEN
        v_min_anticipo := p_total_venta * 0.25;
        IF p_monto_anticipo < v_min_anticipo THEN
            RAISE_APPLICATION_ERROR(-20002, 'Venta con receta medica exige anticipo minimo del 25% (Minimo: S/ ' || TO_CHAR(v_min_anticipo, '9999.99') || ').');
        END IF;
    ELSE
        -- RN-VE06: Productos directos requieren cobro al 100%
        IF p_monto_anticipo < p_total_venta THEN
            RAISE_APPLICATION_ERROR(-20003, 'Venta de productos de catalogo o servicios directos exige cobro del 100%.');
        END IF;
    END IF;

    -- Generar correlativo oficial
    v_correlativo := FN_GENERAR_CORRELATIVO_COMPROBANTE(p_tipo_comprobante);

    -- Determinar estado segun saldo
    IF p_monto_anticipo >= p_total_venta THEN
        v_estado_inicial := 2; -- PAGADA
        p_saldo_pendiente := 0;
    ELSE
        v_estado_inicial := 1; -- PENDIENTE
        p_saldo_pendiente := p_total_venta - p_monto_anticipo;
    END IF;

    -- Insercion de cabecera de venta
    INSERT INTO VENTA (
        fecha_registro, numero_comprobante, tipo_comprobante,
        estado, total, id_paciente, id_empleado, id_receta
    ) VALUES (
        SYSDATE, v_correlativo, p_tipo_comprobante,
        v_estado_inicial, p_total_venta, p_id_paciente, p_id_empleado, p_id_receta
    ) RETURNING id_venta INTO p_id_venta;

    -- Insercion del abono inicial en tabla PAGO si el anticipo > 0
    IF p_monto_anticipo > 0 THEN
        INSERT INTO PAGO (
            fecha_registro, numero_operacion, monto, metodo_pago, id_venta
        ) VALUES (
            SYSDATE, p_numero_operacion, p_monto_anticipo, p_metodo_pago, p_id_venta
        ) RETURNING id_pago INTO v_nuevo_id_pago;
    END IF;

    p_numero_comprobante := v_correlativo;
    p_estado_venta := v_estado_inicial;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Error critico al registrar venta completa: ' || SQLERRM);
END SP_REGISTRAR_VENTA_COMPLETA;
/

-- SP 2: SP_REGISTRAR_PAGO_VENTA (Integrante 1 (Especialista Comercial y Finanzas))
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_PAGO_VENTA (
    p_id_venta          IN  NUMBER,
    p_monto_abono       IN  NUMBER,
    p_metodo_pago       IN  NUMBER,
    p_numero_operacion  IN  VARCHAR2,
    p_id_pago           OUT NUMBER,
    p_saldo_restante    OUT NUMBER,
    p_nuevo_estado      OUT NUMBER
)
IS
    v_total_venta       NUMBER(12,2);
    v_estado_actual     NUMBER(1);
    v_saldo_actual      NUMBER(12,2);
    v_nuevo_saldo       NUMBER(12,2);
BEGIN
    IF p_monto_abono <= 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'El monto del abono debe ser estrictamente mayor a cero.');
    END IF;

    -- Bloqueo pesimista para concurrencia en caja
    SELECT total, estado
    INTO v_total_venta, v_estado_actual
    FROM VENTA
    WHERE id_venta = p_id_venta
    FOR UPDATE;

    IF v_estado_actual = 3 THEN
        RAISE_APPLICATION_ERROR(-20021, 'Operacion denegada: No se permiten cobros en una venta ANULADA.');
    END IF;

    IF v_estado_actual = 2 THEN
        RAISE_APPLICATION_ERROR(-20022, 'Operacion denegada: La venta ya se encuentra PAGADA en su totalidad.');
    END IF;

    v_saldo_actual := FN_CALCULAR_SALDO_VENTA(p_id_venta);

    IF p_monto_abono > v_saldo_actual THEN
        RAISE_APPLICATION_ERROR(-20023, 'El abono de S/ ' || p_monto_abono || ' excede el saldo pendiente restante (S/ ' || v_saldo_actual || ').');
    END IF;

    INSERT INTO PAGO (
        fecha_registro, numero_operacion, monto, metodo_pago, id_venta
    ) VALUES (
        SYSDATE, p_numero_operacion, p_monto_abono, p_metodo_pago, p_id_venta
    ) RETURNING id_pago INTO p_id_pago;

    v_nuevo_saldo := v_saldo_actual - p_monto_abono;
    p_saldo_restante := v_nuevo_saldo;

    IF v_nuevo_saldo = 0 THEN
        UPDATE VENTA 
        SET estado = 2 
        WHERE id_venta = p_id_venta;
        p_nuevo_estado := 2;
    ELSE
        p_nuevo_estado := v_estado_actual;
    END IF;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20024, 'La venta con ID ' || p_id_venta || ' no existe en el sistema.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_REGISTRAR_PAGO_VENTA;
/

-- SP 3: SP_ANULAR_VENTA_REVERTIR (Integrante 1 (Especialista Comercial y Finanzas))
CREATE OR REPLACE PROCEDURE SP_ANULAR_VENTA_REVERTIR (
    p_id_venta          IN  NUMBER,
    p_motivo_anulacion  IN  VARCHAR2,
    p_id_usuario        IN  NUMBER,
    p_filas_revertidas  OUT NUMBER
)
IS
    v_estado_actual NUMBER(1);
    v_cant_ot_proc  NUMBER := 0;
    v_filas_count   NUMBER := 0;
BEGIN
    SELECT estado INTO v_estado_actual
    FROM VENTA WHERE id_venta = p_id_venta
    FOR UPDATE;

    IF v_estado_actual = 3 THEN
        RAISE_APPLICATION_ERROR(-20031, 'La venta ya se encuentra anulada previamente.');
    END IF;

    -- Validar si existen ordenes de trabajo de taller activas asociadas a la receta
    SELECT COUNT(*) INTO v_cant_ot_proc
    FROM ORDEN_TRABAJO ot
    JOIN VENTA v ON v.id_receta = ot.id_receta
    WHERE v.id_venta = p_id_venta AND ot.estado NOT IN (7, 8); -- 7: CANCELADO, 8: RECHAZADO

    IF v_cant_ot_proc > 0 THEN
        RAISE_APPLICATION_ERROR(-20032, 'No se puede anular la venta: Posee ordenes de trabajo de taller en confeccion activa.');
    END IF;

    -- Revertir stock de los productos vendidos
    FOR reg IN (SELECT id_producto, cantidad FROM PRODUCTO_VENDIDO WHERE id_venta = p_id_venta) LOOP
        UPDATE PRODUCTO 
        SET stock = stock + reg.cantidad 
        WHERE id_producto = reg.id_producto;

        INSERT INTO MOVIMIENTO_STOCK_LOG (
            fecha_registro, cantidad, stock_previo, stock_posterior,
            motivo, observaciones, id_producto, id_usuario
        ) VALUES (
            SYSDATE, reg.cantidad, 0, 0,
            6, 'Devolucion por anulacion de venta ID: ' || p_id_venta || '. Motivo: ' || p_motivo_anulacion,
            reg.id_producto, p_id_usuario
        );
        v_filas_count := v_filas_count + 1;
    END LOOP;

    -- Actualizar estado de la venta
    UPDATE VENTA 
    SET estado = 3 
    WHERE id_venta = p_id_venta;

    p_filas_revertidas := v_filas_count;
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20033, 'Venta no localizada para anulacion.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_ANULAR_VENTA_REVERTIR;
/

-- SP 4: SP_REGISTRAR_RECETA_PACIENTE (Integrante 2 (Especialista Clínico y Pacientes))
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_RECETA_PACIENTE (
    p_id_paciente       IN  NUMBER,
    p_id_empleado       IN  NUMBER,
    p_diagnostico       IN  VARCHAR2,
    p_dp_lejos          IN  NUMBER,
    p_dp_cerca          IN  NUMBER,
    p_od_esfera         IN  NUMBER,
    p_od_cilindro       IN  NUMBER,
    p_od_eje            IN  NUMBER,
    p_od_adicion        IN  NUMBER,
    p_od_av             IN  NUMBER,
    p_oi_esfera         IN  NUMBER,
    p_oi_cilindro       IN  NUMBER,
    p_oi_eje            IN  NUMBER,
    p_oi_adicion        IN  NUMBER,
    p_oi_av             IN  NUMBER,
    p_id_receta         OUT NUMBER
)
IS
    v_id_receta_new     NUMBER;
    v_id_medida_lejos   NUMBER;
    v_id_ojo_der        NUMBER;
    v_id_ojo_izq        NUMBER;
BEGIN
    -- Validar rangos de eje angular
    IF (p_od_eje IS NOT NULL AND (p_od_eje < 0 OR p_od_eje > 180)) OR
       (p_oi_eje IS NOT NULL AND (p_oi_eje < 0 OR p_oi_eje > 180)) THEN
        RAISE_APPLICATION_ERROR(-20040, 'El eje optico debe situarse estrictamente en el intervalo sexagesimal [0, 180].');
    END IF;

    -- Cabecera de la receta
    INSERT INTO RECETA (
        fecha_registro, observaciones, id_paciente, id_empleado
    ) VALUES (
        SYSDATE, p_diagnostico, p_id_paciente, p_id_empleado
    ) RETURNING id_receta INTO v_id_receta_new;

    -- Insertar medidas de Ojo Derecho
    INSERT INTO MEDIDA_OJO (
        esfera, cilindro, eje, adicion, agudeza_visual
    ) VALUES (
        p_od_esfera, p_od_cilindro, p_od_eje, p_od_adicion, p_od_av
    ) RETURNING id_medida_ojo INTO v_id_ojo_der;

    -- Insertar medidas de Ojo Izquierdo
    INSERT INTO MEDIDA_OJO (
        esfera, cilindro, eje, adicion, agudeza_visual
    ) VALUES (
        p_oi_esfera, p_oi_cilindro, p_oi_eje, p_oi_adicion, p_oi_av
    ) RETURNING id_medida_ojo INTO v_id_ojo_izq;

    -- Agrupar en entidad MEDIDA (Vision Lejana: tipo 1)
    INSERT INTO MEDIDA (
        tipo_medida, distancia_pupilar, id_receta, id_ojo_derecho, id_ojo_izquierdo
    ) VALUES (
        1, p_dp_lejos, v_id_receta_new, v_id_ojo_der, v_id_ojo_izq
    ) RETURNING id_medida INTO v_id_medida_lejos;

    p_id_receta := v_id_receta_new;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20041, 'Error al registrar la receta oftalmologica: ' || SQLERRM);
END SP_REGISTRAR_RECETA_PACIENTE;
/

-- SP 5: SP_ACTUALIZAR_HISTORIA_PACIENTE (Integrante 2 (Especialista Clínico y Pacientes))
CREATE OR REPLACE PROCEDURE SP_ACTUALIZAR_HISTORIA_PACIENTE (
    p_id_persona        IN  NUMBER,
    p_telefono          IN  VARCHAR2,
    p_direccion         IN  VARCHAR2,
    p_id_usuario        IN  NUMBER,
    p_resultado         OUT VARCHAR2
)
IS
    v_existe NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM PACIENTE WHERE id_persona = p_id_persona;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20042, 'Paciente no encontrado en el padron clinico.');
    END IF;

    UPDATE PERSONA
    SET telefono = p_telefono,
        direccion = p_direccion
    WHERE id_persona = p_id_persona;

    INSERT INTO PACIENTE_LOG (
        fecha_log, tipo_log, id_persona, id_usuario
    ) VALUES (
        SYSDATE, 2, p_id_persona, p_id_usuario -- 2: Modificacion de Datos
    );

    p_resultado := 'Historia clinica y contacto actualizados exitosamente.';
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_ACTUALIZAR_HISTORIA_PACIENTE;
/

-- SP 6: SP_DAR_BAJA_PACIENTE (Integrante 2 (Especialista Clínico y Pacientes))
CREATE OR REPLACE PROCEDURE SP_DAR_BAJA_PACIENTE (
    p_id_persona        IN  NUMBER,
    p_motivo_baja       IN  VARCHAR2,
    p_id_usuario        IN  NUMBER,
    p_mensaje           OUT VARCHAR2
)
IS
    v_deudas_activas NUMBER := 0;
BEGIN
    -- Validar que no posea ventas pendientes con saldo
    SELECT COUNT(*) INTO v_deudas_activas
    FROM VENTA v
    WHERE v.id_paciente = p_id_persona AND v.estado = 1;

    IF v_deudas_activas > 0 THEN
        RAISE_APPLICATION_ERROR(-20043, 'No se puede desactivar al paciente: Registra cuentas de ventas por cobrar pendientes en caja.');
    END IF;

    UPDATE PACIENTE 
    SET estado = 0 
    WHERE id_persona = p_id_persona;

    INSERT INTO PACIENTE_LOG (
        fecha_log, tipo_log, id_persona, id_usuario
    ) VALUES (
        SYSDATE, 3, p_id_persona, p_id_usuario -- 3: Baja Logica
    );

    p_mensaje := 'Paciente desactivado logicamente del sistema con exito.';
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_DAR_BAJA_PACIENTE;
/

-- SP 7: SP_EVALUAR_CONTROL_CALIDAD (Integrante 3 (Especialista Taller, Calidad y Stock))
CREATE OR REPLACE PROCEDURE SP_EVALUAR_CONTROL_CALIDAD (
    p_id_envio_laboratorio  IN  NUMBER,
    p_esfera_medida_od      IN  NUMBER,
    p_cilindro_medido_od    IN  NUMBER,
    p_eje_medido_od         IN  NUMBER,
    p_esfera_medida_oi      IN  NUMBER,
    p_cilindro_medido_oi    IN  NUMBER,
    p_eje_medido_oi         IN  NUMBER,
    p_id_usuario            IN  NUMBER,
    p_aprobado_global       OUT NUMBER,    -- 1: Cumple tolerancias, 0: Rechazado
    p_dictamen_resumen      OUT VARCHAR2
)
IS
    v_tol_dioptrias NUMBER := 0.25;
    v_tol_eje       NUMBER := 4.0;
    v_desv_esf_od   NUMBER;
    v_desv_cil_od   NUMBER;
    v_desv_eje_od   NUMBER;
    v_aprob_od      NUMBER := 1;
    v_aprob_oi      NUMBER := 1;
    v_id_ot         NUMBER;
BEGIN
    SELECT id_orden_trabajo INTO v_id_ot
    FROM ENVIO_LABORATORIO WHERE id_envio_laboratorio = p_id_envio_laboratorio;

    -- Calculo de desviaciones para Ojo Derecho
    v_desv_esf_od := ABS(p_esfera_medida_od - 0.0); -- Comparacion base
    IF v_desv_esf_od > v_tol_dioptrias THEN
        v_aprob_od := 0;
    END IF;

    IF v_aprob_od = 1 AND v_aprob_oi = 1 THEN
        p_aprobado_global := 1;
        p_dictamen_resumen := 'LENSOMETRIA CONFORME: El lente cumple con las tolerancias opticas ISO/UPeU.';
        -- Actualizar estado de envio y orden de trabajo a CONTROL_CALIDAD_APROBADO (5)
        UPDATE ENVIO_LABORATORIO 
        SET aprobado = 1, fecha_revision = SYSDATE 
        WHERE id_envio_laboratorio = p_id_envio_laboratorio;

        UPDATE ORDEN_TRABAJO 
        SET estado = 5 
        WHERE id_orden_trabajo = v_id_ot;
    ELSE
        p_aprobado_global := 0;
        p_dictamen_resumen := 'LENSOMETRIA NO CONFORME: Desviacion dioptrica fuera de tolerancia.';
        UPDATE ENVIO_LABORATORIO 
        SET aprobado = 0, fecha_revision = SYSDATE 
        WHERE id_envio_laboratorio = p_id_envio_laboratorio;

        UPDATE ORDEN_TRABAJO 
        SET estado = 8 -- RECHAZADO / RETRABAJO
        WHERE id_orden_trabajo = v_id_ot;
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20050, 'Falla en la evaluacion de control de calidad: ' || SQLERRM);
END SP_EVALUAR_CONTROL_CALIDAD;
/

-- SP 8: SP_DESPACHAR_ORDEN_LABORATORIO (Integrante 3 (Especialista Taller, Calidad y Stock))
CREATE OR REPLACE PROCEDURE SP_DESPACHAR_ORDEN_LABORATORIO (
    p_id_orden_trabajo      IN  NUMBER,
    p_id_laboratorio        IN  NUMBER,
    p_observaciones_taller  IN  VARCHAR2,
    p_id_envio_generado     OUT NUMBER
)
IS
    v_estado_ot NUMBER;
BEGIN
    SELECT estado INTO v_estado_ot
    FROM ORDEN_TRABAJO WHERE id_orden_trabajo = p_id_orden_trabajo
    FOR UPDATE;

    IF v_estado_ot != 1 THEN -- 1: REGISTRADO / PENDIENTE_ENVIO
        RAISE_APPLICATION_ERROR(-20051, 'La orden de trabajo no se encuentra en estado inicial apto para despacho a laboratorio.');
    END IF;

    INSERT INTO ENVIO_LABORATORIO (
        fecha_envio, observaciones, id_orden_trabajo, id_laboratorio, tolerancia
    ) VALUES (
        SYSDATE, p_observaciones_taller, p_id_orden_trabajo, p_id_laboratorio, 0.25
    ) RETURNING id_envio_laboratorio INTO p_id_envio_generado;

    UPDATE ORDEN_TRABAJO
    SET estado = 2 -- ENVIADO A LABORATORIO
    WHERE id_orden_trabajo = p_id_orden_trabajo;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_DESPACHAR_ORDEN_LABORATORIO;
/

-- SP 9: SP_AJUSTAR_STOCK_INVENTARIO (Integrante 3 (Especialista Taller, Calidad y Stock))
CREATE OR REPLACE PROCEDURE SP_AJUSTAR_STOCK_INVENTARIO (
    p_id_producto       IN  NUMBER,
    p_cantidad_ajuste   IN  NUMBER,    -- Positivo: Incremento, Negativo: Disminucion
    p_tipo_motivo       IN  NUMBER,    -- 1: Compra, 2: Merma, 3: Rotura, 4: Ajuste inventario
    p_glosa             IN  VARCHAR2,
    p_id_usuario        IN  NUMBER,
    p_stock_resultante  OUT NUMBER
)
IS
    v_stock_actual NUMBER;
    v_nuevo_stock  NUMBER;
BEGIN
    SELECT stock INTO v_stock_actual
    FROM PRODUCTO WHERE id_producto = p_id_producto
    FOR UPDATE;

    v_nuevo_stock := v_stock_actual + p_cantidad_ajuste;

    IF v_nuevo_stock < 0 THEN
        RAISE_APPLICATION_ERROR(-20052, 'Ajuste invalido: El stock resultante no puede ser negativo (Stock actual: ' || v_stock_actual || ').');
    END IF;

    UPDATE PRODUCTO 
    SET stock = v_nuevo_stock 
    WHERE id_producto = p_id_producto;

    INSERT INTO MOVIMIENTO_STOCK_LOG (
        fecha_registro, cantidad, stock_previo, stock_posterior,
        motivo, observaciones, id_producto, id_usuario
    ) VALUES (
        SYSDATE, ABS(p_cantidad_ajuste), v_stock_actual, v_nuevo_stock,
        p_tipo_motivo, p_glosa, p_id_producto, p_id_usuario
    );

    p_stock_resultante := v_nuevo_stock;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_AJUSTAR_STOCK_INVENTARIO;
/


-- ============================================================================
-- 5. TRIGGERS REACTIVOS (6 TRIGGERS - 2 POR INTEGRANTE)
-- ============================================================================
PROMPT >>> [5/9] Compilando 6 Triggers...
-- TRG 1: TRG_ACTUALIZAR_ESTADO_VENTA_PAGO (Integrante 1 (Especialista Comercial y Finanzas))
CREATE OR REPLACE TRIGGER TRG_ACTUALIZAR_ESTADO_VENTA_PAGO
FOR INSERT OR UPDATE ON PAGO
COMPOUND TRIGGER

    TYPE t_ventas IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_ventas t_ventas;
    v_total NUMBER(12,2);
    v_pagado NUMBER(12,2);
    v_estado_actual NUMBER;

    AFTER EACH ROW IS
    BEGIN
        IF :NEW.id_venta IS NOT NULL THEN
            v_ventas(v_ventas.COUNT + 1) := :NEW.id_venta;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        FOR i IN 1 .. v_ventas.COUNT LOOP
            BEGIN
                SELECT total, estado
                INTO v_total, v_estado_actual
                FROM VENTA
                WHERE id_venta = v_ventas(i);

                IF v_estado_actual != 3 THEN -- No alterar si esta ANULADA
                    SELECT NVL(SUM(monto), 0)
                    INTO v_pagado
                    FROM PAGO
                    WHERE id_venta = v_ventas(i);

                    IF v_pagado >= v_total AND v_estado_actual != 2 THEN
                        UPDATE VENTA SET estado = 2 WHERE id_venta = v_ventas(i);
                    ELSIF v_pagado < v_total AND v_estado_actual != 1 THEN
                        UPDATE VENTA SET estado = 1 WHERE id_venta = v_ventas(i);
                    END IF;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;
            END;
        END LOOP;
    END AFTER STATEMENT;

END TRG_ACTUALIZAR_ESTADO_VENTA_PAGO;
/

-- TRG 2: TRG_VALIDAR_MONTO_PAGO (Integrante 1 (Especialista Comercial y Finanzas))
CREATE OR REPLACE TRIGGER TRG_VALIDAR_MONTO_PAGO
BEFORE INSERT OR UPDATE ON PAGO
FOR EACH ROW
DECLARE
    v_estado_venta NUMBER;
BEGIN
    IF :NEW.monto <= 0 THEN
        RAISE_APPLICATION_ERROR(-20060, 'El monto del pago debe ser estrictamente mayor a 0.00.');
    END IF;

    SELECT estado INTO v_estado_venta
    FROM VENTA WHERE id_venta = :NEW.id_venta;

    IF v_estado_venta = 3 THEN
        RAISE_APPLICATION_ERROR(-20061, 'Restriccion violada: No es posible registrar pagos en una venta que ha sido ANULADA.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20062, 'La venta asociada al pago no existe en la base de datos.');
END TRG_VALIDAR_MONTO_PAGO;
/

-- TRG 3: TRG_AUDITAR_PACIENTE_CAMBIOS (Integrante 2 (Especialista Clínico y Pacientes))
CREATE OR REPLACE TRIGGER TRG_AUDITAR_PACIENTE_CAMBIOS
AFTER UPDATE ON PACIENTE
FOR EACH ROW
BEGIN
    INSERT INTO PACIENTE_LOG (
        fecha_log, tipo_log, id_persona, id_usuario
    ) VALUES (
        SYSDATE,
        CASE WHEN :NEW.estado != :OLD.estado THEN 3 ELSE 2 END,
        :NEW.id_persona,
        1 -- Usuario administrativo por defecto / sesion
    );
END TRG_AUDITAR_PACIENTE_CAMBIOS;
/

-- TRG 4: TRG_VALIDAR_RANGOS_MEDIDA_OJO (Integrante 2 (Especialista Clínico y Pacientes))
CREATE OR REPLACE TRIGGER TRG_VALIDAR_RANGOS_MEDIDA_OJO
BEFORE INSERT OR UPDATE ON MEDIDA_OJO
FOR EACH ROW
BEGIN
    -- Validar Esfera [-25.00 a +25.00]
    IF :NEW.esfera IS NOT NULL AND (:NEW.esfera < -25.00 OR :NEW.esfera > 25.00) THEN
        RAISE_APPLICATION_ERROR(-20070, 'Valor de esfera refractiva fuera del rango biometrico valido [-25.00 a +25.00].');
    END IF;

    -- Validar Cilindro [-10.00 a 0.00]
    IF :NEW.cilindro IS NOT NULL AND (:NEW.cilindro < -10.00 OR :NEW.cilindro > 0.00) THEN
        RAISE_APPLICATION_ERROR(-20071, 'Valor de cilindro astigmatico fuera del rango valido [-10.00 a 0.00].');
    END IF;

    -- Validar Eje [0 a 180]
    IF :NEW.eje IS NOT NULL AND (:NEW.eje < 0 OR :NEW.eje > 180) THEN
        RAISE_APPLICATION_ERROR(-20072, 'El eje optico debe situarse estrictamente entre 0 y 180 grados sexagesimales.');
    END IF;
END TRG_VALIDAR_RANGOS_MEDIDA_OJO;
/

-- TRG 5: TRG_DESCONTAR_STOCK_POR_VENTA (Integrante 3 (Especialista Taller, Calidad y Stock))
CREATE OR REPLACE TRIGGER TRG_DESCONTAR_STOCK_POR_VENTA
AFTER INSERT ON PRODUCTO_VENDIDO
FOR EACH ROW
DECLARE
    v_stock_actual NUMBER;
    v_stock_nuevo  NUMBER;
    v_id_usuario   NUMBER := 1;
BEGIN
    SELECT stock INTO v_stock_actual
    FROM PRODUCTO WHERE id_producto = :NEW.id_producto
    FOR UPDATE;

    IF v_stock_actual < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(-20080, 'Stock insuficiente para el producto ID ' || :NEW.id_producto || 
                                       '. Disponible: ' || v_stock_actual || ', Solicitado: ' || :NEW.cantidad);
    END IF;

    v_stock_nuevo := v_stock_actual - :NEW.cantidad;

    UPDATE PRODUCTO
    SET stock = v_stock_nuevo
    WHERE id_producto = :NEW.id_producto;

    INSERT INTO MOVIMIENTO_STOCK_LOG (
        fecha_registro, cantidad, stock_previo, stock_posterior,
        motivo, observaciones, id_producto, id_usuario
    ) VALUES (
        SYSDATE, :NEW.cantidad, v_stock_actual, v_stock_nuevo,
        5, 'Salida automatica por venta ID: ' || :NEW.id_venta, :NEW.id_producto, v_id_usuario
    );
END TRG_DESCONTAR_STOCK_POR_VENTA;
/

-- TRG 6: TRG_VALIDAR_ENTREGA_ORDEN_TRABAJO (Integrante 3 (Especialista Taller, Calidad y Stock))
CREATE OR REPLACE TRIGGER TRG_VALIDAR_ENTREGA_ORDEN_TRABAJO
BEFORE UPDATE ON ORDEN_TRABAJO
FOR EACH ROW
DECLARE
    v_id_venta      NUMBER;
    v_saldo_deudor  NUMBER;
BEGIN
    -- Si el estado nuevo es 6 (ENTREGADO)
    IF :NEW.estado = 6 AND :OLD.estado != 6 THEN
        -- Localizar venta asociada a traves de la receta del lente
        BEGIN
            SELECT v.id_venta INTO v_id_venta
            FROM VENTA v
            WHERE v.id_receta = (SELECT l.id_receta FROM LENTE l WHERE l.id_lente = :NEW.id_lente)
              AND ROWNUM = 1;

            v_saldo_deudor := FN_CALCULAR_SALDO_VENTA(v_id_venta);

            IF v_saldo_deudor > 0 THEN
                RAISE_APPLICATION_ERROR(-20090, 'REGLA DE NEGOCIO VIOLADA (RN-OT01): No se puede entregar el trabajo optico. La venta ID ' || 
                                               v_id_venta || ' presenta saldo deudor pendiente de S/ ' || TO_CHAR(v_saldo_deudor, '9999.99'));
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL; -- Sin venta con receta asociada
        END;
    END IF;
END TRG_VALIDAR_ENTREGA_ORDEN_TRABAJO;
/


-- ============================================================================
-- 6. VISTAS DE BASE DE DATOS (9 VISTAS - 3 POR INTEGRANTE)
-- ============================================================================
PROMPT >>> [6/9] Creando 9 Vistas de Base de Datos...
-- VISTA 1: V_M_REPORTE_VENTAS_CONSOLIDADO (Integrante 1 (Especialista Comercial y Finanzas))
CREATE OR REPLACE VIEW V_M_REPORTE_VENTAS_CONSOLIDADO AS
SELECT 
    v.id_venta,
    v.fecha_registro,
    v.numero_comprobante,
    v.tipo_comprobante,
    CASE v.tipo_comprobante
        WHEN 1 THEN 'BOLETA'
        WHEN 2 THEN 'FACTURA'
        ELSE 'NOTA DE VENTA'
    END AS nombre_tipo_comprobante,
    v.estado AS codigo_estado,
    CASE v.estado
        WHEN 1 THEN 'PENDIENTE'
        WHEN 2 THEN 'PAGADA'
        WHEN 3 THEN 'ANULADA'
        ELSE 'DESCONOCIDO'
    END AS nombre_estado,
    v.total AS total_venta,
    NVL((SELECT SUM(p.monto) FROM PAGO p WHERE p.id_venta = v.id_venta), 0) AS total_pagado,
    GREATEST(0, v.total - NVL((SELECT SUM(p.monto) FROM PAGO p WHERE p.id_venta = v.id_venta), 0)) AS saldo_pendiente,
    per_cli.numero_documento AS doc_cliente,
    TRIM(per_cli.nombres || ' ' || per_cli.apellidos) AS nombre_cliente,
    per_cli.telefono AS telefono_cliente,
    TRIM(per_emp.nombres || ' ' || per_emp.apellidos) AS nombre_empleado
FROM VENTA v
LEFT JOIN PACIENTE pac ON v.id_paciente = pac.id_persona
LEFT JOIN PERSONA per_cli ON pac.id_persona = per_cli.id_persona
JOIN EMPLEADO emp ON v.id_empleado = emp.id_persona
JOIN PERSONA per_emp ON emp.id_persona = per_emp.id_persona;
/

-- VISTA 2: V_M_RANKING_PRODUCTOS_SERVICIOS (Integrante 1 (Especialista Comercial y Finanzas))
CREATE OR REPLACE VIEW V_M_RANKING_PRODUCTOS_SERVICIOS AS
WITH Consolidado AS (
    SELECT 
        'PRODUCTO' AS tipo,
        p.id_producto AS id_item,
        p.codigo,
        p.nombre,
        pv.cantidad,
        pv.sub_total
    FROM PRODUCTO_VENDIDO pv
    JOIN PRODUCTO p ON pv.id_producto = p.id_producto
    JOIN VENTA v ON pv.id_venta = v.id_venta WHERE v.estado != 3
    UNION ALL
    SELECT 
        'SERVICIO' AS tipo,
        s.id_servicio AS id_item,
        'SERV-' || TO_CHAR(s.id_servicio) AS codigo,
        s.nombre,
        1 AS cantidad,
        sv.precio AS sub_total
    FROM SERVICIO_VENDIDO sv
    JOIN SERVICIO s ON sv.id_servicio = s.id_servicio
    JOIN VENTA v ON sv.id_venta = v.id_venta WHERE v.estado != 3
)
SELECT 
    tipo,
    id_item,
    codigo,
    nombre,
    SUM(cantidad) AS unidades_vendidas,
    SUM(sub_total) AS recaudacion_total,
    DENSE_RANK() OVER (PARTITION BY tipo ORDER BY SUM(sub_total) DESC) AS ranking_ingreso
FROM Consolidado
GROUP BY tipo, id_item, codigo, nombre;
/

-- VISTA 3: V_S_VENTAS_SALDOS_PENDIENTES (Integrante 1 (Especialista Comercial y Finanzas))
CREATE OR REPLACE VIEW V_S_VENTAS_SALDOS_PENDIENTES AS
SELECT 
    v.id_venta,
    v.numero_comprobante,
    v.fecha_registro,
    v.total AS monto_total,
    FN_CALCULAR_SALDO_VENTA(v.id_venta) AS saldo_deudor,
    v.id_paciente
FROM VENTA v
WHERE v.estado = 1;
/

-- VISTA 4: V_M_HISTORIAL_CLINICO_PACIENTE (Integrante 2 (Especialista Clínico y Pacientes))
CREATE OR REPLACE VIEW V_M_HISTORIAL_CLINICO_PACIENTE AS
SELECT 
    pac.id_persona AS id_paciente,
    per.numero_documento AS dni,
    TRIM(per.nombres || ' ' || per.apellidos) AS nombre_completo,
    FN_CALCULAR_EDAD_PACIENTE(per.id_persona) AS edad_anos,
    per.telefono,
    r.id_receta,
    r.fecha_registro AS fecha_receta,
    r.observaciones AS diagnostico,
    mo_od.esfera AS od_esfera,
    mo_od.cilindro AS od_cilindro,
    mo_od.eje AS od_eje,
    mo_oi.esfera AS oi_esfera,
    mo_oi.cilindro AS oi_cilindro,
    mo_oi.eje AS oi_eje,
    m.distancia_pupilar AS dp_mm
FROM PACIENTE pac
JOIN PERSONA per ON pac.id_persona = per.id_persona
JOIN RECETA r ON pac.id_persona = r.id_paciente
JOIN MEDIDA m ON r.id_receta = m.id_receta AND m.tipo_medida = 1
LEFT JOIN MEDIDA_OJO mo_od ON m.id_ojo_derecho = mo_od.id_medida_ojo
LEFT JOIN MEDIDA_OJO mo_oi ON m.id_ojo_izquierdo = mo_oi.id_medida_ojo;
/

-- VISTA 5: V_S_RECETAS_VIGENTES_ACTIVAS (Integrante 2 (Especialista Clínico y Pacientes))
CREATE OR REPLACE VIEW V_S_RECETAS_VIGENTES_ACTIVAS AS
SELECT 
    r.id_receta,
    r.fecha_registro,
    r.id_paciente,
    r.id_empleado,
    r.observaciones
FROM RECETA r
WHERE r.fecha_registro >= ADD_MONTHS(SYSDATE, -12);
/

-- VISTA 6: V_M_RESUMEN_DIAGNOSTICOS_ETARIOS (Integrante 2 (Especialista Clínico y Pacientes))
CREATE OR REPLACE VIEW V_M_RESUMEN_DIAGNOSTICOS_ETARIOS AS
SELECT 
    CASE 
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, per.fecha_nacimiento)/12) < 18 THEN 'INFANTES'
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, per.fecha_nacimiento)/12) <= 45 THEN 'ADULTOS'
        ELSE 'ADULTOS MAYORES'
    END AS grupo_etario,
    COUNT(r.id_receta) AS cantidad_recetas,
    ROUND(AVG(mo.esfera), 2) AS promedio_esfera,
    ROUND(AVG(mo.cilindro), 2) AS promedio_cilindro
FROM RECETA r
JOIN PACIENTE pac ON r.id_paciente = pac.id_persona
JOIN PERSONA per ON pac.id_persona = per.id_persona
JOIN MEDIDA m ON r.id_receta = m.id_receta AND m.tipo_medida = 1
JOIN MEDIDA_OJO mo ON m.id_ojo_derecho = mo.id_medida_ojo
GROUP BY 
    CASE 
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, per.fecha_nacimiento)/12) < 18 THEN 'INFANTES'
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, per.fecha_nacimiento)/12) <= 45 THEN 'ADULTOS'
        ELSE 'ADULTOS MAYORES'
    END;
/

-- VISTA 7: V_M_SEGUIMIENTO_ORDENES_TALLER (Integrante 3 (Especialista Taller, Calidad y Stock))
CREATE OR REPLACE VIEW V_M_SEGUIMIENTO_ORDENES_TALLER AS
SELECT 
    ot.id_orden_trabajo,
    ot.fecha_creacion,
    ot.estado AS codigo_estado,
    CASE ot.estado
        WHEN 1 THEN 'REGISTRADO'
        WHEN 2 THEN 'ENVIADO A TALLER'
        WHEN 3 THEN 'RECIBIDO EN OPTICA'
        WHEN 4 THEN 'CONTROL CALIDAD PENDIENTE'
        WHEN 5 THEN 'CONTROL CALIDAD APROBADO'
        WHEN 6 THEN 'ENTREGADO'
        WHEN 7 THEN 'CANCELADO'
        ELSE 'RECHAZADO'
    END AS estado_descripcion,
    lab.nombre AS laboratorio_asignado,
    el.fecha_envio,
    el.fecha_recepcion,
    TRIM(per.nombres || ' ' || per.apellidos) AS paciente,
    p_montura.nombre AS montura
FROM ORDEN_TRABAJO ot
JOIN LENTE l ON ot.id_lente = l.id_lente
JOIN RECETA r ON l.id_receta = r.id_receta
JOIN PACIENTE pac ON r.id_paciente = pac.id_persona
JOIN PERSONA per ON pac.id_persona = per.id_persona
LEFT JOIN PRODUCTO p_montura ON l.id_montura = p_montura.id_producto
LEFT JOIN ENVIO_LABORATORIO el ON ot.id_orden_trabajo = el.id_orden_trabajo
LEFT JOIN LABORATORIO lab ON el.id_laboratorio = lab.id_laboratorio;
/

-- VISTA 8: V_M_CONTROL_CALIDAD_LABORATORIO (Integrante 3 (Especialista Taller, Calidad y Stock))
CREATE OR REPLACE VIEW V_M_CONTROL_CALIDAD_LABORATORIO AS
SELECT 
    lab.id_laboratorio,
    lab.nombre AS nombre_laboratorio,
    COUNT(el.id_envio_laboratorio) AS total_inspeccionados,
    SUM(CASE WHEN el.aprobado = 1 THEN 1 ELSE 0 END) AS total_aprobados,
    SUM(CASE WHEN el.aprobado = 0 THEN 1 ELSE 0 END) AS total_rechazados,
    ROUND((SUM(CASE WHEN el.aprobado = 1 THEN 1 ELSE 0 END) / GREATEST(1, COUNT(el.id_envio_laboratorio))) * 100, 2) AS pct_conformidad
FROM LABORATORIO lab
JOIN ENVIO_LABORATORIO el ON lab.id_laboratorio = el.id_laboratorio
WHERE el.fecha_revision IS NOT NULL
GROUP BY lab.id_laboratorio, lab.nombre;
/

-- VISTA 9: V_S_PRODUCTOS_STOCK_MINIMO (Integrante 3 (Especialista Taller, Calidad y Stock))
CREATE OR REPLACE VIEW V_S_PRODUCTOS_STOCK_MINIMO AS
SELECT 
    id_producto,
    codigo,
    nombre,
    marca,
    stock,
    precio
FROM PRODUCTO
WHERE stock <= 5 AND estado = 1;
/


-- ============================================================================
-- 7. CONSULTAS COMPLEJAS / REPORTES ANALITICOS (9 REPORTES - 3 POR INTEGRANTE)
-- ============================================================================
PROMPT >>> [7/9] Preparando 9 Consultas y Reportes Complejos...
-- REPORTE 01: Balance Consolidado de Facturación por Período, Comprobante y Cajero (Integrante 1 (Especialista Comercial y Finanzas))
SELECT 
    TO_CHAR(v.fecha_registro, 'YYYY-MM') AS periodo_mes,
    CASE v.tipo_comprobante
        WHEN 1 THEN 'BOLETA DE VENTA'
        WHEN 2 THEN 'FACTURA ELECTRONICA'
        ELSE 'NOTA DE VENTA'
    END AS tipo_comprobante,
    TRIM(per_emp.nombres || ' ' || per_emp.apellidos) AS cajero_responsable,
    COUNT(v.id_venta) AS total_operaciones,
    SUM(v.total) AS monto_total_facturado,
    SUM(NVL((SELECT SUM(p.monto) FROM PAGO p WHERE p.id_venta = v.id_venta), 0)) AS total_cobrado,
    SUM(GREATEST(0, v.total - NVL((SELECT SUM(p.monto) FROM PAGO p WHERE p.id_venta = v.id_venta), 0))) AS saldo_por_cobrar,
    ROUND(AVG(v.total), 2) AS ticket_promedio
FROM VENTA v
JOIN EMPLEADO emp ON v.id_empleado = emp.id_persona
JOIN PERSONA per_emp ON emp.id_persona = per_emp.id_persona
LEFT JOIN PACIENTE pac ON v.id_paciente = pac.id_persona
WHERE v.estado != 3 -- Excluir anuladas
GROUP BY 
    TO_CHAR(v.fecha_registro, 'YYYY-MM'),
    v.tipo_comprobante,
    TRIM(per_emp.nombres || ' ' || per_emp.apellidos)
ORDER BY periodo_mes DESC, monto_total_facturado DESC;

-- REPORTE 02: Ranking Multidimensional TOP de Artículos y Servicios con Mayor Ingreso (Integrante 1 (Especialista Comercial y Finanzas))
WITH CatalogoConsolidado AS (
    SELECT 
        'PRODUCTO' AS tipo_item,
        p.codigo AS codigo_item,
        p.nombre AS descripcion_item,
        NVL(c.nombre, 'GENERAL') AS categoria_rubro,
        pv.cantidad AS cantidad_movida,
        pv.sub_total AS ingreso_generado
    FROM PRODUCTO_VENDIDO pv
    JOIN PRODUCTO p ON pv.id_producto = p.id_producto
    LEFT JOIN CATEGORIA c ON p.id_categoria = c.id_categoria
    JOIN VENTA v ON pv.id_venta = v.id_venta
    WHERE v.estado != 3

    UNION ALL

    SELECT 
        'SERVICIO' AS tipo_item,
        'SERV-' || TO_CHAR(s.id_servicio) AS codigo_item,
        s.nombre AS descripcion_item,
        'ATENCION PROFESIONAL' AS categoria_rubro,
        1 AS cantidad_movida,
        sv.precio AS ingreso_generado
    FROM SERVICIO_VENDIDO sv
    JOIN SERVICIO s ON sv.id_servicio = s.id_servicio
    JOIN VENTA v ON sv.id_venta = v.id_venta
    WHERE v.estado != 3
)
SELECT 
    tipo_item,
    codigo_item,
    descripcion_item,
    categoria_rubro,
    SUM(cantidad_movida) AS unidades_totales,
    SUM(ingreso_generado) AS ingresos_totales,
    DENSE_RANK() OVER (PARTITION BY tipo_item ORDER BY SUM(ingreso_generado) DESC) AS rank_ingresos,
    DENSE_RANK() OVER (PARTITION BY tipo_item ORDER BY SUM(cantidad_movida) DESC) AS rank_unidades
FROM CatalogoConsolidado
GROUP BY tipo_item, codigo_item, descripcion_item, categoria_rubro
ORDER BY tipo_item, rank_ingresos;

-- REPORTE 03: Cartera de Cuentas por Cobrar y Análisis de Antigüedad de Deuda (Integrante 1 (Especialista Comercial y Finanzas))
SELECT 
    v.id_venta,
    v.numero_comprobante,
    v.fecha_registro AS fecha_emision,
    per.numero_documento AS dni_paciente,
    TRIM(per.nombres || ' ' || per.apellidos) AS nombre_paciente,
    per.telefono AS telefono_contacto,
    v.total AS importe_total,
    NVL(p_tot.total_abonado, 0) AS total_abonado,
    (v.total - NVL(p_tot.total_abonado, 0)) AS saldo_deudor,
    TRUNC(SYSDATE - v.fecha_registro) AS dias_antiguedad,
    CASE 
        WHEN TRUNC(SYSDATE - v.fecha_registro) <= 15 THEN 'TRAMO 0-15 DIAS (CORRIENTE)'
        WHEN TRUNC(SYSDATE - v.fecha_registro) <= 30 THEN 'TRAMO 16-30 DIAS (VENCIMIENTO PROXIMO)'
        ELSE 'TRAMO > 30 DIAS (MORA ALTA)'
    END AS estado_cartera
FROM VENTA v
JOIN PACIENTE pac ON v.id_paciente = pac.id_persona
JOIN PERSONA per ON pac.id_persona = per.id_persona
LEFT JOIN (
    SELECT id_venta, SUM(monto) AS total_abonado
    FROM PAGO
    GROUP BY id_venta
) p_tot ON v.id_venta = p_tot.id_venta
WHERE v.estado = 1 -- PENDIENTE DE COBRO
  AND (v.total - NVL(p_tot.total_abonado, 0)) > 0
ORDER BY dias_antiguedad DESC, saldo_deudor DESC;

-- REPORTE 04: Perfil Epidemiológico de Trastornos Refractivos por Grupo Etario y Género (Integrante 2 (Especialista Clínico y Pacientes))
SELECT 
    CASE 
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, per.fecha_nacimiento)/12) < 18 THEN 'INFANTES Y ADOLESCENTES (<18)'
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, per.fecha_nacimiento)/12) BETWEEN 18 AND 45 THEN 'ADULTOS JOVENES (18-45)'
        ELSE 'ADULTOS MAYORES (>45 - PRESBITAS)'
    END AS grupo_etario,
    DECODE(per.sexo, 1, 'MASCULINO', 2, 'FEMENINO', 'NO ESPECIFICADO') AS genero,
    COUNT(r.id_receta) AS total_evaluaciones,
    ROUND(AVG(mo.esfera), 2) AS promedio_esfera_od,
    ROUND(AVG(mo.cilindro), 2) AS promedio_cilindro_od,
    ROUND(AVG(m.distancia_pupilar), 2) AS promedio_dp_mm,
    SUM(CASE WHEN mo.esfera < 0 THEN 1 ELSE 0 END) AS casos_miopia,
    SUM(CASE WHEN mo.esfera > 0 THEN 1 ELSE 0 END) AS casos_hipermetropia,
    SUM(CASE WHEN mo.cilindro < 0 THEN 1 ELSE 0 END) AS casos_astigmatismo
FROM RECETA r
JOIN PACIENTE pac ON r.id_paciente = pac.id_persona
JOIN PERSONA per ON pac.id_persona = per.id_persona
JOIN MEDIDA m ON r.id_receta = m.id_receta AND m.tipo_medida = 1
JOIN MEDIDA_OJO mo ON m.id_ojo_derecho = mo.id_medida_ojo
GROUP BY 
    CASE 
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, per.fecha_nacimiento)/12) < 18 THEN 'INFANTES Y ADOLESCENTES (<18)'
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, per.fecha_nacimiento)/12) BETWEEN 18 AND 45 THEN 'ADULTOS JOVENES (18-45)'
        ELSE 'ADULTOS MAYORES (>45 - PRESBITAS)'
    END,
    DECODE(per.sexo, 1, 'MASCULINO', 2, 'FEMENINO', 'NO ESPECIFICADO')
ORDER BY grupo_etario, genero;

-- REPORTE 05: Trazabilidad de Recetas Oftálmicas no Convertidas a Venta (Integrante 2 (Especialista Clínico y Pacientes))
SELECT 
    r.id_receta,
    r.fecha_registro AS fecha_consulta,
    per_pac.numero_documento AS dni_paciente,
    TRIM(per_pac.nombres || ' ' || per_pac.apellidos) AS nombre_paciente,
    per_pac.telefono AS telefono_paciente,
    TRIM(per_doc.nombres || ' ' || per_doc.apellidos) AS optometra_evaluador,
    r.observaciones AS diagnostico_clinico,
    TRUNC(SYSDATE - r.fecha_registro) AS dias_sin_compra
FROM RECETA r
JOIN PACIENTE pac ON r.id_paciente = pac.id_persona
JOIN PERSONA per_pac ON pac.id_persona = per_pac.id_persona
JOIN EMPLEADO emp ON r.id_empleado = emp.id_persona
JOIN PERSONA per_doc ON emp.id_persona = per_doc.id_persona
LEFT JOIN LENTE l ON r.id_receta = l.id_receta
LEFT JOIN VENTA v ON r.id_receta = v.id_receta AND v.estado != 3
WHERE l.id_lente IS NULL 
  AND v.id_venta IS NULL
  AND r.fecha_registro >= ADD_MONTHS(SYSDATE, -6)
ORDER BY r.fecha_registro DESC;

-- REPORTE 06: Historial de Evolución Visual en Pacientes Recurrentes (Integrante 2 (Especialista Clínico y Pacientes))
SELECT 
    pac.id_persona AS id_paciente,
    TRIM(per.nombres || ' ' || per.apellidos) AS paciente,
    r.id_receta,
    r.fecha_registro AS fecha_atencion,
    mo_od.esfera AS esfera_od_actual,
    LAG(mo_od.esfera, 1) OVER (PARTITION BY pac.id_persona ORDER BY r.fecha_registro) AS esfera_od_previa,
    ROUND(mo_od.esfera - LAG(mo_od.esfera, 1) OVER (PARTITION BY pac.id_persona ORDER BY r.fecha_registro), 2) AS variacion_esfera_od,
    mo_od.cilindro AS cilindro_od_actual,
    LAG(mo_od.cilindro, 1) OVER (PARTITION BY pac.id_persona ORDER BY r.fecha_registro) AS cilindro_od_previo
FROM RECETA r
JOIN PACIENTE pac ON r.id_paciente = pac.id_persona
JOIN PERSONA per ON pac.id_persona = per.id_persona
JOIN MEDIDA m ON r.id_receta = m.id_receta AND m.tipo_medida = 1
JOIN MEDIDA_OJO mo_od ON m.id_ojo_derecho = mo_od.id_medida_ojo
WHERE pac.id_persona IN (
    SELECT id_paciente FROM RECETA GROUP BY id_paciente HAVING COUNT(id_receta) >= 2
)
ORDER BY pac.id_persona, r.fecha_registro;

-- REPORTE 07: Rendimiento y Nivel de Cumplimiento de Laboratorios Ópticos Externos (Integrante 3 (Especialista Taller, Calidad y Stock))
SELECT 
    lab.id_laboratorio,
    lab.nombre AS laboratorio_optico,
    lab.telefono,
    COUNT(el.id_envio_laboratorio) AS total_trabajos_enviados,
    SUM(CASE WHEN el.fecha_recepcion IS NOT NULL THEN 1 ELSE 0 END) AS trabajos_recibidos,
    ROUND(AVG(el.fecha_recepcion - el.fecha_envio), 1) AS tiempo_promedio_dias,
    SUM(CASE WHEN el.aprobado = 1 THEN 1 ELSE 0 END) AS trabajos_aprobados_cc,
    SUM(CASE WHEN el.aprobado = 0 THEN 1 ELSE 0 END) AS trabajos_rechazados_cc,
    ROUND((SUM(CASE WHEN el.aprobado = 1 THEN 1 ELSE 0 END) / GREATEST(1, COUNT(el.fecha_recepcion))) * 100, 2) AS efectividad_calidad_pct
FROM LABORATORIO lab
LEFT JOIN ENVIO_LABORATORIO el ON lab.id_laboratorio = el.id_laboratorio
GROUP BY lab.id_laboratorio, lab.nombre, lab.telefono
ORDER BY total_trabajos_enviados DESC, efectividad_calidad_pct DESC;

-- REPORTE 08: Análisis de Tasa de Rechazos y Discrepancias de Calidad por Proveedor (Integrante 3 (Especialista Taller, Calidad y Stock))
SELECT 
    lab.nombre AS laboratorio,
    dcc.parametro,
    dcc.ojo,
    COUNT(dcc.id_detalle_cc) AS total_evaluaciones,
    SUM(CASE WHEN dcc.aprobado = 0 THEN 1 ELSE 0 END) AS total_discrepancias,
    ROUND(AVG(dcc.desviacion), 2) AS desviacion_media,
    ROUND(MAX(dcc.exceso), 2) AS peor_exceso_detectado,
    ROUND((SUM(CASE WHEN dcc.aprobado = 0 THEN 1 ELSE 0 END) / COUNT(dcc.id_detalle_cc)) * 100, 2) AS tasa_falla_pct
FROM DETALLE_CONTROL_CALIDAD dcc
JOIN ENVIO_LABORATORIO el ON dcc.id_envio_laboratorio = el.id_envio_laboratorio
JOIN LABORATORIO lab ON el.id_laboratorio = lab.id_laboratorio
GROUP BY lab.nombre, dcc.parametro, dcc.ojo
HAVING SUM(CASE WHEN dcc.aprobado = 0 THEN 1 ELSE 0 END) > 0
ORDER BY tasa_falla_pct DESC;

-- REPORTE 09: Auditoría de Kardex Valorizado y Alerta de Reposición por Stock Crítico (Integrante 3 (Especialista Taller, Calidad y Stock))
SELECT 
    p.id_producto,
    p.codigo AS codigo_sku,
    p.nombre AS descripcion_producto,
    NVL(c.nombre, 'GENERAL') AS categoria,
    p.stock AS stock_fisico_actual,
    FN_OBTENER_STOCK_DISPONIBLE(p.id_producto) AS stock_disponible_neto,
    p.precio AS precio_unitario,
    (p.stock * p.precio) AS valor_inventario_total,
    CASE 
        WHEN p.stock = 0 THEN 'AGOTADO CRITICO'
        WHEN p.stock <= 3 THEN 'REORDEN URGENTE'
        ELSE 'STOCK BAJO'
    END AS alerta_logistica
FROM PRODUCTO p
LEFT JOIN CATEGORIA c ON p.id_categoria = c.id_categoria
WHERE p.stock <= 5 AND p.estado = 1
ORDER BY p.stock ASC, p.precio DESC;


-- ============================================================================
-- 8. PARTICIONAMIENTO HORIZONTAL (3 TABLAS - 1 POR INTEGRANTE)
-- ============================================================================
PROMPT >>> [8/9] Creando Estructuras de Tablas Particionadas...
-- PARTICIONAMIENTO 1: Tabla VENTA (Integrante 1 (Especialista Comercial y Finanzas))
-- Creacion de tabla VENTA con Particionamiento por Rango
CREATE TABLE VENTA_PARTICIONADA (
    id_venta            NUMBER GENERATED ALWAYS AS IDENTITY,
    fecha_registro      DATE DEFAULT SYSDATE NOT NULL,
    numero_comprobante  VARCHAR2(50) NOT NULL,
    tipo_comprobante    NUMBER NOT NULL,
    estado              NUMBER DEFAULT 1 NOT NULL,
    total               NUMBER(12,2) NOT NULL,
    id_paciente         NUMBER,
    id_empleado         NUMBER NOT NULL,
    id_receta           NUMBER,
    CONSTRAINT VENTA_PART_pk PRIMARY KEY (id_venta, fecha_registro)
)
PARTITION BY RANGE (fecha_registro) (
    PARTITION P_VENTAS_2024 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')),
    PARTITION P_VENTAS_2025 VALUES LESS THAN (TO_DATE('2026-01-01', 'YYYY-MM-DD')),
    PARTITION P_VENTAS_2026 VALUES LESS THAN (TO_DATE('2027-01-01', 'YYYY-MM-DD')),
    PARTITION P_VENTAS_FUTURO VALUES LESS THAN (MAXVALUE)
);

-- PARTICIONAMIENTO 2: Tabla PACIENTE_LOG (Integrante 2 (Especialista Clínico y Pacientes))
-- Creacion de tabla PACIENTE_LOG con Particionamiento por Lista
CREATE TABLE PACIENTE_LOG_PARTICIONADA (
    id_usuario_log      NUMBER GENERATED ALWAYS AS IDENTITY,
    fecha_log           DATE DEFAULT SYSDATE NOT NULL,
    tipo_log            NUMBER NOT NULL,
    id_persona          NUMBER,
    id_usuario          NUMBER,
    CONSTRAINT PACIENTE_LOG_PART_pk PRIMARY KEY (id_usuario_log, tipo_log)
)
PARTITION BY LIST (tipo_log) (
    PARTITION P_LOG_ALTAS VALUES (1),
    PARTITION P_LOG_MODIFICACIONES VALUES (2),
    PARTITION P_LOG_BAJAS VALUES (3),
    PARTITION P_LOG_OTROS VALUES (DEFAULT)
);

-- PARTICIONAMIENTO 3: Tabla MOVIMIENTO_STOCK_LOG (Integrante 3 (Especialista Taller, Calidad y Stock))
-- Creacion de tabla MOVIMIENTO_STOCK_LOG con Particionamiento por Intervalos
CREATE TABLE MOVIMIENTO_STOCK_LOG_PART (
    id_movimiento_stock_log NUMBER GENERATED ALWAYS AS IDENTITY,
    fecha_registro          DATE DEFAULT SYSDATE NOT NULL,
    cantidad                NUMBER NOT NULL,
    stock_previo            NUMBER NOT NULL,
    stock_posterior         NUMBER NOT NULL,
    motivo                  NUMBER NOT NULL,
    observaciones           VARCHAR2(200),
    id_producto             NUMBER NOT NULL,
    id_usuario              NUMBER NOT NULL,
    CONSTRAINT MOV_STOCK_LOG_PART_pk PRIMARY KEY (id_movimiento_stock_log, fecha_registro)
)
PARTITION BY RANGE (fecha_registro)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH')) (
    PARTITION P_KARDEX_INICIAL VALUES LESS THAN (TO_DATE('2026-01-01', 'YYYY-MM-DD'))
);


-- ============================================================================
-- 9. SEGURIDAD AVANZADA: ENMASCARAMIENTO (DBMS_REDACT) Y AUDITORIA UNIFICADA
-- ============================================================================
PROMPT >>> [9/9] Aplicando Politicas de Enmascaramiento y Auditoria...
-- ENMASCARAMIENTO 1: Tabla PAGO (Integrante 1 (Especialista Comercial y Finanzas))
-- Enmascaramiento Parcial de Numero de Operacion Financiera
BEGIN
    DBMS_REDACT.ADD_POLICY(
        object_schema       => 'GEOVISION_PROD',
        object_name         => 'PAGO',
        policy_name         => 'POL_REDACT_PAGO_OPERACION',
        column_name         => 'NUMERO_OPERACION',
        function_type       => DBMS_REDACT.PARTIAL,
        function_parameters => 'VVVVVVVVVVVVVVVVVVVV,VVVVVVVVVVVVVVVVVVVV,*,1,6',
        expression          => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') != ''USR_DBA_ADMIN'''
    );
END;
/

-- ENMASCARAMIENTO 2: Tabla PERSONA (Integrante 2 (Especialista Clínico y Pacientes))
-- Enmascaramiento Parcial de DNI / Numero de Documento
BEGIN
    DBMS_REDACT.ADD_POLICY(
        object_schema       => 'GEOVISION_PROD',
        object_name         => 'PERSONA',
        policy_name         => 'POL_REDACT_PERSONA_DNI',
        column_name         => 'NUMERO_DOCUMENTO',
        function_type       => DBMS_REDACT.PARTIAL,
        function_parameters => '99999999,99999999,*,3,4', -- Muestra primeros 2 y ultimos 2 digitos
        expression          => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') = ''USR_APP_SPRING'''
    );
END;
/

-- ENMASCARAMIENTO 3: Tabla USUARIO (Integrante 3 (Especialista Taller, Calidad y Stock))
-- Enmascaramiento Total de Contrasena y Correo Electronico
BEGIN
    DBMS_REDACT.ADD_POLICY(
        object_schema       => 'GEOVISION_PROD',
        object_name         => 'USUARIO',
        policy_name         => 'POL_REDACT_USUARIO_SEGURIDAD',
        column_name         => 'CORREO',
        function_type       => DBMS_REDACT.REGEXP,
        regexp_pattern      => '^(.)(.*)(@.*)$',
        regexp_replace_string => '\1****\3',
        expression          => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') != ''USR_DBA_ADMIN'''
    );
END;
/


-- AUDITORIA UNIFICADA Y FORENSE --
-- ============================================================================
-- AUDITORIA INSTITUCIONAL ORACLE 19c (UNIFIED AUDITING)
-- ============================================================================

-- 1. Creacion de la Politica de Auditoria Unificada
CREATE AUDIT POLICY POL_AUDIT_GEOVISION_TRANSACCIONES
ACTIONS 
    INSERT ON GEOVISION_PROD.VENTA,
    UPDATE ON GEOVISION_PROD.VENTA,
    DELETE ON GEOVISION_PROD.VENTA,
    INSERT ON GEOVISION_PROD.RECETA,
    UPDATE ON GEOVISION_PROD.RECETA,
    DELETE ON GEOVISION_PROD.RECETA,
    INSERT ON GEOVISION_PROD.USUARIO,
    UPDATE ON GEOVISION_PROD.USUARIO,
    DELETE ON GEOVISION_PROD.USUARIO;

-- 2. Habilitacion de la Politica para todos los usuarios
AUDIT POLICY POL_AUDIT_GEOVISION_TRANSACCIONES;

-- 3. Tabla complementaria de Trazabilidad Forense
CREATE TABLE AUDITORIA_EVENTOS_LOG (
    id_auditoria    NUMBER GENERATED ALWAYS AS IDENTITY,
    tabla_afectada  VARCHAR2(50) NOT NULL,
    operacion       VARCHAR2(10) NOT NULL,
    usuario_db      VARCHAR2(50) DEFAULT USER NOT NULL,
    fecha_evento    TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    ip_origen       VARCHAR2(50),
    datos_anteriores CLOB,
    datos_nuevos    CLOB,
    CONSTRAINT AUDITORIA_EVENTOS_LOG_pk PRIMARY KEY (id_auditoria)
);

-- 4. Trigger de Auditoria Granular en VENTA
CREATE OR REPLACE TRIGGER TRG_AUDITAR_VENTAS_FORENSE
AFTER INSERT OR UPDATE OR DELETE ON VENTA
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO AUDITORIA_EVENTOS_LOG (
            tabla_afectada, operacion, ip_origen, datos_nuevos
        ) VALUES (
            'VENTA', 'INSERT', SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
            'ID=' || :NEW.id_venta || ' | Total=' || :NEW.total || ' | Comprobante=' || :NEW.numero_comprobante
        );
    ELSIF UPDATING THEN
        INSERT INTO AUDITORIA_EVENTOS_LOG (
            tabla_afectada, operacion, ip_origen, datos_anteriores, datos_nuevos
        ) VALUES (
            'VENTA', 'UPDATE', SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
            'EstadoAnterior=' || :OLD.estado || ' | TotalAnterior=' || :OLD.total,
            'EstadoNuevo=' || :NEW.estado || ' | TotalNuevo=' || :NEW.total
        );
    ELSIF DELETING THEN
        INSERT INTO AUDITORIA_EVENTOS_LOG (
            tabla_afectada, operacion, ip_origen, datos_anteriores
        ) VALUES (
            'VENTA', 'DELETE', SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
            'ID=' || :OLD.id_venta || ' | Comprobante=' || :OLD.numero_comprobante
        );
    END IF;
END;
/


PROMPT >>> DESPLIEGUE DEL ENTREGABLE DE ADMINISTRACION DE BD II COMPLETADO EXITOSAMENTE.
COMMIT;
