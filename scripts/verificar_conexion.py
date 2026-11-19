"""Autoprueba real de MySQL desde el contenedor web.
Uso: docker compose exec web python scripts/verificar_conexion.py
"""
from sqlalchemy import text
from src.db import engine
with engine().connect() as c:
    print('Servidor:', c.execute(text('SELECT VERSION()')).scalar())
    print('BD:', c.execute(text('SELECT DATABASE()')).scalar())
    for t in ['COLECCION','PIEZA','CLIENTE','VENTA','DETALLE_VENTA','EVALUACION']:
        print(t, c.execute(text(f'SELECT COUNT(*) FROM {t}')).scalar())
    vistas=c.execute(text("SELECT COUNT(*) FROM information_schema.VIEWS WHERE TABLE_SCHEMA=DATABASE()" )).scalar()
    procs=c.execute(text("SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_TYPE='PROCEDURE'" )).scalar()
    print('Vistas:',vistas,'Procedimientos:',procs)
    if vistas!=6 or procs!=6: raise SystemExit('ERROR: faltan objetos SQL')
print('OK conexión, tablas y objetos; falta probar PMV y Workbench de forma interactiva.')
