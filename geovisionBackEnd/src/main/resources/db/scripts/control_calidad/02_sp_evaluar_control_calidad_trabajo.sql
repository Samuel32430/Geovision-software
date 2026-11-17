-- ============================================================================
-- PROYECTO GEOVISION - MODULO DE CONTROL DE CALIDAD Y ORDENES DE TRABAJO
-- Archivo: 02_sp_evaluar_control_calidad_trabajo.sql
-- Motor: Oracle Database 19c
-- Proposito: Procedimiento complejo de evaluacion automatica de lensometria,
--            calculo de desviaciones y excesos frente a tolerancias, determinacion
--            de aprobacion individual/conjunta y persistencia transaccional.
-- ============================================================================

CREATE OR REPLACE PROCEDURE SP_EVALUAR_CONTROL_CALIDAD_TRABAJO (
    p_id_envio_laboratorio      IN  NUMBER,
    p_id_usuario                IN  NUMBER,
    p_medidas_control_json      IN  CLOB,
    p_observaciones             IN  VARCHAR2 DEFAULT NULL,
    p_tol_dioptrias_custom      IN  NUMBER   DEFAULT NULL,
    p_tol_eje_custom            IN  NUMBER   DEFAULT NULL,
    p_tol_dp_custom             IN  NUMBER   DEFAULT NULL,
    p_tol_prisma_custom         IN  NUMBER   DEFAULT NULL,
    p_aprobado_global           OUT NUMBER,
    p_total_medidas_evaluadas   OUT NUMBER,
    p_medidas_aprobadas         OUT NUMBER,
    p_medidas_rechazadas        OUT NUMBER,
    p_resumen_dictamen          OUT VARCHAR2,
    p_cursor_detalle            OUT SYS_REFCURSOR
)
IS
    -- Variables de control de orden y envio
    v_id_orden_trabajo          ORDEN_TRABAJO.id_orden_trabajo%TYPE;
    v_id_lente                  ORDEN_TRABAJO.id_lente%TYPE;
    v_id_receta                 LENTE.id_receta%TYPE;
    v_estado_ot                 ORDEN_TRABAJO.estado%TYPE;
    v_fecha_recepcion           ENVIO_LABORATORIO.fecha_recepcion%TYPE;
    v_fecha_revision            ENVIO_LABORATORIO.fecha_revision%TYPE;
    v_aprobado_actual           ENVIO_LABORATORIO.aprobado%TYPE;
    v_obs_actuales              ENVIO_LABORATORIO.observaciones%TYPE;
    v_nombre_usuario            VARCHAR2(100);

    -- Tolerancias efectivas
    v_tol_dioptrias             NUMBER(5,2);
    v_tol_eje                   NUMBER(5,2);
    v_tol_dp                    NUMBER(5,2);
    v_tol_prisma                NUMBER(5,2);

    -- Contadores y banderas
    v_cant_medidas_receta       NUMBER := 0;
    v_cant_medidas_control      NUMBER := 0;
    v_medida_aprobada           NUMBER(1);
    v_exceso_max_medida         NUMBER(5,2);
    v_nuevo_estado_ot           NUMBER;
    v_constancia                VARCHAR2(1000);

    -- Claves primarias generadas para medidas de taller
    v_id_ojo_der_nuevo          NUMBER;
    v_id_ojo_izq_nuevo          NUMBER;
    v_id_medida_nueva           NUMBER;

    -- Cursor con las medidas de control provistas en formato JSON
    CURSOR c_control IS
        SELECT 
            jt.tipo_medida,
            jt.distancia_pupilar,
            jt.prisma,
            jt.observaciones,
            jt.od_agudeza_visual,
            jt.od_esfera,
            jt.od_cilindro,
            jt.od_eje,
            jt.od_adicion,
            jt.oi_agudeza_visual,
            jt.oi_esfera,
            jt.oi_cilindro,
            jt.oi_eje,
            jt.oi_adicion
        FROM JSON_TABLE(p_medidas_control_json, '$[*]'
            COLUMNS (
                tipo_medida         NUMBER          PATH '$.tipo_medida',
                distancia_pupilar   NUMBER          PATH '$.distancia_pupilar',
                prisma              NUMBER          PATH '$.prisma',
                observaciones       VARCHAR2(255)   PATH '$.observaciones',
                od_agudeza_visual   VARCHAR2(50)    PATH '$.ojo_derecho.agudeza_visual',
                od_esfera           NUMBER          PATH '$.ojo_derecho.esfera',
                od_cilindro         NUMBER          PATH '$.ojo_derecho.cilindro',
                od_eje              NUMBER          PATH '$.ojo_derecho.eje',
                od_adicion          NUMBER          PATH '$.ojo_derecho.adicion',
                oi_agudeza_visual   VARCHAR2(50)    PATH '$.ojo_izquierdo.agudeza_visual',
                oi_esfera           NUMBER          PATH '$.ojo_izquierdo.esfera',
                oi_cilindro         NUMBER          PATH '$.ojo_izquierdo.cilindro',
                oi_eje              NUMBER          PATH '$.ojo_izquierdo.eje',
                oi_adicion          NUMBER          PATH '$.ojo_izquierdo.adicion'
            )
        ) jt;

    -- Registro auxiliar de receta para comparacion
    TYPE r_receta_medida IS RECORD (
        id_medida           NUMBER,
        tipo_medida         NUMBER,
        distancia_pupilar   NUMBER,
        prisma              NUMBER,
        od_esfera           NUMBER,
        od_cilindro         NUMBER,
        od_eje              NUMBER,
        od_adicion          NUMBER,
        oi_esfera           NUMBER,
        oi_cilindro         NUMBER,
        oi_eje              NUMBER,
        oi_adicion          NUMBER
    );
    v_ref r_receta_medida;

    -- Procedimiento local para registrar y auditar cada parametro individual
    PROCEDURE EVALUAR_PARAMETRO (
        p_tipo_medida IN NUMBER,
        p_ojo         IN VARCHAR2,
        p_parametro   IN VARCHAR2,
        p_val_receta  IN NUMBER,
        p_val_medido  IN NUMBER,
        p_tolerancia  IN NUMBER,
        p_es_eje      IN BOOLEAN DEFAULT FALSE,
        io_aprobado   IN OUT NUMBER(1),
        io_exceso_max IN OUT NUMBER
    )
    IS
        v_desviacion NUMBER(5,2) := 0;
        v_exceso     NUMBER(5,2) := 0;
        v_param_ok   NUMBER(1) := 1;
        v_diff_raw   NUMBER;
    BEGIN
        -- Caso 1: Parametro angular (Eje astigmatico: escala circular de 180 grados)
        IF p_es_eje THEN
            IF p_val_receta IS NULL OR p_val_medido IS NULL THEN
                v_param_ok := 0;
                v_desviacion := 180;
                v_exceso := 180 - p_tolerancia;
            ELSE
                v_diff_raw := ABS(p_val_receta - p_val_medido);
                v_desviacion := LEAST(v_diff_raw, 180 - v_diff_raw);
                IF v_desviacion > p_tolerancia THEN
                    v_exceso := v_desviacion - p_tolerancia;
                    v_param_ok := 0;
                ELSE
                    v_exceso := 0;
                    v_param_ok := 1;
                END IF;
            END IF;
        -- Caso 2: Parametros de potencia o distancias lineales (Esfera, Cilindro, Adicion, DP, Prisma)
        ELSE
            IF p_val_receta IS NULL THEN
                IF p_val_medido IS NULL OR p_val_medido = 0 THEN
                    v_desviacion := 0;
                    v_exceso := 0;
                    v_param_ok := 1;
                ELSE
                    v_desviacion := ABS(p_val_medido);
                    v_exceso := GREATEST(0, v_desviacion - p_tolerancia);
                    v_param_ok := CASE WHEN v_desviacion <= p_tolerancia THEN 1 ELSE 0 END;
                END IF;
            ELSE
                IF p_val_medido IS NULL THEN
                    v_param_ok := 0;
                    v_desviacion := 99.99;
                    v_exceso := 99.99;
                ELSE
                    v_desviacion := ABS(p_val_receta - p_val_medido);
                    IF v_desviacion > p_tolerancia THEN
                        v_exceso := v_desviacion - p_tolerancia;
                        v_param_ok := 0;
                    ELSE
                        v_exceso := 0;
                        v_param_ok := 1;
                    END IF;
                END IF;
            END IF;
        END IF;

        -- Actualizar acumuladores de la medida
        IF v_param_ok = 0 THEN
            io_aprobado := 0;
        END IF;
        IF v_exceso > io_exceso_max THEN
            io_exceso_max := v_exceso;
        END IF;

        -- Registrar en la tabla de detalle y auditoria de control de calidad
        INSERT INTO DETALLE_CONTROL_CALIDAD (
            id_envio_laboratorio, tipo_medida, ojo, parametro,
            valor_receta, valor_medido, tolerancia_aplicada,
            desviacion, exceso, aprobado, fecha_registro
        ) VALUES (
            p_id_envio_laboratorio, p_tipo_medida, p_ojo, p_parametro,
            p_val_receta, p_val_medido, p_tolerancia,
            v_desviacion, v_exceso, v_param_ok, SYSDATE
        );
    END EVALUAR_PARAMETRO;

BEGIN
    -- ------------------------------------------------------------------------
    -- 1. VALIDACION DE PRECONDICIONES Y BLOQUEO PESIMISTA
    -- ------------------------------------------------------------------------
    IF p_id_envio_laboratorio IS NULL THEN
        RAISE_APPLICATION_ERROR(-20020, 'El ID de envio a laboratorio es obligatorio.');
    END IF;

    IF p_medidas_control_json IS NULL OR DBMS_LOB.GETLENGTH(p_medidas_control_json) = 0 THEN
        RAISE_APPLICATION_ERROR(-20021, 'Debe proporcionar el payload JSON con las medidas tomadas en el negocio.');
    END IF;

    -- Obtener nombre del usuario auditor
    BEGIN
        SELECT nombre INTO v_nombre_usuario FROM USUARIO WHERE id_usuario = p_id_usuario;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_nombre_usuario := 'USUARIO-' || TO_CHAR(p_id_usuario);
    END;

    -- Bloqueo pesimista del envio y de la orden de trabajo para garantizar atomicidad
    BEGIN
        SELECT 
            el.id_orden_trabajo,
            ot.id_lente,
            l.id_receta,
            ot.estado,
            el.fecha_recepcion,
            el.fecha_revision,
            el.aprobado,
            el.observaciones,
            NVL(el.tolerancia_dioptrias, 0.25),
            NVL(el.tolerancia_eje_grados, 4.00),
            NVL(el.tolerancia_dp_mm, 1.00),
            NVL(el.tolerancia_prisma, 0.25)
        INTO 
            v_id_orden_trabajo,
            v_id_lente,
            v_id_receta,
            v_estado_ot,
            v_fecha_recepcion,
            v_fecha_revision,
            v_aprobado_actual,
            v_obs_actuales,
            v_tol_dioptrias,
            v_tol_eje,
            v_tol_dp,
            v_tol_prisma
        FROM ENVIO_LABORATORIO el
        JOIN ORDEN_TRABAJO ot ON el.id_orden_trabajo = ot.id_orden_trabajo
        JOIN LENTE l ON ot.id_lente = l.id_lente
        WHERE el.id_envio_laboratorio = p_id_envio_laboratorio
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20022, 'Envio a laboratorio no encontrado o no vinculado a una orden valida.');
    END;

    -- Validacion de estados de negocio
    IF v_fecha_recepcion IS NULL THEN
        RAISE_APPLICATION_ERROR(-20023, 'El envio no ha sido recibido aun del laboratorio (fecha_recepcion es nula).');
    END IF;

    IF v_estado_ot != 3 THEN -- 3: RECIBIDO_LABORATORIO
        RAISE_APPLICATION_ERROR(-20024, 'La orden de trabajo debe estar en estado RECIBIDO_LABORATORIO (3). Estado actual: ' || v_estado_ot);
    END IF;

    IF v_fecha_revision IS NOT NULL OR v_aprobado_actual IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20025, 'Este envio ya cuenta con una evaluacion registrada. Para reevaluar debe registrar un nuevo reenvio.');
    END IF;

    -- Aplicar tolerancias personalizadas si fueron provistas por el usuario
    v_tol_dioptrias := NVL(p_tol_dioptrias_custom, v_tol_dioptrias);
    v_tol_eje       := NVL(p_tol_eje_custom, v_tol_eje);
    v_tol_dp        := NVL(p_tol_dp_custom, v_tol_dp);
    v_tol_prisma    := NVL(p_tol_prisma_custom, v_tol_prisma);

    -- ------------------------------------------------------------------------
    -- 2. VALIDACION DE CANTIDAD DE MEDIDAS (RECETA VS CONTROL)
    -- ------------------------------------------------------------------------
    SELECT COUNT(m.id_medida) INTO v_cant_medidas_receta
    FROM MEDIDA m
    WHERE m.id_medida IN (
        SELECT lm.id_medida FROM LENTE_MEDIDA lm WHERE lm.id_lente = v_id_lente
    ) OR (
        NOT EXISTS (SELECT 1 FROM LENTE_MEDIDA lm WHERE lm.id_lente = v_id_lente)
        AND m.id_receta = v_id_receta AND m.id_envio_laboratorio IS NULL
    );

    IF v_cant_medidas_receta = 0 THEN
        RAISE_APPLICATION_ERROR(-20026, 'El trabajo/lente no cuenta con medidas clinicas registradas en la receta para contrastar.');
    END IF;

    SELECT COUNT(*) INTO v_cant_medidas_control
    FROM JSON_TABLE(p_medidas_control_json, '$[*]' COLUMNS (tipo_medida NUMBER PATH '$.tipo_medida'));

    IF v_cant_medidas_control != v_cant_medidas_receta THEN
        RAISE_APPLICATION_ERROR(-20027, 'Discrepancia en cantidad de medidas: La receta prescribe ' 
            || v_cant_medidas_receta || ' tipo(s) de medida pero el control envio ' || v_cant_medidas_control || '.');
    END IF;

    -- Inicializacion de acumuladores globales
    p_aprobado_global := 1;
    p_total_medidas_evaluadas := 0;
    p_medidas_aprobadas := 0;
    p_medidas_rechazadas := 0;

    -- Limpiar evaluaciones previas residuales si existieran para este envio
    DELETE FROM DETALLE_CONTROL_CALIDAD WHERE id_envio_laboratorio = p_id_envio_laboratorio;

    -- ------------------------------------------------------------------------
    -- 3. EVALUACION PARAMETRO POR PARAMETRO MEDIDA A MEDIDA
    -- ------------------------------------------------------------------------
    FOR r_ctrl IN c_control LOOP
        p_total_medidas_evaluadas := p_total_medidas_evaluadas + 1;
        v_medida_aprobada := 1;
        v_exceso_max_medida := 0;

        -- Buscar la medida de receta correspondiente al tipo de medida actual (1: Lejos, 2: Medio, 3: Cerca)
        BEGIN
            SELECT 
                m.id_medida,
                m.tipo_medida,
                m.distancia_pupilar,
                m.prisma,
                od.esfera,
                od.cilindro,
                od.eje,
                od.adicion,
                oi.esfera,
                oi.cilindro,
                oi.eje,
                oi.adicion
            INTO v_ref
            FROM MEDIDA m
            LEFT JOIN MEDIDA_OJO od ON m.id_medida_ojo_derecha = od.id_medida_ojo
            LEFT JOIN MEDIDA_OJO oi ON m.id_medida_ojo_izquierda = oi.id_medida_ojo
            WHERE m.tipo_medida = r_ctrl.tipo_medida
              AND (
                  m.id_medida IN (SELECT lm.id_medida FROM LENTE_MEDIDA lm WHERE lm.id_lente = v_id_lente)
                  OR (
                      NOT EXISTS (SELECT 1 FROM LENTE_MEDIDA lm WHERE lm.id_lente = v_id_lente)
                      AND m.id_receta = v_id_receta AND m.id_envio_laboratorio IS NULL
                  )
              )
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20028, 'El tipo de medida ' || r_ctrl.tipo_medida || ' no corresponde a la receta de este trabajo.');
        END;

        -- Validaciones de rango fisico basico en los datos tomados en taller
        IF r_ctrl.distancia_pupilar IS NULL OR r_ctrl.distancia_pupilar <= 0 THEN
            RAISE_APPLICATION_ERROR(-20029, 'La distancia pupilar debe ser positiva en tipo_medida: ' || r_ctrl.tipo_medida);
        END IF;

        IF r_ctrl.od_eje IS NOT NULL AND (r_ctrl.od_eje < 0 OR r_ctrl.od_eje > 180) THEN
            RAISE_APPLICATION_ERROR(-20030, 'Eje de Ojo Derecho fuera de rango (0-180) en tipo_medida: ' || r_ctrl.tipo_medida);
        END IF;

        IF r_ctrl.oi_eje IS NOT NULL AND (r_ctrl.oi_eje < 0 OR r_ctrl.oi_eje > 180) THEN
            RAISE_APPLICATION_ERROR(-20031, 'Eje de Ojo Izquierdo fuera de rango (0-180) en tipo_medida: ' || r_ctrl.tipo_medida);
        END IF;

        -- --------------------------------------------------------------------
        -- A. EVALUAR OJO DERECHO (OD)
        -- --------------------------------------------------------------------
        EVALUAR_PARAMETRO(r_ctrl.tipo_medida, 'OD', 'ESFERA',   v_ref.od_esfera,   r_ctrl.od_esfera,   v_tol_dioptrias, FALSE, v_medida_aprobada, v_exceso_max_medida);
        EVALUAR_PARAMETRO(r_ctrl.tipo_medida, 'OD', 'CILINDRO', v_ref.od_cilindro, r_ctrl.od_cilindro, v_tol_dioptrias, FALSE, v_medida_aprobada, v_exceso_max_medida);
        EVALUAR_PARAMETRO(r_ctrl.tipo_medida, 'OD', 'EJE',      v_ref.od_eje,      r_ctrl.od_eje,      v_tol_eje,       TRUE,  v_medida_aprobada, v_exceso_max_medida);
        EVALUAR_PARAMETRO(r_ctrl.tipo_medida, 'OD', 'ADICION',  v_ref.od_adicion,  r_ctrl.od_adicion,  v_tol_dioptrias, FALSE, v_medida_aprobada, v_exceso_max_medida);

        -- --------------------------------------------------------------------
        -- B. EVALUAR OJO IZQUIERDO (OI)
        -- --------------------------------------------------------------------
        EVALUAR_PARAMETRO(r_ctrl.tipo_medida, 'OI', 'ESFERA',   v_ref.oi_esfera,   r_ctrl.oi_esfera,   v_tol_dioptrias, FALSE, v_medida_aprobada, v_exceso_max_medida);
        EVALUAR_PARAMETRO(r_ctrl.tipo_medida, 'OI', 'CILINDRO', v_ref.oi_cilindro, r_ctrl.oi_cilindro, v_tol_dioptrias, FALSE, v_medida_aprobada, v_exceso_max_medida);
        EVALUAR_PARAMETRO(r_ctrl.tipo_medida, 'OI', 'EJE',      v_ref.oi_eje,      r_ctrl.oi_eje,      v_tol_eje,       TRUE,  v_medida_aprobada, v_exceso_max_medida);
        EVALUAR_PARAMETRO(r_ctrl.tipo_medida, 'OI', 'ADICION',  v_ref.oi_adicion,  r_ctrl.oi_adicion,  v_tol_dioptrias, FALSE, v_medida_aprobada, v_exceso_max_medida);

        -- --------------------------------------------------------------------
        -- C. EVALUAR PARAMETROS GLOBALES / MONTURA (DP Y PRISMA)
        -- --------------------------------------------------------------------
        EVALUAR_PARAMETRO(r_ctrl.tipo_medida, 'AO', 'DISTANCIA_PUPILAR', v_ref.distancia_pupilar, r_ctrl.distancia_pupilar, v_tol_dp,     FALSE, v_medida_aprobada, v_exceso_max_medida);
        EVALUAR_PARAMETRO(r_ctrl.tipo_medida, 'AO', 'PRISMA',            v_ref.prisma,            r_ctrl.prisma,            v_tol_prisma, FALSE, v_medida_aprobada, v_exceso_max_medida);

        -- Acumular estado de la medida
        IF v_medida_aprobada = 1 THEN
            p_medidas_aprobadas := p_medidas_aprobadas + 1;
        ELSE
            p_medidas_rechazadas := p_medidas_rechazadas + 1;
            p_aprobado_global := 0; -- Si una sola medida falla, se rechaza el trabajo en su conjunto
        END IF;

        -- --------------------------------------------------------------------
        -- D. PERSISTENCIA DE LA MEDIDA REALIZADA EN EL TALLER
        -- --------------------------------------------------------------------
        -- Ojo Derecho
        INSERT INTO MEDIDA_OJO (agudeza_visual, esfera, cilindro, eje, adicion)
        VALUES (r_ctrl.od_agudeza_visual, r_ctrl.od_esfera, r_ctrl.od_cilindro, r_ctrl.od_eje, r_ctrl.od_adicion)
        RETURNING id_medida_ojo INTO v_id_ojo_der_nuevo;

        -- Ojo Izquierdo
        INSERT INTO MEDIDA_OJO (agudeza_visual, esfera, cilindro, eje, adicion)
        VALUES (r_ctrl.oi_agudeza_visual, r_ctrl.oi_esfera, r_ctrl.oi_cilindro, r_ctrl.oi_eje, r_ctrl.oi_adicion)
        RETURNING id_medida_ojo INTO v_id_ojo_izq_nuevo;

        -- Registro en MEDIDA asociada al envio (sin alterar receta clinica)
        INSERT INTO MEDIDA (
            tipo_medida, distancia_pupilar, prisma, observaciones,
            id_receta, id_medida_ojo_derecha, id_medida_ojo_izquierda,
            id_envio_laboratorio, aprobado, exceso_maximo
        ) VALUES (
            r_ctrl.tipo_medida, r_ctrl.distancia_pupilar, r_ctrl.prisma, r_ctrl.observaciones,
            NULL, v_id_ojo_der_nuevo, v_id_ojo_izq_nuevo,
            p_id_envio_laboratorio, v_medida_aprobada, v_exceso_max_medida
        ) RETURNING id_medida INTO v_id_medida_nueva;

    END LOOP;

    -- ------------------------------------------------------------------------
    -- 4. DETERMINACION DEL DICTAMEN FINAL Y ACTUALIZACIONES DE ESTADO
    -- ------------------------------------------------------------------------
    -- Regla de negocio:
    -- Si Aprobado  -> ORDEN_TRABAJO pasa a estado 6 (LISTO_ENTREGA)
    -- Si Rechazado -> ORDEN_TRABAJO pasa a estado 5 (CONTROL_CALIDAD_RECHAZADO)
    IF p_aprobado_global = 1 THEN
        v_nuevo_estado_ot := 6; -- LISTO_ENTREGA
        p_resumen_dictamen := 'CONTROL DE CALIDAD APROBADO: ' || p_medidas_aprobadas || ' de ' || p_total_medidas_evaluadas || ' medidas dentro de tolerancia.';
    ELSE
        v_nuevo_estado_ot := 5; -- CONTROL_CALIDAD_RECHAZADO
        p_resumen_dictamen := 'CONTROL DE CALIDAD RECHAZADO: ' || p_medidas_rechazadas || ' medida(s) superaron la tolerancia permitida.';
    END IF;

    -- Construir constancia formal para el historico de observaciones
    v_constancia := '[Calidad ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI') || '] '
        || 'Auditor: ' || v_nombre_usuario || '. '
        || (CASE WHEN p_aprobado_global = 1 THEN 'APROBADO' ELSE 'RECHAZADO' END)
        || '. Margenes: Dioptrias=' || TO_CHAR(v_tol_dioptrias, '0.00')
        || ', Eje=' || TO_CHAR(v_tol_eje, '0.0') || 'deg'
        || ', DP=' || TO_CHAR(v_tol_dp, '0.00') || 'mm'
        || ', Prisma=' || TO_CHAR(v_tol_prisma, '0.00')
        || CASE WHEN p_observaciones IS NOT NULL THEN '. Obs: ' || p_observaciones ELSE '' END;

    -- Actualizar cabecera de ENVIO_LABORATORIO
    UPDATE ENVIO_LABORATORIO
    SET fecha_revision          = SYSDATE,
        tolerancia              = v_tol_dioptrias,
        tolerancia_dioptrias    = v_tol_dioptrias,
        tolerancia_eje_grados   = v_tol_eje,
        tolerancia_dp_mm        = v_tol_dp,
        tolerancia_prisma       = v_tol_prisma,
        aprobado                = p_aprobado_global,
        observaciones           = CASE 
                                    WHEN v_obs_actuales IS NULL THEN v_constancia 
                                    ELSE v_obs_actuales || ' | ' || v_constancia 
                                  END
    WHERE id_envio_laboratorio = p_id_envio_laboratorio;

    -- Actualizar cabecera de ORDEN_TRABAJO
    UPDATE ORDEN_TRABAJO
    SET estado = v_nuevo_estado_ot
    WHERE id_orden_trabajo = v_id_orden_trabajo;

    -- ------------------------------------------------------------------------
    -- 5. APERTURA DE CURSOR CON EL REPORTE DETALLADO
    -- ------------------------------------------------------------------------
    OPEN p_cursor_detalle FOR
        SELECT 
            d.id_detalle_cc,
            d.tipo_medida,
            CASE d.tipo_medida 
                WHEN 1 THEN 'LEJOS' 
                WHEN 2 THEN 'MEDIO' 
                WHEN 3 THEN 'CERCA' 
                ELSE 'OTRO' 
            END AS nombre_tipo_medida,
            d.ojo,
            d.parametro,
            d.valor_receta,
            d.valor_medido,
            d.tolerancia_aplicada,
            d.desviacion,
            d.exceso,
            d.aprobado AS cumple_tolerancia,
            CASE d.aprobado WHEN 1 THEN 'CUMPLE' ELSE 'EXCEDE' END AS estado_parametro
        FROM DETALLE_CONTROL_CALIDAD d
        WHERE d.id_envio_laboratorio = p_id_envio_laboratorio
        ORDER BY d.id_detalle_cc ASC;

EXCEPTION
    WHEN OTHERS THEN
        IF c_control%ISOPEN THEN
            CLOSE c_control;
        END IF;
        ROLLBACK;
        RAISE;
END SP_EVALUAR_CONTROL_CALIDAD_TRABAJO;
/
