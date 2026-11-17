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
