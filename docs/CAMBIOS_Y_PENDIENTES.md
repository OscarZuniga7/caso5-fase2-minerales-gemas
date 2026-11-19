# Revisión de fuentes originales y pendientes reales

Fuente: `fuentes/script_integral_original.sql` (enviado por las estudiantes) y `fuentes/04_procedimientos_original.sql`.

## Preservación

Se conservan, sin sustituir su modelo por uno inventado, las 19 tablas, PK/FK, restricciones, nombres de columnas y los datos sintéticos del SQL original. Los identificadores de los doce requerimientos oficiales están respetados:

| Vista | ID | Procedimiento | ID |
| --- | --- | --- | --- |
| v_r2_distribucion_tipo_coleccion | R2 | sp_r1_colecciones_mayor_monto | R1 |
| v_r3_monto_vs_evaluacion | R3 | sp_r4_colecciones_piezas_clientes | R4 |
| v_r5_proporcion_vendida_coleccion | R5 | sp_r9_ventas_sobre_promedio_coleccion | R9 |
| v_r6_ingreso_pieza_coleccion_tipo | R6 | sp_r10_piezas_sobre_promedio_tipo | R10 |
| v_r7_exposiciones_diversidad_ventas | R7 | sp_r11_clientes_sobre_promedio | R11 |
| v_r8_clientes_compras_monto | R8 | sp_r12_colecciones_sobre_promedio_general | R12 |

## Ajustes puntuales

1. `sql/01_schema.sql`: aviso explícito de que el script **destruye y reconstruye** `coleccion_db`. Conserva `DROP DATABASE` original para reconstrucción de la BD de demostración.
2. `sql/03_vistas.sql`: R5 y R7 usan `NULLIF(...,0)` en denominadores para prevenir división por cero.
3. `sql/03_vistas.sql`: R7 entiende *posteriormente* como venta después de la fecha de término de exposición, o fecha de inicio si no existe término; en el original se comparaba con fecha de incorporación. El equipo debe justificar esta interpretación.
4. `sql/04_procedimientos.sql`: sentencias SQL conservadas de las estudiantes (cada `CREATE PROCEDURE` consta de una sola sentencia `SELECT`, sintaxis válida MySQL sin `BEGIN/END`).
5. Se separaron esquema, datos, vistas y procedimientos, y se recompuso un `sql/00_integral.sql` para despliegue automático inicial; se añadieron las pruebas `05_pruebas.sql`.
6. Se agregó el PMV completo (cuatro módulos) con contraseñas PBKDF2 y configuración privada; la fuente original usaba hashes SHA-256 simples para sus cuentas semilla. Solo las tres cuentas de demostración reaprovisionadas permiten ingresar al PMV; el resto se conserva como datos históricos y no se aceptan claves SHA-256 antiguas.

## Brechas que el código no puede fabricar honestamente

* Los archivos de Fase 1 (MERE original, observaciones/correcciones) **no fueron adjuntados**. Por tanto no se puede afirmar haber validado el MERE contra Fase 1 ni haber creado capturas genuinas de Workbench.
* Deben agregar una imagen real del MERE corregido y del modelo relacional de Workbench.
* Cada integrante debe registrar **sus** responsabilidades, bitácora, aporte y conclusión, con evidencia real. La sección 14 pide un responsable distinto para cada módulo PMV; esto requiere criterio/coordinación si fueran solo dos integrantes.
* Evidencias de ejecución en MySQL Workbench, Streamlit y Docker Compose deben capturarse tras una ejecución real. No se han inventado capturas ni resultados de consultas.
* El generador original de Faker asociado al SQL de las estudiantes **no fue proporcionado**. Se incluye un nuevo generador adicional y reproducible, pero no se atribuye falsamente la capacidad de regenerar exactamente los registros recibidos.
* Los datos originales simulan múltiples ventas del mismo idPieza. La validez de esa regla respecto del caso comercial debe explicarse en el informe o corregirse después de validar el modelo de Fase 1.
* La especialización disyunta `PIEZA→MINERAL/FOSIL/GEMA` no está garantizada solo con las tres FK del original para escritores SQL arbitrarios. El PMV registra cada pieza nueva en un solo subtipo; deben documentar este límite del modelo.

## Validación

Las comprobaciones locales incluyeron compilación de Python y análisis estático de archivos (no ejecución real de MySQL 8.4). Ejecute `sql/05_pruebas.sql` en Workbench y `docker compose exec web python scripts/verificar_conexion.py` en Codespaces. No es correcto calificar el sistema como desplegado o la conexión externa como probada sin esas verificaciones.
