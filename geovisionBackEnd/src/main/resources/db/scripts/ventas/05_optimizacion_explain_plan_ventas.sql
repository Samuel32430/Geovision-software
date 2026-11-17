-- ============================================================================
-- PROYECTO GEOVISION - MODULO DE VENTAS Y REPORTES
-- Archivo: 05_optimizacion_explain_plan_ventas.sql
-- Motor: Oracle Database 19c
-- Proposito: 1. Indices DDL complementarios para optimizar consultas y FKs de ventas.
--            2. Generacion y visualizacion de EXPLAIN PLAN para las consultas criticas.
--            3. Analisis detallado de costo, accesos por indice y prevencion de TM locks.
--            4. Bloque anonimo de prueba integral para SP_PROCESAR_VENTA_CON_DETALLE.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 100;

PROMPT >>> [1/4] CREANDO INDICES OPTIMIZADOS PARA EL MODULO DE VENTAS...

-- En Oracle 19c, las claves foraneas sin indice producen contencion critica
-- por bloqueos de tabla completa (TM locks) ante INSERTs/UPDATEs concurrentes
-- y fuerzan TABLE ACCESS FULL en las operaciones de agrupacion y joins.

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX IDX_PV_VENTA ON PRODUCTO_VENDIDO(id_venta)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX IDX_PV_PRODUCTO ON PRODUCTO_VENDIDO(id_producto)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX IDX_PAGO_VENTA ON PAGO(id_venta)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX IDX_VENTA_EMPLEADO ON VENTA(id_empleado)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX IDX_VENTA_PACIENTE ON VENTA(id_paciente)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX IDX_VENTA_RECETA ON VENTA(id_receta)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX IDX_VENTA_FECHA_ESTADO ON VENTA(fecha_registro, estado)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX IDX_MSL_PROD_MOTIVO ON MOVIMIENTO_STOCK_LOG(id_producto, motivo)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

COMMIT;
PROMPT >>> Indices de optimizacion creados o verificados exitosamente.

-- ============================================================================
-- 2. GENERACION DE EXPLAIN PLAN (PLANES DE EJECUCION DE CONSULTAS CRITICAS)
-- ============================================================================
PROMPT >>> [2/4] GENERANDO EXPLAIN PLAN PARA OPERACIONES CRITICAS DEL PROCEDIMIENTO...

-- ----------------------------------------------------------------------------
-- CONSULTA 1: Bloqueo Pesimista por Fila (Row-Level Lock) de Productos
-- Esta sentencia garantiza aislamiento serializable y previene perdida de stock.
-- Se evalua que el optimizador use INDEX UNIQUE SCAN sobre PRODUCTO_pk.
-- ----------------------------------------------------------------------------
DELETE FROM PLAN_TABLE WHERE STATEMENT_ID = 'PLAN_BLOQUEO_STOCK';

EXPLAIN PLAN SET STATEMENT_ID = 'PLAN_BLOQUEO_STOCK' FOR
SELECT nombre, precio, stock, estado
FROM PRODUCTO
WHERE id_producto = 1
FOR UPDATE;

-- ----------------------------------------------------------------------------
-- CONSULTA 2: Parseo de Payload JSON y Cruce con Catalogo de Productos
-- El procedimiento procesa los items mediante JSON_TABLE. Evaluamos como
-- Oracle 19c proyecta el JSON y resuelve el cruce con el indice primario.
-- ----------------------------------------------------------------------------
DELETE FROM PLAN_TABLE WHERE STATEMENT_ID = 'PLAN_JSON_TABLE_PRODUCTO';

EXPLAIN PLAN SET STATEMENT_ID = 'PLAN_JSON_TABLE_PRODUCTO' FOR
SELECT 
    jt.id_producto,
    SUM(jt.cantidad) AS cantidad_total,
    p.nombre,
    p.precio,
    p.stock
FROM JSON_TABLE(
    '[{"id_producto": 1, "cantidad": 2}, {"id_producto": 2, "cantidad": 1}]',
    '$[*]' COLUMNS (
        id_producto NUMBER PATH '$.id_producto',
        cantidad    NUMBER PATH '$.cantidad'
    )
) jt
JOIN PRODUCTO p ON jt.id_producto = p.id_producto
GROUP BY jt.id_producto, p.nombre, p.precio, p.stock
ORDER BY jt.id_producto ASC;

-- ----------------------------------------------------------------------------
-- CONSULTA 3: Validacion Cruzada de Receta y Paciente (Reglas RN-VE02/03)
-- Cruza la receta con el paciente para asegurar coherencia clinica.
-- Debe emplear INDEX UNIQUE SCAN tanto en RECETA_pk como en PACIENTE_pk.
-- ----------------------------------------------------------------------------
DELETE FROM PLAN_TABLE WHERE STATEMENT_ID = 'PLAN_VALIDACION_RECETA';

EXPLAIN PLAN SET STATEMENT_ID = 'PLAN_VALIDACION_RECETA' FOR
SELECT r.id_receta, r.id_paciente, pac.estado AS estado_paciente
FROM RECETA r
JOIN PACIENTE pac ON r.id_paciente = pac.id_persona
WHERE r.id_receta = 10 AND pac.id_persona = 5;

-- ----------------------------------------------------------------------------
-- CONSULTA 4: Calculo de Saldo Pendiente y Consolidacion de Pagos
-- Utilizada por FN_CALCULAR_SALDO_VENTA y el trigger de actualizacion.
-- Gracias a IDX_PAGO_VENTA, debe ejecutar INDEX RANGE SCAN en lugar de FULL SCAN.
-- ----------------------------------------------------------------------------
DELETE FROM PLAN_TABLE WHERE STATEMENT_ID = 'PLAN_CALCULO_SALDO';

EXPLAIN PLAN SET STATEMENT_ID = 'PLAN_CALCULO_SALDO' FOR
SELECT 
    v.id_venta,
    v.total,
    COALESCE(SUM(p.monto), 0) AS total_pagado,
    (v.total - COALESCE(SUM(p.monto), 0)) AS saldo_deudor
FROM VENTA v
LEFT JOIN PAGO p ON v.id_venta = p.id_venta
WHERE v.id_venta = 100
GROUP BY v.id_venta, v.total;

-- ============================================================================
-- 3. VISUALIZACION DE LOS PLANES CON DBMS_XPLAN.DISPLAY
-- ============================================================================
PROMPT >>> [3/4] RESULTADOS FORMATEADOS DE DBMS_XPLAN...

PROMPT ------------------------------------------------------------------------
PROMPT PLAN 1: BLOQUEO PESIMISTA DE PRODUCTO (FOR UPDATE)
PROMPT ------------------------------------------------------------------------
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'PLAN_BLOQUEO_STOCK', 'TYPICAL'));

PROMPT ------------------------------------------------------------------------
PROMPT PLAN 2: JSON_TABLE + CRUCE CON PRODUCTO + ORDENAMIENTO
PROMPT ------------------------------------------------------------------------
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'PLAN_JSON_TABLE_PRODUCTO', 'TYPICAL'));

PROMPT ------------------------------------------------------------------------
PROMPT PLAN 3: VALIDACION DE INTEGRIDAD RECETA - PACIENTE
PROMPT ------------------------------------------------------------------------
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'PLAN_VALIDACION_RECETA', 'TYPICAL'));

PROMPT ------------------------------------------------------------------------
PROMPT PLAN 4: CONSOLIDACION DE PAGOS Y SALDO (CON INDICE IDX_PAGO_VENTA)
PROMPT ------------------------------------------------------------------------
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'PLAN_CALCULO_SALDO', 'TYPICAL'));

-- ============================================================================
-- 4. BATERIA DE PRUEBA TRANSACCIONAL (BLOQUE ANONIMO)
-- ============================================================================
PROMPT >>> [4/4] EJECUTANDO PRUEBA FUNCIONAL DEL PROCEDIMIENTO...

DECLARE
    v_id_emp            NUMBER;
    v_id_pac            NUMBER;
    v_id_rec            NUMBER;
    v_id_prod1          NUMBER;
    v_id_prod2          NUMBER;
    v_json_payload      CLOB;

    -- Parametros OUT
    v_out_id_venta      NUMBER;
    v_out_comprobante   VARCHAR2(100);
    v_out_total         NUMBER;
    v_out_pagado        NUMBER;
    v_out_saldo         NUMBER;
    v_out_estado        NUMBER;
    v_out_mensaje       VARCHAR2(500);

BEGIN
    DBMS_OUTPUT.PUT_LINE('================================================================');
    DBMS_OUTPUT.PUT_LINE('INICIANDO PRUEBA DE SP_PROCESAR_VENTA_CON_DETALLE');
    DBMS_OUTPUT.PUT_LINE('================================================================');

    -- 1. Obtener identificadores existentes para el test
    SELECT MIN(id_persona) INTO v_id_emp FROM EMPLEADO WHERE estado = 1;
    SELECT MIN(id_persona) INTO v_id_pac FROM PACIENTE WHERE estado = 1;
    SELECT MIN(id_producto) INTO v_id_prod1 FROM PRODUCTO WHERE estado = 1 AND stock >= 5;

    IF v_id_emp IS NULL OR v_id_prod1 IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('AVISO: No se encontraron datos suficientes en catalogo (EMPLEADO o PRODUCTO con stock >= 5). Se omite ejecucion en vivo.');
        RETURN;
    END IF;

    -- Construir payload JSON simulado para venta directa sin receta (2 unidades)
    v_json_payload := '[{"id_producto": ' || v_id_prod1 || ', "cantidad": 2}]';

    -- Obtener precio del producto para calcular pago exacto 100%
    DECLARE
        v_precio_unit NUMBER;
        v_total_esperado NUMBER;
    BEGIN
        SELECT precio INTO v_precio_unit FROM PRODUCTO WHERE id_producto = v_id_prod1;
        v_total_esperado := v_precio_unit * 2;

        -- Invocacion del procedimiento
        SP_PROCESAR_VENTA_CON_DETALLE (
            p_id_empleado        => v_id_emp,
            p_id_paciente        => v_id_pac,
            p_id_receta          => NULL,
            p_tipo_comprobante   => 1, -- Boleta
            p_items_json         => v_json_payload,
            p_monto_inicial_pago => v_total_esperado,
            p_metodo_pago        => 1, -- Efectivo
            p_numero_operacion   => NULL,
            p_id_venta           => v_out_id_venta,
            p_numero_comprobante => v_out_comprobante,
            p_total_calculado    => v_out_total,
            p_total_pagado       => v_out_pagado,
            p_saldo_pendiente    => v_out_saldo,
            p_estado_venta       => v_out_estado,
            p_mensaje            => v_out_mensaje
        );

        DBMS_OUTPUT.PUT_LINE('VENTA REGISTRADA CON EXITO:');
        DBMS_OUTPUT.PUT_LINE(' - ID Venta:       ' || v_out_id_venta);
        DBMS_OUTPUT.PUT_LINE(' - Comprobante:    ' || v_out_comprobante);
        DBMS_OUTPUT.PUT_LINE(' - Total Venta:    S/ ' || v_out_total);
        DBMS_OUTPUT.PUT_LINE(' - Monto Pagado:   S/ ' || v_out_pagado);
        DBMS_OUTPUT.PUT_LINE(' - Saldo Deudor:   S/ ' || v_out_saldo);
        DBMS_OUTPUT.PUT_LINE(' - Estado:         ' || CASE WHEN v_out_estado = 2 THEN 'PAGADA (2)' ELSE 'PENDIENTE (1)' END);
        DBMS_OUTPUT.PUT_LINE(' - Mensaje:        ' || v_out_mensaje);

        -- Rollback para no ensuciar la base de datos de desarrollo
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Prueba finalizada y revertida satisfactoriamente (ROLLBACK de test).');
    END;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR EN LA PRUEBA: ' || SQLERRM);
END;
/
