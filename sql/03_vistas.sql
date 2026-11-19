-- 03_vistas.sql : 6 vistas (R2, R3, R5, R6, R7, R8)
SET NAMES utf8mb4;
USE coleccion_db;

-- R2 ¿Cómo se distribuyen las piezas comercializadas entre minerales, fósiles y gemas, por colección?
CREATE OR REPLACE VIEW v_r2_distribucion_tipo_coleccion AS
SELECT c.idColeccion, c.nombreColeccion,
       CASE WHEN m.idPieza IS NOT NULL THEN 'Mineral' WHEN f.idPieza IS NOT NULL THEN 'Fosil'
            WHEN g.idPieza IS NOT NULL THEN 'Gema' ELSE 'Sin clasificar' END AS tipoPieza,
       COUNT(DISTINCT p.idPieza)  AS piezasDistintasVendidas,
       COUNT(dv.nroCorrelativo)   AS unidadesVendidas,
       SUM(dv.precioVenta)        AS montoVendido,
       ROUND(100 * COUNT(dv.nroCorrelativo) / SUM(COUNT(dv.nroCorrelativo)) OVER (PARTITION BY c.idColeccion), 2) AS pctDentroColeccion
FROM COLECCION c
JOIN PIEZA p          ON p.idColeccion = c.idColeccion
LEFT JOIN MINERAL m   ON m.idPieza = p.idPieza
LEFT JOIN FOSIL f     ON f.idPieza = p.idPieza
LEFT JOIN GEMA g      ON g.idPieza = p.idPieza
JOIN DETALLE_VENTA dv ON dv.idPieza = p.idPieza
JOIN VENTA v          ON v.idVenta = dv.idVenta
GROUP BY c.idColeccion, c.nombreColeccion, tipoPieza;

-- R3 ¿Existe relación entre el monto de la venta y la evaluación entregada por el cliente?
CREATE OR REPLACE VIEW v_r3_monto_vs_evaluacion AS
SELECT v.idVenta, v.fechaVenta, CONCAT(cl.nombre, ' ', cl.apellido) AS cliente,
       d.piezasVendidas, v.montoTotal, e.cantEvaluaciones, e.promedioEvaluacion
FROM VENTA v
JOIN CLIENTE cl ON cl.idCliente = v.idCliente
JOIN (SELECT idVenta, COUNT(*) AS piezasVendidas FROM DETALLE_VENTA GROUP BY idVenta) d ON d.idVenta = v.idVenta
JOIN (SELECT idVenta, COUNT(*) AS cantEvaluaciones, ROUND(AVG(calificacion), 2) AS promedioEvaluacion
      FROM EVALUACION GROUP BY idVenta) e ON e.idVenta = v.idVenta;

-- R5 ¿Qué colecciones presentan mayor proporción de piezas vendidas respecto del total registrado?
CREATE OR REPLACE VIEW v_r5_proporcion_vendida_coleccion AS
SELECT c.idColeccion, c.nombreColeccion,
       COUNT(DISTINCT p.idPieza)       AS piezasRegistradas,
       COUNT(DISTINCT dv.idPieza)      AS piezasVendidas,
       ROUND(100 * COUNT(DISTINCT dv.idPieza) / NULLIF(COUNT(DISTINCT p.idPieza), 0), 2) AS porcentajeComercializacion
FROM COLECCION c
LEFT JOIN PIEZA p          ON p.idColeccion = c.idColeccion
LEFT JOIN DETALLE_VENTA dv ON dv.idPieza = p.idPieza
GROUP BY c.idColeccion, c.nombreColeccion;

-- R6 ¿Qué piezas generan mayor ingreso acumulado por colección y tipo de pieza?
CREATE OR REPLACE VIEW v_r6_ingreso_pieza_coleccion_tipo AS
SELECT c.nombreColeccion, p.idPieza, p.nombreComercial,
       CASE WHEN m.idPieza IS NOT NULL THEN 'Mineral' WHEN f.idPieza IS NOT NULL THEN 'Fosil'
            WHEN g.idPieza IS NOT NULL THEN 'Gema' ELSE 'Sin clasificar' END AS tipoPieza,
       COUNT(dv.nroCorrelativo) AS vecesVendida,
       SUM(dv.precioVenta)      AS ingresoAcumulado
FROM COLECCION c
JOIN PIEZA p          ON p.idColeccion = c.idColeccion
LEFT JOIN MINERAL m   ON m.idPieza = p.idPieza
LEFT JOIN FOSIL f     ON f.idPieza = p.idPieza
LEFT JOIN GEMA g      ON g.idPieza = p.idPieza
JOIN DETALLE_VENTA dv ON dv.idPieza = p.idPieza
GROUP BY c.nombreColeccion, p.idPieza, p.nombreComercial, tipoPieza;

-- R7 ¿Qué exposiciones concentran mayor diversidad de piezas y cuántas fueron comercializadas posteriormente?
CREATE OR REPLACE VIEW v_r7_exposiciones_diversidad_ventas AS
SELECT e.idExposicion, e.nombre AS exposicion, e.fechaInicio,
       COUNT(DISTINCT pe.idPieza) AS piezasDistintasExhibidas,
       COUNT(DISTINCT CASE WHEN m.idPieza IS NOT NULL THEN 'Mineral' WHEN f.idPieza IS NOT NULL THEN 'Fosil'
                           WHEN g.idPieza IS NOT NULL THEN 'Gema' ELSE 'Sin clasificar' END) AS tiposDistintos,
       COUNT(DISTINCT CASE WHEN v.idVenta IS NOT NULL THEN pe.idPieza END) AS piezasVendidasPosteriormente,
       ROUND(100 * COUNT(DISTINCT CASE WHEN v.idVenta IS NOT NULL THEN pe.idPieza END) / NULLIF(COUNT(DISTINCT pe.idPieza), 0), 2) AS pctVendidas
FROM EXPOSICION e
JOIN PARTICIPACION_EXPOSICION pe ON pe.idExposicion = e.idExposicion
JOIN PIEZA p        ON p.idPieza = pe.idPieza
LEFT JOIN MINERAL m ON m.idPieza = p.idPieza
LEFT JOIN FOSIL f   ON f.idPieza = p.idPieza
LEFT JOIN GEMA g    ON g.idPieza = p.idPieza
LEFT JOIN DETALLE_VENTA dv ON dv.idPieza = p.idPieza
LEFT JOIN VENTA v   ON v.idVenta = dv.idVenta AND v.fechaVenta > COALESCE(e.fechaTermino, e.fechaInicio)
GROUP BY e.idExposicion, e.nombre, e.fechaInicio;

-- R8 ¿Qué clientes presentan mayor cantidad de compras y monto total pagado acumulado?
CREATE OR REPLACE VIEW v_r8_clientes_compras_monto AS
SELECT cl.idCliente, CONCAT(cl.nombre, ' ', cl.apellido) AS cliente, cl.tipoCliente,
       COUNT(DISTINCT v.idVenta) AS cantidadCompras,
       COUNT(dv.nroCorrelativo)  AS piezasCompradas,
       SUM(dv.precioVenta)       AS montoTotalPagado
FROM CLIENTE cl
JOIN VENTA v          ON v.idCliente = cl.idCliente
JOIN DETALLE_VENTA dv ON dv.idVenta = v.idVenta
GROUP BY cl.idCliente, cl.nombre, cl.apellido, cl.tipoCliente
HAVING COUNT(DISTINCT v.idVenta) >= 3 AND SUM(dv.precioVenta) > 0;
