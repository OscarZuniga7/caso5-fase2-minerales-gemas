# Fase 2 — Caso 5: Sistema de Venta de Minerales y Gemas de Colección

**UNAB · TDFI103 · Proyecto Semestral 2026 · Base de datos: `coleccion_db`**

Proyecto de referencia desarrollado a partir de los scripts entregados por Diana y Valentina. Contiene: MySQL 8.4, SQL de creación y datos, seis vistas y seis procedimientos, PMV integrado Python/Streamlit, SQLAlchemy + PyMySQL, Pandas + Plotly, control de accesos y Docker Compose. **Código entregado no equivale a una demostración real**: hay que ejecutar las pruebas y documentar las capturas antes de la entrega.

## 1. La arquitectura en una frase

Workbench instalado en Windows **es un cliente**. MySQL 8.4 vive en el contenedor `db` de Codespaces. Streamlit vive en `web`, se conecta internamente a `db:3306` y se abre desde navegador en el puerto 8501. Workbench accede a `db` por un **túnel TCP privado**, no por una URL HTTP. Véase `docs/ARQUITECTURA.md`.

## 2. Inicio rápido desde GitHub Codespaces (recomendado)

### A. Crear un repositorio público con el ZIP

1. Descomprimir el ZIP y entrar a la carpeta `caso5_fase2_codespaces`.
2. Crear en GitHub un repositorio público vacío (por ejemplo `proyecto-fase2-caso5`).
3. Subir **el contenido completo** de la carpeta mediante GitHub Desktop o Git, incluidos `.devcontainer/`, `.gitignore`, `sql/` y `src/`. NO subir archivos `.env`.
4. Con Git instalado y GitHub CLI autenticado, una forma reproducible desde esa carpeta es:

```bash
git init
git add .
git commit -m "Proyecto Fase 2 Caso 5"
gh auth login
gh repo create proyecto-fase2-caso5 --public --source=. --remote=origin --push
```

Si el repositorio ya existe, configurar el remoto apropiado y hacer `git push` normalmente; no intentar crear uno duplicado. Revisar la cuenta/organización antes de publicar. **Nunca publicar las claves** de `.env` ni datos reales de personas. Antes de publicar, verificar que los teléfonos y correos del SQL semilla sean efectivamente ficticios y no correspondan a terceros reales.

### B. Iniciar Codespaces

1. Abrir el repositorio público en GitHub.
2. Seleccionar **Code → Codespaces → Create codespace on main**.
3. Esperar que se abra VS Code web y entrar a **Terminal → New Terminal**.
4. En la raíz del proyecto ejecutar:

```bash
python scripts/configurar_env.py
docker compose up -d --build
```

`configurar_env.py` crea `.env` con claves aleatorias. El archivo queda **privado** gracias a `.gitignore`. Se usa también para las tres contraseñas demo. Para verlas, desde el mismo Codespace autorizado: `cat .env` (nunca copiar ni publicar su contenido). El contenedor `web` actualiza de forma idempotente los tres usuarios de demostración.

5. Revisar el estado:

```bash
docker compose ps
docker compose logs --tail=50 db
docker compose logs --tail=50 web
docker compose exec web python scripts/verificar_conexion.py
```

6. Abrir **Ports**, buscar el puerto **8501**, abrir la URL de Streamlit. Mantener la visibilidad **Private**.
7. Ingresar con `admin`, `gestor` o `catalogador`, utilizando la contraseña correspondiente en `.env` (no son iguales).

**Importante:** la inicialización `sql/00_integral.sql` se ejecuta automáticamente SOLO cuando el volumen de datos `mysql_data` es nuevo. Detener o reiniciar contenedores conserva la BD; modificar el SQL después de iniciar no lo vuelve a importar automáticamente. Para cambios, ejecutar scripts puntuales en Workbench. `docker compose down -v` **borra permanentemente el volumen con toda la BD**: usar solo para reconstruir una copia de prueba y previo respaldo.

## 3. Conectar tu MySQL Workbench 8.0.47 de Windows a ese Codespace

Requisito: tener instalado **GitHub CLI** en el computador Windows y acceso autenticado al **Codespace propio**. No es necesario MySQL Server local, y no se debe arrancar `MySQL97`.

En **PowerShell de Windows** (NO en la terminal de Codespaces):

```powershell
gh auth login
gh codespace list
gh codespace ports forward 3306:3307 -c NOMBRE_DEL_CODESPACE
```

Sustituir `NOMBRE_DEL_CODESPACE` por el nombre exacto listado. Dejar esa consola abierta: es el túnel privado. El puerto 3307 evita conflictos con servicios MySQL locales.

Luego, en Workbench seleccionar **MySQL Connections → +**:

| Campo | Valor |
|---|---|
| Connection Name | Caso5_Codespaces |
| Connection Method | Standard (TCP/IP) |
| Hostname | 127.0.0.1 |
| Port | 3307 |
| Username | caso5_app |
| Password | `MYSQL_APP_PASSWORD` de `.env` de ESE Codespace |
| Default Schema | coleccion_db |

Presionar **Test Connection** y luego conectar. Ejecutar:

```sql
SELECT VERSION();
USE coleccion_db;
SHOW TABLES;
SELECT COUNT(*) FROM VENTA;
SELECT * FROM v_r5_proporcion_vendida_coleccion LIMIT 5;
```

La conexión no puede garantizarse desde un ZIP; cuando esos resultados aparezcan en Workbench habrá **evidencia de conexión real**. Para probar todos los doce objetos, abrir `sql/05_pruebas.sql` y ejecutar cada consulta o `CALL`; guardar capturas reales.

**Problemas típicos:** `Can't connect` → túnel cerrado, Codespace detenido o puerto ocupado; `Access denied` → contraseña de `.env` incorrecta; BD vacía → volumen anterior no se inicializó o se usó otro Codespace; 8501 no abre → revisar `docker compose logs web`.

## 4. ¿Cómo colaboran Diana y Valentina?

El repositorio público **comparte los archivos**, no la base de datos viva de una estudiante. Recomendación rápida: **cada una crea su propio Codespace** desde el mismo repo, ejecuta Compose y conecta su Workbench local a SU Codespace mediante `gh codespace ports forward`.

Las mejoras se comparten haciendo commits y pull requests; para trabajar en la misma BD en tiempo real se requeriría un servidor común con control de acceso, distinto de lo que automáticamente ofrece un repositorio público. El profesor puede ejecutar una tercera copia en su propio Codespace. Un túnel privado de una cuenta GitHub no se comparte automáticamente con otra.

## 5. Entregables y estructura del proyecto

```text
.
├─ sql/
│  ├─ 00_integral.sql           esquema + datos + 6 vistas + 6 procedimientos
│  ├─ 01_schema.sql             19 tablas, restricciones y relaciones
│  ├─ 02_datos.sql              poblamiento original de las estudiantes
│  ├─ 03_vistas.sql             R2 R3 R5 R6 R7 R8
│  ├─ 04_procedimientos.sql     R1 R4 R9 R10 R11 R12
│  ├─ 05_pruebas.sql            SELECT/CALL y conteos para Workbench
│  └─ 06_dashboard_p4.sql       cuarta pregunta propuesta
├─ app.py                       aplicación Streamlit integrada
├─ src/db.py                    conexión y transacciones SQLAlchemy
├─ src/auth.py                  autenticación y permisos en MySQL
├─ scripts/configurar_env.py    genera claves privadas
├─ scripts/provisionar_usuarios.py
├─ scripts/generar_datos.py     Faker adicional reproducible
├─ scripts/verificar_conexion.py
├─ Dockerfile
├─ docker-compose.yml
├─ requirements.txt
├─ .devcontainer/devcontainer.json
├─ .env.example                 nombres de claves, sin valores secretos
├─ docs/ARQUITECTURA.md
├─ docs/CAMBIOS_Y_PENDIENTES.md
├─ docs/GUIA_DEFENSA.md
└─ fuentes/                      SQL originales sin alterar
```

**Importante:** `sql/00_integral.sql` ejecuta un `DROP DATABASE` al iniciar una base de pruebas. **No ejecutar el integral en una instancia con trabajo que se quiera conservar.** Para reconstruir desde cero, usar un Codespace/volumen nuevo.

## 6. SQL académico: exactamente doce requerimientos

Seis vistas: **R2**, **R3**, **R5**, **R6**, **R7**, **R8**. Seis procedimientos: **R1**, **R4**, **R9**, **R10**, **R11**, **R12**. Conservar en el informe enunciado, código, ejecución, salida capturada e interpretación (2–4 líneas) para cada uno. **No integrar estos doce objetos al PMV**, de acuerdo con la sección 9 del PDF oficial. El PMV hace sus propias consultas de negocio.

## 7. PMV: cuatro módulos integrados

| Módulo | Se prueba con | Comportamiento |
|---|---|---|
| Formulario transaccional | `gestor` / `admin` | Cliente, gestor, varias piezas; guarda VENTA + DETALLE_VENTA en una transacción |
| CRUD tablas maestras | `catalogador` / `admin` | Crear, listar, modificar y desactivar COLECCION y PIEZA |
| Usuarios y roles | Tres cuentas | Roles reales de tablas ASIGNADO y PERMISO_ROL; limita navegación y entrada a cada módulo |
| Dashboard | Todos los tres | P1 montos colección, P2 tipos, P3 ventas-evaluaciones, P4 mayores clientes por ingresos |

**Prueba de permisos:** `gestor` no debe ver CRUD; `catalogador` no debe ver Registro de ventas; `admin` dispone de todas las funciones. Usuarios inactivos no ingresan. Hash PBKDF2 salado; el login no admite SHA-256 antiguo.

**Reglas del modelo:** el original permite una misma pieza en ventas diferentes. El formulario evita repetirla dos veces en **una misma venta**, pero no prohíbe reventas existentes en los datos. El equipo debe justificar esta decisión en el modelo de negocio.

## 8. Replicar datos de prueba con Faker (opcional)

El archivo fuente incluye datos sintéticos suficientes para arrancar. El generador original no fue adjuntado, por lo que se entrega un generador **adicional** reproducible, NO una reconstrucción exacta del original:

```bash
docker compose exec web python scripts/generar_datos.py --cantidad 10
```

El resultado `sql/02_datos_adicionales.sql` se genera dentro del contenedor, no en el repositorio del Codespace (por el COPY del Dockerfile). Si desean llevarlo al repositorio, ejecutar `python scripts/generar_datos.py --cantidad 10` desde el **terminal del Codespace** con Faker instalado (`pip install Faker`). La carga adicional es voluntaria; no reemplaza `02_datos.sql`.

## 9. Informe, MERE y defensa: pendientes humanos obligatorios

El **código** está preparado, pero no se pueden inventar: las imágenes reales del MERE y modelo Workbench, la ejecución efectiva de doce consultas, pantallas del PMV, pruebas de Docker, responsabilidades, bitácoras y conclusiones individuales. Para ello usar `docs/GUIA_DEFENSA.md`. Además, la revisión de Fase 1 exige adjuntar MERE original y observaciones; esos archivos no se recibieron.

### Registro transparente de validación

Se comprobó de manera local la sintaxis de Python mediante `py_compile` y la presencia de las 19 tablas, 6 vistas y 6 procedimientos en los archivos. **No se ejecutó Docker/MySQL 8.4 ni se estableció una conexión a Codespaces desde este entorno.** Por tanto, el funcionamiento extremo a extremo deberá verificarse siguiendo los comandos anteriores antes de afirmar que el proyecto funciona.

## Documentación oficial

- [GitHub Codespaces: reenvío de puertos](https://docs.github.com/es/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace)
- [GitHub CLI con Codespaces](https://docs.github.com/es/codespaces/developing-in-a-codespace/using-github-codespaces-with-github-cli)
- [Dev container Python en Codespaces](https://docs.github.com/es/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/setting-up-your-python-project-for-codespaces)
