# Inicio rápido — 10 pasos para profesor, Diana y Valentina

**El objetivo inmediato es probar una conexión real.** El paquete fue generado y comprobado estáticamente, pero todavía no se ha ejecutado desde un Codespace real.

1. Descomprimir el ZIP, entrar a `caso5_fase2_codespaces`.
2. Crear en GitHub un repositorio vacío, público, y subir **todo el contenido** de la carpeta. El `README.md` explica GitHub Desktop/Git.
3. En el repositorio: **Code → Codespaces → Create codespace on main**.
4. En terminal Codespaces ejecutar: `python scripts/configurar_env.py`.
5. Ejecutar: `docker compose up -d --build`.
6. Ejecutar: `docker compose ps` y `docker compose exec web python scripts/verificar_conexion.py`.
7. Abrir el puerto 8501 desde la pestaña **Ports**, y probar usuarios `admin`, `gestor`, `catalogador` usando las contraseñas de `.env` privado.
8. En Windows con GitHub CLI, abrir **PowerShell** y ejecutar: `gh auth login`; `gh codespace list`.
9. En esa misma PowerShell ejecutar `gh codespace ports forward 3306:3307 -c NOMBRE_DEL_CODESPACE` y **dejar abierta la ventana**.
10. Workbench 8.0.47 → nueva conexión TCP/IP: `127.0.0.1`, puerto `3307`, usuario `caso5_app`, clave `MYSQL_APP_PASSWORD` de `.env`; **Test Connection**. Después abrir `sql/05_pruebas.sql` y realizar las 6 consultas SELECT y 6 CALL.

**Precauciones:** No subir `.env`; no compartir el túnel ni abrir públicamente 3306; no ejecutar `docker compose down -v` sin respaldo; no importar `sql/00_integral.sql` a una base con datos que desee conservar (incluye `DROP DATABASE`). Los datos fuente se recibieron como sintéticos; verificar antes de publicar que no contengan datos personales auténticos.

**Trabajo colaborativo:** Las estudiantes comparten el repositorio, no automáticamente la misma base viva. Cada una puede tener su propio Codespace y reproducir la misma base mediante Docker. Para una BD realmente única y compartida se requiere otro diseño de acceso seguro.

**Pendiente académico:** imágenes MERE/Workbench, capturas de SQL, ejecución del PMV y Docker, bitácoras y participación real. Consultar `docs/GUIA_DEFENSA.md`.
