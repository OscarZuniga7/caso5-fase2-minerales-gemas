# Arquitectura didáctica del Caso 5

## Tres componentes que no hay que confundir

**MySQL Workbench 8.0.47** es el **cliente de administración** en Windows. No almacena los datos de la aplicación: se conecta a MySQL 8.4.

**MySQL 8.4** se ejecuta en el contenedor `db` de Docker Compose, en GitHub Codespaces. Sus tablas y objetos existen en `coleccion_db`; sus datos persisten en el volumen `mysql_data`.

**Streamlit** es la aplicación Python del contenedor `web`. Usa SQLAlchemy + PyMySQL para conectarse con MySQL, de manera interna, por `db:3306`. Desde un navegador se ve la app en el puerto 8501.

```text
PC Windows                                       GitHub Codespaces (cada estudiante)
MySQL Workbench -- gh CLI túnel TCP 3307 -> 3306 -- [docker] MySQL 8.4 (db)
                                                      ^
                                                      | SQLAlchemy/PyMySQL
                                                      v
                                                  [docker] Streamlit (web:8501)
                                                               ^
                                                               | HTTPS / navegador
                                                               v
                                                       Usuario final del PMV
```

Un repositorio **público no da permiso para entrar al Codespace personal de otra persona**. Las estudiantes pueden crear dos Codespaces, cada una con su propia copia de la BD, y colaborar en un único repositorio Git. Para una única BD compartida hace falta un host/control de acceso adicionales; no publicar MySQL en Internet.

## SQL académico y aplicación

* R1, R4, R9, R10, R11 y R12 son procedimientos almacenados.
* R2, R3, R5, R6, R7 y R8 son vistas.
* Todos se prueban con **MySQL Workbench** y se capturan para el informe.
* El enunciado oficial, sección 9, establece que estos doce objetos **no se integran en el PMV**.
* El PMV implementa: registro de ventas en transacción, CRUD de COLECCION y PIEZA, acceso por roles, cuatro gráficos/consultas de negocio.

## Flujos

**Registrar venta:** seleccionar cliente + gestor + piezas; confirmar -> validar claves y valores -> `INSERT VENTA` + `INSERT DETALLE_VENTA` en `engine().begin()` -> `COMMIT` o `ROLLBACK`.

**CRUD:** se permiten creación, consulta, modificación y desactivación lógica (`activo=0`); ello preserva FKs históricas.

**Acceso:** `CUENTA_USUARIO` + `ASIGNADO` + `PERMISO_ROL`; contraseñas PBKDF2 individuales en BD, generadas desde variables privadas. Se provisionan las cuentas de demo `admin`, `gestor` y `catalogador`.

**Dashboard:** P1 suma ventas por colección; P2 distribución por tipo; P3 dispersión de montos y evaluación; P4 top diez clientes por ingresos. P4 es una propuesta del ejemplo, pendiente de justificación personal del equipo.

## Límite del modelo fuente

En los datos originales se registran ventas repetidas de una misma PIEZA. Conservar esa decisión favorece la coherencia con las cifras del SQL recibido, pero no representa necesariamente la venta de ejemplares únicos. El equipo debe **justificar esta regla** o ajustar modelo/poblamiento para reflejar reventas o inventario de ejemplares. No se ha impuesto silenciosamente una prohibición no declarada en el modelo.
