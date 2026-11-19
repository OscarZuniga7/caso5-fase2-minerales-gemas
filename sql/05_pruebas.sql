-- Pruebas que deben ejecutarse y fotografiarse EN MySQL Workbench.
-- Usar tras cargar sql/00_integral.sql. No ejecutar DROP en una BD con trabajo nuevo.
USE coleccion_db;

-- 1. Estructura, datos y coherencia
SHOW TABLES;
SELECT 'COLECCION' AS tabla, COUNT(*) AS filas FROM COLECCION
UNION ALL SELECT 'PIEZA',COUNT(*) FROM PIEZA
UNION ALL SELECT 'CLIENTE',COUNT(*) FROM CLIENTE
UNION ALL SELECT 'VENTA',COUNT(*) FROM VENTA
UNION ALL SELECT 'DETALLE_VENTA',COUNT(*) FROM DETALLE_VENTA
UNION ALL SELECT 'EVALUACION',COUNT(*) FROM EVALUACION;

SELECT COUNT(*) AS ventas_con_total_distinto_del_detalle
FROM VENTA v JOIN
 (SELECT idVenta,ROUND(SUM(precioVenta),2) AS total FROM DETALLE_VENTA GROUP BY idVenta) x
 ON x.idVenta=v.idVenta
WHERE ABS(v.montoTotal-x.total)>0.01;

SELECT COUNT(*) AS piezas_con_mas_de_un_subtipo
FROM PIEZA p LEFT JOIN MINERAL m ON m.idPieza=p.idPieza
LEFT JOIN FOSIL f ON f.idPieza=p.idPieza LEFT JOIN GEMA g ON g.idPieza=p.idPieza
WHERE (m.idPieza IS NOT NULL)+(f.idPieza IS NOT NULL)+(g.idPieza IS NOT NULL)>1;

-- 2. Las seis vistas oficiales (R2,R3,R5,R6,R7,R8)
SELECT * FROM v_r2_distribucion_tipo_coleccion ORDER BY idColeccion,tipoPieza LIMIT 50;
SELECT * FROM v_r3_monto_vs_evaluacion ORDER BY fechaVenta DESC LIMIT 25;
SELECT * FROM v_r5_proporcion_vendida_coleccion ORDER BY porcentajeComercializacion DESC;
SELECT * FROM v_r6_ingreso_pieza_coleccion_tipo ORDER BY ingresoAcumulado DESC LIMIT 25;
SELECT * FROM v_r7_exposiciones_diversidad_ventas ORDER BY piezasDistintasExhibidas DESC;
SELECT * FROM v_r8_clientes_compras_monto ORDER BY montoTotalPagado DESC LIMIT 25;

-- 3. Los seis procedimientos oficiales (R1,R4,R9,R10,R11,R12)
CALL sp_r1_colecciones_mayor_monto('2023-01-01','2026-12-31');
CALL sp_r4_colecciones_piezas_clientes('2023-01-01','2026-12-31');
CALL sp_r9_ventas_sobre_promedio_coleccion('COL001','2023-01-01','2026-12-31');
CALL sp_r10_piezas_sobre_promedio_tipo('Mineral');
CALL sp_r11_clientes_sobre_promedio('2023-01-01','2026-12-31');
CALL sp_r12_colecciones_sobre_promedio_general('2023-01-01','2026-12-31');

-- 4. Comprobar exactamente seis vistas y seis procedimientos
SELECT ROUTINE_NAME,ROUTINE_TYPE FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA='coleccion_db' ORDER BY ROUTINE_NAME;
SELECT TABLE_NAME FROM information_schema.VIEWS
WHERE TABLE_SCHEMA='coleccion_db' ORDER BY TABLE_NAME;
