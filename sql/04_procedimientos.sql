-- 04_procedimientos.sql : 6 procedimientos almacenados (R1, R4, R9, R10, R11, R12)
SET NAMES utf8mb4;
USE coleccion_db;
-- R1 Colecciones con mayor monto de ventas en un período
DROP PROCEDURE IF EXISTS sp_r1_colecciones_mayor_monto;
CREATE PROCEDURE sp_r1_colecciones_mayor_monto(IN p_inicio DATE, IN p_fin DATE)
  SELECT c.idColeccion, c.nombreColeccion,
         COUNT(DISTINCT v.idVenta) AS ventas,
         COUNT(dv.nroCorrelativo)  AS piezasVendidas,
         SUM(dv.precioVenta)       AS montoVendido
  FROM COLECCION c
  JOIN PIEZA p          ON p.idColeccion = c.idColeccion
  JOIN DETALLE_VENTA dv ON dv.idPieza = p.idPieza
  JOIN VENTA v          ON v.idVenta = dv.idVenta
  WHERE v.fechaVenta BETWEEN p_inicio AND p_fin
  GROUP BY c.idColeccion, c.nombreColeccion
  ORDER BY montoVendido DESC;

-- R4 Colecciones con más piezas vendidas y clientes distintos en un período
DROP PROCEDURE IF EXISTS sp_r4_colecciones_piezas_clientes;
CREATE PROCEDURE sp_r4_colecciones_piezas_clientes(IN p_inicio DATE, IN p_fin DATE)
  SELECT c.idColeccion, c.nombreColeccion,
         COUNT(dv.nroCorrelativo)    AS piezasVendidas,
         COUNT(DISTINCT cl.idCliente) AS clientesDistintos
  FROM COLECCION c
  JOIN PIEZA p          ON p.idColeccion = c.idColeccion
  JOIN DETALLE_VENTA dv ON dv.idPieza = p.idPieza
  JOIN VENTA v          ON v.idVenta = dv.idVenta
  JOIN CLIENTE cl       ON cl.idCliente = v.idCliente
  WHERE v.fechaVenta BETWEEN p_inicio AND p_fin
  GROUP BY c.idColeccion, c.nombreColeccion
  ORDER BY piezasVendidas DESC, clientesDistintos DESC;

-- R9 Ventas que superan el monto promedio de las ventas con piezas de una colección (subconsulta correlacionada)
DROP PROCEDURE IF EXISTS sp_r9_ventas_sobre_promedio_coleccion;
CREATE PROCEDURE sp_r9_ventas_sobre_promedio_coleccion(IN p_idColeccion VARCHAR(10), IN p_inicio DATE, IN p_fin DATE)
  SELECT DISTINCT v.idVenta, v.fechaVenta, v.montoTotal, c.nombreColeccion,
         (SELECT ROUND(AVG(v2.montoTotal), 2)
            FROM VENTA v2
           WHERE v2.fechaVenta BETWEEN p_inicio AND p_fin
             AND EXISTS (SELECT 1 FROM DETALLE_VENTA d2 JOIN PIEZA p2 ON p2.idPieza = d2.idPieza
                          WHERE d2.idVenta = v2.idVenta AND p2.idColeccion = p.idColeccion)) AS promedioVentasColeccion
  FROM VENTA v
  JOIN DETALLE_VENTA dv ON dv.idVenta = v.idVenta
  JOIN PIEZA p          ON p.idPieza = dv.idPieza
  JOIN COLECCION c      ON c.idColeccion = p.idColeccion
  WHERE p.idColeccion = p_idColeccion
    AND v.fechaVenta BETWEEN p_inicio AND p_fin
    AND v.montoTotal > (SELECT AVG(v2.montoTotal)
                          FROM VENTA v2
                         WHERE v2.fechaVenta BETWEEN p_inicio AND p_fin
                           AND EXISTS (SELECT 1 FROM DETALLE_VENTA d2 JOIN PIEZA p2 ON p2.idPieza = d2.idPieza
                                        WHERE d2.idVenta = v2.idVenta AND p2.idColeccion = p.idColeccion))
  ORDER BY v.montoTotal DESC;

-- R10 Piezas con precio de venta promedio superior al promedio de su mismo tipo (subconsulta correlacionada)
-- p_tipo: 'Mineral' | 'Fosil' | 'Gema' | 'Sin clasificar'
DROP PROCEDURE IF EXISTS sp_r10_piezas_sobre_promedio_tipo;
CREATE PROCEDURE sp_r10_piezas_sobre_promedio_tipo(IN p_tipo VARCHAR(20))
  SELECT t.idPieza, t.nombreComercial, t.tipoPieza, t.ventas, t.precioPromedio,
         (SELECT ROUND(AVG(d2.precioVenta), 2)
            FROM DETALLE_VENTA d2
            JOIN PIEZA p2 ON p2.idPieza = d2.idPieza
            LEFT JOIN MINERAL m2 ON m2.idPieza = p2.idPieza
            LEFT JOIN FOSIL f2   ON f2.idPieza = p2.idPieza
            LEFT JOIN GEMA g2    ON g2.idPieza = p2.idPieza
           WHERE CASE WHEN m2.idPieza IS NOT NULL THEN 'Mineral' WHEN f2.idPieza IS NOT NULL THEN 'Fosil'
                      WHEN g2.idPieza IS NOT NULL THEN 'Gema' ELSE 'Sin clasificar' END = t.tipoPieza) AS promedioDelTipo
  FROM (SELECT p.idPieza, p.nombreComercial,
               CASE WHEN m.idPieza IS NOT NULL THEN 'Mineral' WHEN f.idPieza IS NOT NULL THEN 'Fosil'
                    WHEN g.idPieza IS NOT NULL THEN 'Gema' ELSE 'Sin clasificar' END AS tipoPieza,
               COUNT(DISTINCT v.idVenta) AS ventas,
               ROUND(AVG(dv.precioVenta), 2) AS precioPromedio
          FROM PIEZA p
          LEFT JOIN MINERAL m ON m.idPieza = p.idPieza
          LEFT JOIN FOSIL f   ON f.idPieza = p.idPieza
          LEFT JOIN GEMA g    ON g.idPieza = p.idPieza
          JOIN DETALLE_VENTA dv ON dv.idPieza = p.idPieza
          JOIN VENTA v          ON v.idVenta = dv.idVenta
         GROUP BY p.idPieza, p.nombreComercial, m.idPieza, f.idPieza, g.idPieza) t
  WHERE t.tipoPieza = p_tipo
    AND t.precioPromedio > (SELECT AVG(d2.precioVenta)
            FROM DETALLE_VENTA d2
            JOIN PIEZA p2 ON p2.idPieza = d2.idPieza
            LEFT JOIN MINERAL m2 ON m2.idPieza = p2.idPieza
            LEFT JOIN FOSIL f2   ON f2.idPieza = p2.idPieza
            LEFT JOIN GEMA g2    ON g2.idPieza = p2.idPieza
           WHERE CASE WHEN m2.idPieza IS NOT NULL THEN 'Mineral' WHEN f2.idPieza IS NOT NULL THEN 'Fosil'
                      WHEN g2.idPieza IS NOT NULL THEN 'Gema' ELSE 'Sin clasificar' END = t.tipoPieza)
  ORDER BY t.precioPromedio DESC;

-- R11 Clientes con más compras que el promedio y evaluación promedio superior al promedio general
DROP PROCEDURE IF EXISTS sp_r11_clientes_sobre_promedio;
CREATE PROCEDURE sp_r11_clientes_sobre_promedio(IN p_inicio DATE, IN p_fin DATE)
  SELECT cl.idCliente, CONCAT(cl.nombre, ' ', cl.apellido) AS cliente, cl.tipoCliente,
         COUNT(DISTINCT vm.idVenta)      AS compras,
         ROUND(AVG(e.calificacion), 2)   AS evaluacionPromedio
  FROM CLIENTE cl
  JOIN (SELECT v.idVenta, v.idCliente, SUM(dv.precioVenta) AS montoDetalle
          FROM VENTA v JOIN DETALLE_VENTA dv ON dv.idVenta = v.idVenta
         WHERE v.fechaVenta BETWEEN p_inicio AND p_fin
         GROUP BY v.idVenta, v.idCliente) vm ON vm.idCliente = cl.idCliente
  JOIN EVALUACION e ON e.idVenta = vm.idVenta
  GROUP BY cl.idCliente, cl.nombre, cl.apellido, cl.tipoCliente
  HAVING COUNT(DISTINCT vm.idVenta) > (SELECT AVG(x.n) FROM (SELECT COUNT(*) AS n FROM VENTA
                                                              WHERE fechaVenta BETWEEN p_inicio AND p_fin
                                                              GROUP BY idCliente) x)
     AND AVG(e.calificacion) > (SELECT AVG(ev.calificacion) FROM EVALUACION ev
                                 JOIN VENTA v3 ON v3.idVenta = ev.idVenta
                                WHERE v3.fechaVenta BETWEEN p_inicio AND p_fin)
  ORDER BY compras DESC, evaluacionPromedio DESC;

-- R12 Colecciones con monto promedio de venta por pieza superior al promedio general de las colecciones
DROP PROCEDURE IF EXISTS sp_r12_colecciones_sobre_promedio_general;
CREATE PROCEDURE sp_r12_colecciones_sobre_promedio_general(IN p_inicio DATE, IN p_fin DATE)
  SELECT c.idColeccion, c.nombreColeccion,
         COUNT(dv.nroCorrelativo)       AS piezasVendidas,
         ROUND(AVG(dv.precioVenta), 2)  AS montoPromedioPorPieza
  FROM COLECCION c
  JOIN PIEZA p          ON p.idColeccion = c.idColeccion
  JOIN DETALLE_VENTA dv ON dv.idPieza = p.idPieza
  JOIN VENTA v          ON v.idVenta = dv.idVenta
  WHERE v.fechaVenta BETWEEN p_inicio AND p_fin
  GROUP BY c.idColeccion, c.nombreColeccion
  HAVING AVG(dv.precioVenta) > (SELECT AVG(y.prom)
                                  FROM (SELECT AVG(d2.precioVenta) AS prom
                                          FROM COLECCION c2
                                          JOIN PIEZA p2          ON p2.idColeccion = c2.idColeccion
                                          JOIN DETALLE_VENTA d2  ON d2.idPieza = p2.idPieza
                                          JOIN VENTA v2          ON v2.idVenta = d2.idVenta
                                         WHERE v2.fechaVenta BETWEEN p_inicio AND p_fin
                                         GROUP BY c2.idColeccion) y)
  ORDER BY montoPromedioPorPieza DESC;

