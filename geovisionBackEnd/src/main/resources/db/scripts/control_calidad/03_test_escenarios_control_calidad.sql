-- ============================================================================
-- PROYECTO GEOVISION - MODULO DE CONTROL DE CALIDAD Y ORDENES DE TRABAJO
-- Archivo: 03_test_escenarios_control_calidad.sql
-- Motor: Oracle Database 19c
-- Proposito: Bateria de pruebas para validar SP_EVALUAR_CONTROL_CALIDAD_TRABAJO
--            tanto en escenario Aprobado como en Rechazado con reporte de excesos.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- ----------------------------------------------------------------------------
-- ESCENARIO 1: EJECUCION CON CONTROL DE CALIDAD APROBADO (TODO EN TOLERANCIA)
-- ----------------------------------------------------------------------------
DECLARE
    -- Parametros de entrada
    v_id_envio          NUMBER := 1; -- Asignar un ID de envio existente en estado recibido
    v_id_usuario        NUMBER := 1;
    v_json_aprobado     CLOB;
    v_observaciones     VARCHAR2(200) := 'Control de calidad rutinario en taller - Lente monofocal Lejos';
    
    -- Parametros de salida
    v_aprobado_global   NUMBER;
    v_total_evaluadas   NUMBER;
    v_aprobadas         NUMBER;
    v_rechazadas        NUMBER;
    v_dictamen          VARCHAR2(500);
    v_cursor            SYS_REFCURSOR;

    -- Variables para leer el cursor de detalle
    v_id_detalle        NUMBER;
    v_tipo_medida       NUMBER;
    v_nom_tipo          VARCHAR2(20);
    v_ojo               VARCHAR2(5);
    v_parametro         VARCHAR2(30);
    v_receta            NUMBER;
    v_medido            NUMBER;
    v_tolerancia        NUMBER;
    v_desviacion        NUMBER;
    v_exceso            NUMBER;
    v_cumple            NUMBER;
    v_estado_txt        VARCHAR2(20);

BEGIN
    DBMS_OUTPUT.PUT_LINE('================================================================');
    DBMS_OUTPUT.PUT_LINE('INICIANDO PRUEBA DE CONTROL DE CALIDAD - ESCENARIO APROBADO');
    DBMS_OUTPUT.PUT_LINE('================================================================');

    -- Payload JSON simulando medicion tomada en el negocio (lensometria dentro de rangos)
    v_json_aprobado := '[
        {
            "tipo_medida": 1,
            "distancia_pupilar": 62.50,
            "prisma": 0.00,
            "observaciones": "Sin novedades opticas en montura",
            "ojo_derecho": {
                "agudeza_visual": "20/20",
                "esfera": -2.25,
                "cilindro": -0.75,
                "eje": 15,
                "adicion": 0.00
            },
            "ojo_izquierdo": {
                "agudeza_visual": "20/20",
                "esfera": -1.50,
                "cilindro": -0.50,
                "eje": 170,
                "adicion": 0.00
            }
        }
    ]';

    -- Invocacion del procedimiento
    SP_EVALUAR_CONTROL_CALIDAD_TRABAJO(
        p_id_envio_laboratorio      => v_id_envio,
        p_id_usuario                => v_id_usuario,
        p_medidas_control_json      => v_json_aprobado,
        p_observaciones             => v_observaciones,
        p_tol_dioptrias_custom      => 0.25,
        p_tol_eje_custom            => 4.00,
        p_tol_dp_custom             => 1.00,
        p_tol_prisma_custom         => 0.25,
        p_aprobado_global           => v_aprobado_global,
        p_total_medidas_evaluadas   => v_total_evaluadas,
        p_medidas_aprobadas         => v_aprobadas,
        p_medidas_rechazadas        => v_rechazadas,
        p_resumen_dictamen          => v_dictamen,
        p_cursor_detalle            => v_cursor
    );

    DBMS_OUTPUT.PUT_LINE('DICTAMEN: ' || v_dictamen);
    DBMS_OUTPUT.PUT_LINE('RESULTADO GLOBAL: ' || CASE WHEN v_aprobado_global = 1 THEN 'APROBADO (1)' ELSE 'RECHAZADO (0)' END);
    DBMS_OUTPUT.PUT_LINE('MEDIDAS EVALUADAS: ' || v_total_evaluadas || ' | APROBADAS: ' || v_aprobadas || ' | RECHAZADAS: ' || v_rechazadas);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('OJO', 5) || RPAD('PARAMETRO', 20) || RPAD('RECETA', 10) || RPAD('MEDIDO', 10) || RPAD('TOL', 8) || RPAD('DESV', 8) || RPAD('EXCESO', 8) || 'ESTADO');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------------------------------------');

    LOOP
        FETCH v_cursor INTO 
            v_id_detalle, v_tipo_medida, v_nom_tipo, v_ojo, v_parametro,
            v_receta, v_medido, v_tolerancia, v_desviacion, v_exceso, v_cumple, v_estado_txt;
        EXIT WHEN v_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_ojo, 5) ||
            RPAD(v_parametro, 20) ||
            RPAD(NVL(TO_CHAR(v_receta, '90.99'), ' - '), 10) ||
            RPAD(NVL(TO_CHAR(v_medido, '90.99'), ' - '), 10) ||
            RPAD(TO_CHAR(v_tolerancia, '90.99'), 8) ||
            RPAD(TO_CHAR(v_desviacion, '90.99'), 8) ||
            RPAD(TO_CHAR(v_exceso, '90.99'), 8) ||
            v_estado_txt
        );
    END LOOP;
    CLOSE v_cursor;

    -- Confirmar o revertir segun se requiera en sesion de prueba
    -- COMMIT;
    ROLLBACK;
END;
/


-- ----------------------------------------------------------------------------
-- ESCENARIO 2: EJECUCION CON RECHAZO (EXCESOS EN ESFERA Y EJE)
-- ----------------------------------------------------------------------------
DECLARE
    v_id_envio          NUMBER := 1;
    v_id_usuario        NUMBER := 1;
    v_json_rechazado    CLOB;
    v_aprobado_global   NUMBER;
    v_total_evaluadas   NUMBER;
    v_aprobadas         NUMBER;
    v_rechazadas        NUMBER;
    v_dictamen          VARCHAR2(500);
    v_cursor            SYS_REFCURSOR;

    v_id_detalle        NUMBER;
    v_tipo_medida       NUMBER;
    v_nom_tipo          VARCHAR2(20);
    v_ojo               VARCHAR2(5);
    v_parametro         VARCHAR2(30);
    v_receta            NUMBER;
    v_medido            NUMBER;
    v_tolerancia        NUMBER;
    v_desviacion        NUMBER;
    v_exceso            NUMBER;
    v_cumple            NUMBER;
    v_estado_txt        VARCHAR2(20);

BEGIN
    DBMS_OUTPUT.PUT_LINE('================================================================');
    DBMS_OUTPUT.PUT_LINE('INICIANDO PRUEBA DE CONTROL DE CALIDAD - ESCENARIO RECHAZADO');
    DBMS_OUTPUT.PUT_LINE('================================================================');

    -- Payload JSON con error severo en esfera OD y desalineacion de eje en OI
    v_json_rechazado := '[
        {
            "tipo_medida": 1,
            "distancia_pupilar": 65.50,
            "prisma": 0.00,
            "observaciones": "Cilindro con desalineacion notable en lente izquierdo",
            "ojo_derecho": {
                "agudeza_visual": "20/30",
                "esfera": -3.00,
                "cilindro": -0.75,
                "eje": 15,
                "adicion": 0.00
            },
            "ojo_izquierdo": {
                "agudeza_visual": "20/40",
                "esfera": -1.50,
                "cilindro": -0.50,
                "eje": 140,
                "adicion": 0.00
            }
        }
    ]';

    SP_EVALUAR_CONTROL_CALIDAD_TRABAJO(
        p_id_envio_laboratorio      => v_id_envio,
        p_id_usuario                => v_id_usuario,
        p_medidas_control_json      => v_json_rechazado,
        p_observaciones             => 'Rechazo detectado en control inicial',
        p_tol_dioptrias_custom      => 0.25,
        p_tol_eje_custom            => 4.00,
        p_tol_dp_custom             => 1.00,
        p_tol_prisma_custom         => 0.25,
        p_aprobado_global           => v_aprobado_global,
        p_total_medidas_evaluadas   => v_total_evaluadas,
        p_medidas_aprobadas         => v_aprobadas,
        p_medidas_rechazadas        => v_rechazadas,
        p_resumen_dictamen          => v_dictamen,
        p_cursor_detalle            => v_cursor
    );

    DBMS_OUTPUT.PUT_LINE('DICTAMEN: ' || v_dictamen);
    DBMS_OUTPUT.PUT_LINE('RESULTADO GLOBAL: ' || CASE WHEN v_aprobado_global = 1 THEN 'APROBADO (1)' ELSE 'RECHAZADO (0)' END);
    DBMS_OUTPUT.PUT_LINE('MEDIDAS EVALUADAS: ' || v_total_evaluadas || ' | APROBADAS: ' || v_aprobadas || ' | RECHAZADAS: ' || v_rechazadas);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('OJO', 5) || RPAD('PARAMETRO', 20) || RPAD('RECETA', 10) || RPAD('MEDIDO', 10) || RPAD('TOL', 8) || RPAD('DESV', 8) || RPAD('EXCESO', 8) || 'ESTADO');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------------------------------------');

    LOOP
        FETCH v_cursor INTO 
            v_id_detalle, v_tipo_medida, v_nom_tipo, v_ojo, v_parametro,
            v_receta, v_medido, v_tolerancia, v_desviacion, v_exceso, v_cumple, v_estado_txt;
        EXIT WHEN v_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_ojo, 5) ||
            RPAD(v_parametro, 20) ||
            RPAD(NVL(TO_CHAR(v_receta, '90.99'), ' - '), 10) ||
            RPAD(NVL(TO_CHAR(v_medido, '90.99'), ' - '), 10) ||
            RPAD(TO_CHAR(v_tolerancia, '90.99'), 8) ||
            RPAD(TO_CHAR(v_desviacion, '90.99'), 8) ||
            RPAD(TO_CHAR(v_exceso, '90.99'), 8) ||
            v_estado_txt
        );
    END LOOP;
    CLOSE v_cursor;

    ROLLBACK;
END;
/
