-- ============================================================================
-- PROYECTO GEOVISION - MODULO DE VENTAS Y REPORTES
-- Objeto: PROCEDIMIENTO ALMACENADO 4 / 4
-- Nombre: SP_PROCESAR_VENTA_CON_DETALLE
-- Motor: Oracle Database 19c
-- Finalidad: Registro transaccional integral y optimo de una venta con su
--            detalle de productos en formato JSON, verificacion de stock con
--            bloqueo pesimista ordenado (anti-deadlock), calculo dinamico de
--            subtotales, reglas de negocio optometricas (RN-VE), generacion
--            de correlativo oficial, descarga de inventario, auditoria kardex
--            y liquidacion/pago inicial.
-- ============================================================================

CREATE OR REPLACE PROCEDURE SP_PROCESAR_VENTA_CON_DETALLE (
    p_id_empleado         IN  NUMBER,
    p_id_paciente         IN  NUMBER   DEFAULT NULL,
    p_id_receta           IN  NUMBER   DEFAULT NULL,
    p_tipo_comprobante    IN  NUMBER,
    p_items_json          IN  CLOB,
    p_monto_inicial_pago  IN  NUMBER   DEFAULT 0,
    p_metodo_pago         IN  NUMBER   DEFAULT 1,
    p_numero_operacion    IN  VARCHAR2 DEFAULT NULL,
    p_id_venta            OUT NUMBER,
    p_numero_comprobante  OUT VARCHAR2,
    p_total_calculado     OUT NUMBER,
    p_total_pagado        OUT NUMBER,
    p_saldo_pendiente     OUT NUMBER,
    p_estado_venta        OUT NUMBER,
    p_mensaje             OUT VARCHAR2
)
IS
    -- Variables para entidades maestras
    v_emp_activo          EMPLEADO.estado%TYPE;
    v_emp_usuario         EMPLEADO.id_usuario%TYPE;
    v_pac_activo          PACIENTE.estado%TYPE;
    v_rec_paciente        RECETA.id_paciente%TYPE;

    -- Variables de calculo monetario y correlativo
    v_total_acumulado     NUMBER(12,2) := 0;
    v_adelanto_minimo     NUMBER(12,2) := 0;
    v_saldo_calculado     NUMBER(12,2) := 0;
    v_estado_inicial      NUMBER;
    v_correlativo         VARCHAR2(100);
    v_id_venta_generada   NUMBER;
    v_cant_items          NUMBER := 0;

    -- Tipo registro y tabla en memoria para procesar items validados
    TYPE r_item_venta IS RECORD (
        id_producto       PRODUCTO.id_producto%TYPE,
        nombre_producto   PRODUCTO.nombre%TYPE,
        cantidad          NUMBER(10),
        precio_unitario   PRODUCTO.precio%TYPE,
        sub_total         NUMBER(12,2),
        stock_actual      PRODUCTO.stock%TYPE,
        stock_nuevo       NUMBER(10)
    );
    TYPE t_items_venta IS TABLE OF r_item_venta INDEX BY PLS_INTEGER;
    v_items_procesados    t_items_venta;

    -- Cursor 1: Parseo de JSON y agrupacion de cantidades por producto
    -- Se agrupa por id_producto para consolidar items repetidos en el payload
    CURSOR c_items_json IS
        SELECT 
            jt.id_producto,
            SUM(jt.cantidad) AS cantidad_total
        FROM JSON_TABLE(p_items_json, '$[*]'
            COLUMNS (
                id_producto NUMBER PATH '$.id_producto',
                cantidad    NUMBER PATH '$.cantidad'
            )
        ) jt
        GROUP BY jt.id_producto
        ORDER BY jt.id_producto ASC; -- Orden deterministico anti-deadlock

BEGIN
    -- ------------------------------------------------------------------------
    -- 1. VALIDACION DE EMPLEADO RESPONSABLE (Vendedor)
    -- ------------------------------------------------------------------------
    IF p_id_empleado IS NULL THEN
        RAISE_APPLICATION_ERROR(-20010, 'El ID del empleado vendedor es obligatorio.');
    END IF;

    BEGIN
        SELECT estado, id_usuario
        INTO v_emp_activo, v_emp_usuario
        FROM EMPLEADO
        WHERE id_persona = p_id_empleado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Empleado vendedor no encontrado con ID: ' || p_id_empleado);
    END;

    IF v_emp_activo != 1 THEN
        RAISE_APPLICATION_ERROR(-20010, 'El empleado vendedor no se encuentra activo en el sistema.');
    END IF;

    -- Fallback seguro para usuario de auditoria
    IF v_emp_usuario IS NULL THEN
        v_emp_usuario := 1;
    END IF;

    -- ------------------------------------------------------------------------
    -- 2. VALIDACION DEL TIPO DE COMPROBANTE
    -- ------------------------------------------------------------------------
    IF p_tipo_comprobante NOT IN (1, 2, 3) THEN
        RAISE_APPLICATION_ERROR(-20011, 'Tipo de comprobante invalido. Valores permitidos: 1 (Boleta), 2 (Factura), 3 (Nota de Venta).');
    END IF;

    -- ------------------------------------------------------------------------
    -- 3. VALIDACION DE CLIENTE / PACIENTE Y RECETA MEDICA (Reglas RN-VE02 / RN-VE03)
    -- ------------------------------------------------------------------------
    IF p_id_paciente IS NOT NULL THEN
        BEGIN
            SELECT estado
            INTO v_pac_activo
            FROM PACIENTE
            WHERE id_persona = p_id_paciente;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20012, 'Paciente no encontrado con ID: ' || p_id_paciente);
        END;

        IF v_pac_activo != 1 THEN
            RAISE_APPLICATION_ERROR(-20012, 'El paciente indicado se encuentra inactivo.');
        END IF;
    END IF;

    IF p_id_receta IS NOT NULL THEN
        IF p_id_paciente IS NULL THEN
            RAISE_APPLICATION_ERROR(-20013, 'RN-VE02: Toda venta asociada a una receta medica debe contar obligatoriamente con un paciente asignado.');
        END IF;

        BEGIN
            SELECT id_paciente
            INTO v_rec_paciente
            FROM RECETA
            WHERE id_receta = p_id_receta;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20013, 'Receta medica no encontrada con ID: ' || p_id_receta);
        END;

        IF v_rec_paciente != p_id_paciente THEN
            RAISE_APPLICATION_ERROR(-20013, 'RN-VE03: La receta medica Nro ' || p_id_receta || ' no pertenece al paciente indicado.');
        END IF;
    END IF;

    -- ------------------------------------------------------------------------
    -- 4. VALIDACION DEL PAYLOAD JSON Y EXISTENCIA DE ITEMS
    -- ------------------------------------------------------------------------
    IF p_items_json IS NULL OR DBMS_LOB.GETLENGTH(p_items_json) <= 2 THEN
        RAISE_APPLICATION_ERROR(-20014, 'El detalle de productos en formato JSON es obligatorio y no puede estar vacio.');
    END IF;

    -- ------------------------------------------------------------------------
    -- 5. BLOQUEO PESIMISTA ORDENADO, VALIDACION DE CATALOGO Y STOCK DISPONIBLE
    --    Se ordenan los IDs de producto ascendentemente para prevenir Deadlocks (ORA-00060).
    -- ------------------------------------------------------------------------
    FOR r_item IN c_items_json LOOP
        IF r_item.id_producto IS NULL OR r_item.cantidad_total <= 0 THEN
            RAISE_APPLICATION_ERROR(-20014, 'Cada item del detalle debe especificar un id_producto valido y cantidad mayor a cero.');
        END IF;

        v_cant_items := v_cant_items + 1;

        -- Variables temporales para el producto actual
        DECLARE
            v_prod_nombre   PRODUCTO.nombre%TYPE;
            v_prod_precio   PRODUCTO.precio%TYPE;
            v_prod_stock    PRODUCTO.stock%TYPE;
            v_prod_estado   PRODUCTO.estado%TYPE;
        BEGIN
            -- Bloqueo pesimista por fila (ROW-LEVEL LOCK) mediante FOR UPDATE
            SELECT nombre, precio, stock, estado
            INTO v_prod_nombre, v_prod_precio, v_prod_stock, v_prod_estado
            FROM PRODUCTO
            WHERE id_producto = r_item.id_producto
            FOR UPDATE;

            IF v_prod_estado != 1 THEN
                RAISE_APPLICATION_ERROR(-20015, 'El producto "' || v_prod_nombre || '" (ID: ' || r_item.id_producto || ') no esta activo para la venta.');
            END IF;

            IF v_prod_stock < r_item.cantidad_total THEN
                RAISE_APPLICATION_ERROR(-20015, 'RN-VE05: Stock insuficiente para el producto "' || v_prod_nombre || 
                                               '". Stock disponible: ' || v_prod_stock || ', Cantidad solicitada: ' || r_item.cantidad_total);
            END IF;

            -- Cargar en coleccion en memoria para posterior persistencia en lote
            v_items_procesados(v_cant_items).id_producto     := r_item.id_producto;
            v_items_procesados(v_cant_items).nombre_producto := v_prod_nombre;
            v_items_procesados(v_cant_items).cantidad        := r_item.cantidad_total;
            v_items_procesados(v_cant_items).precio_unitario := v_prod_precio;
            v_items_procesados(v_cant_items).sub_total       := ROUND(r_item.cantidad_total * v_prod_precio, 2);
            v_items_procesados(v_cant_items).stock_actual    := v_prod_stock;
            v_items_procesados(v_cant_items).stock_nuevo     := v_prod_stock - r_item.cantidad_total;

            v_total_acumulado := v_total_acumulado + v_items_procesados(v_cant_items).sub_total;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20015, 'Producto no registrado en el catalogo con ID: ' || r_item.id_producto);
        END;
    END LOOP;

    IF v_cant_items = 0 THEN
        RAISE_APPLICATION_ERROR(-20014, 'No se identificaron productos validos en el JSON proporcionado.');
    END IF;

    -- ------------------------------------------------------------------------
    -- 6. REGLAS FINANCIERAS Y DE CONDICION DE PAGO (RN-VE06, RN-VE07, RN-VE12, RN-VE13)
    -- ------------------------------------------------------------------------
    IF p_monto_inicial_pago < 0 THEN
        RAISE_APPLICATION_ERROR(-20016, 'El monto inicial de pago no puede ser negativo.');
    END IF;

    IF p_monto_inicial_pago > v_total_acumulado THEN
        RAISE_APPLICATION_ERROR(-20016, 'RN-VE13: El monto pagado (S/ ' || p_monto_inicial_pago || 
                                       ') no puede superar el total de la venta (S/ ' || v_total_acumulado || ').');
    END IF;

    -- Regla segun existencia de receta
    IF p_id_receta IS NULL THEN
        -- Venta directa en mostrador: exige pago total inmediato al 100%
        IF p_monto_inicial_pago < v_total_acumulado THEN
            RAISE_APPLICATION_ERROR(-20017, 'RN-VE06: Para ventas directas sin receta medica, se requiere cancelar el 100% del total (Monto requerido: S/ ' || v_total_acumulado || ').');
        END IF;
    ELSE
        -- Venta con receta optica: permite adelanto minimo del 25%
        v_adelanto_minimo := ROUND(v_total_acumulado * 0.25, 2);
        IF p_monto_inicial_pago < v_adelanto_minimo THEN
            RAISE_APPLICATION_ERROR(-20017, 'RN-VE07: En ventas con receta oftalmologica, el adelanto minimo requerido es del 25% (Minimo: S/ ' || v_adelanto_minimo || ').');
        END IF;
    END IF;

    -- Validacion de voucher para pagos electronicos
    IF p_monto_inicial_pago > 0 AND p_metodo_pago IN (2, 3, 4) THEN
        IF p_numero_operacion IS NULL OR TRIM(p_numero_operacion) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20018, 'RN-VE12: Para pagos mediante tarjeta o transferencia es obligatorio consignar el numero de operacion/voucher.');
        END IF;
    END IF;

    -- ------------------------------------------------------------------------
    -- 7. GENERACION DE CORRELATIVO Y DETERMINACION DE ESTADO
    -- ------------------------------------------------------------------------
    v_correlativo := FN_GENERAR_CORRELATIVO_COMPROBANTE(p_tipo_comprobante);

    IF p_monto_inicial_pago >= v_total_acumulado THEN
        v_estado_inicial := 2; -- PAGADA
    ELSE
        v_estado_inicial := 1; -- PENDIENTE
    END IF;

    -- ------------------------------------------------------------------------
    -- 8. PERSISTENCIA DE CABECERA VENTA
    -- ------------------------------------------------------------------------
    INSERT INTO VENTA (
        fecha_registro, total, estado, numero_comprobante,
        tipo_comprobante, id_empleado, id_paciente, id_receta
    ) VALUES (
        SYSDATE, v_total_acumulado, v_estado_inicial, v_correlativo,
        p_tipo_comprobante, p_id_empleado, p_id_paciente, p_id_receta
    ) RETURNING id_venta INTO v_id_venta_generada;

    -- ------------------------------------------------------------------------
    -- 9. PERSISTENCIA DE DETALLE PRODUCTO_VENDIDO, DESCARGA DE STOCK Y KARDEX
    -- ------------------------------------------------------------------------
    FOR i IN 1 .. v_items_procesados.COUNT LOOP
        -- a. Registrar auditoria de salida en MOVIMIENTO_STOCK_LOG (motivo 5 = SALIDA_POR_VENTA)
        --    Se registra con la referencia de comprobante para coordinar con TRG_DESCONTAR_STOCK_POR_VENTA
        INSERT INTO MOVIMIENTO_STOCK_LOG (
            fecha_registro, cantidad, stock_previo, stock_posterior,
            motivo, observaciones, id_producto, id_usuario
        ) VALUES (
            SYSDATE, v_items_procesados(i).cantidad, v_items_procesados(i).stock_actual,
            v_items_procesados(i).stock_nuevo, 5,
            'Salida automatica por venta comprobante ID: ' || v_id_venta_generada || ' (' || v_correlativo || ')',
            v_items_procesados(i).id_producto, v_emp_usuario
        );

        -- b. Actualizar stock del producto en la entidad maestra
        UPDATE PRODUCTO
        SET stock = v_items_procesados(i).stock_nuevo
        WHERE id_producto = v_items_procesados(i).id_producto;

        -- c. Insertar registro de linea vendida
        INSERT INTO PRODUCTO_VENDIDO (
            cantidad, precio_unit, sub_total, id_venta, id_producto
        ) VALUES (
            v_items_procesados(i).cantidad,
            v_items_procesados(i).precio_unitario,
            v_items_procesados(i).sub_total,
            v_id_venta_generada,
            v_items_procesados(i).id_producto
        );
    END LOOP;

    -- ------------------------------------------------------------------------
    -- 10. PERSISTENCIA DE PAGO INICIAL (Si aplica)
    -- ------------------------------------------------------------------------
    IF p_monto_inicial_pago > 0 THEN
        INSERT INTO PAGO (
            fecha_registro, numero_operacion, monto, metodo_pago, id_venta
        ) VALUES (
            SYSDATE, p_numero_operacion, p_monto_inicial_pago, p_metodo_pago, v_id_venta_generada
        );
    END IF;

    -- ------------------------------------------------------------------------
    -- 11. CALCULO DE RESULTADOS Y PARAMETROS DE SALIDA
    -- ------------------------------------------------------------------------
    v_saldo_calculado := v_total_acumulado - p_monto_inicial_pago;
    IF v_saldo_calculado < 0 THEN
        v_saldo_calculado := 0;
    END IF;

    p_id_venta           := v_id_venta_generada;
    p_numero_comprobante := v_correlativo;
    p_total_calculado    := v_total_acumulado;
    p_total_pagado       := p_monto_inicial_pago;
    p_saldo_pendiente    := v_saldo_calculado;
    p_estado_venta       := v_estado_inicial;
    p_mensaje            := 'Venta procesada exitosamente. Comprobante: ' || v_correlativo || 
                            ', Items: ' || v_cant_items || 
                            ', Total: S/ ' || TO_CHAR(v_total_acumulado, 'FM999,990.00') || 
                            ', Saldo: S/ ' || TO_CHAR(v_saldo_calculado, 'FM999,990.00');

    -- Nota de transaccionalidad:
    -- Se prescinde de COMMIT explicito en el cuerpo para respetar el estandar del proyecto,
    -- permitiendo la gestion atomica desde Spring Boot (@Transactional) o transacciones compuestas.
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_PROCESAR_VENTA_CON_DETALLE;
/
