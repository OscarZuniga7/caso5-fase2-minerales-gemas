-- Cuarta pregunta propuesta por equipo (requiere aprobación/justificación del equipo).
-- ¿Cuáles son los clientes que generan mayor monto de ingresos en el período?
-- Una consulta independiente del requisito R8, para uso exclusivo del dashboard.
USE coleccion_db;
SELECT c.idCliente, CONCAT(c.nombre,' ',c.apellido) AS cliente,
       COUNT(DISTINCT v.idVenta) AS compras,
       ROUND(SUM(d.precioVenta),2) AS montoPagado
FROM CLIENTE c
JOIN VENTA v ON v.idCliente=c.idCliente
JOIN DETALLE_VENTA d ON d.idVenta=v.idVenta
WHERE v.fechaVenta BETWEEN '2023-01-01' AND '2026-12-31'
GROUP BY c.idCliente,c.nombre,c.apellido
ORDER BY montoPagado DESC LIMIT 10;
-- Decisión de negocio: identificar segmentos de clientes para fidelización.
