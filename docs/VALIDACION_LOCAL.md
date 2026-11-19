# Registro de validación local (sin contenedores)

Fuente de conteos: análisis del SQL entregado por Diana y Valentina (script integral original).

| Tabla | Filas de origen |
|---|---:|
| COLECCION | 16 |
| PIEZA | 120 |
| EXPOSICION | 28 |
| PARTICIPACION_EXPOSICION | 344 |
| CLIENTE | 220 |
| PERSONAL | 50 |
| VENTA | 350 |
| DETALLE_VENTA | 992 |
| EVALUACION | 228 |
| CUENTA_USUARIO | 50 |
| ROL | 3 |

Controles hechos sobre el texto SQL:

- **350/350** montos de venta coinciden con la suma de sus detalles, con tolerancia de 0,01.
- Todas las referencias foráneas presentes en los INSERT revisados apuntan a identificadores presentes en las tablas de referencia.
- **0** piezas aparecen simultáneamente en dos o tres tablas de subtipos dentro de los INSERT de origen.
- **115** piezas distintas aparecen en DETALLE_VENTA de las **120** piezas registradas (el conjunto de origen permite reventas).
- Los 12 objetos R1–R12 están definidos en los SQL originales, y el modelo contiene 19 tablas.

Estos controles NO equivalen a ejecución SQL real: no se pudo iniciar Docker/MySQL 8.4 dentro del entorno de generación. Se debe completar la prueba de despliegue, login, CRUD, ventas, dashboard, 6 SELECT y 6 CALL en Codespaces + Workbench.

Consulta recomendada: `sql/05_pruebas.sql`. Autodiagnóstico de la app: `docker compose exec web python scripts/verificar_conexion.py`.
