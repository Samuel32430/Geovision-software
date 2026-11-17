-- ============================================================================
-- PROYECTO GEOVISION - SCRIPT MAESTRO DE CONTROL DE CALIDAD
-- Esquema: geovisionBackEnd (Oracle Database 19c)
-- Ejecutar en: Oracle SQL Developer / SQL*Plus
-- ============================================================================

SET SERVEROUTPUT ON;
PROMPT >>> INICIANDO INSTALACION DEL MODULO DE CONTROL DE CALIDAD...

PROMPT >>> [1/2] Ejecutando DDL de Optimizacion y Auditoria (01_ddl_optimizacion_control_calidad.sql)...
@@01_ddl_optimizacion_control_calidad.sql;

PROMPT >>> [2/2] Creando Procedimiento Almacenado Complejo (02_sp_evaluar_control_calidad_trabajo.sql)...
@@02_sp_evaluar_control_calidad_trabajo.sql;

PROMPT >>> INSTALACION DE CONTROL DE CALIDAD COMPLETADA EXITOSAMENTE.
COMMIT;
