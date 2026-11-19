"""Configura tres cuentas del conjunto sintético con contraseñas privadas en variables de entorno."""
import os, sys
sys.path.insert(0,os.path.dirname(os.path.dirname(__file__)))
from sqlalchemy import text
from src.auth import hash_password
from src.db import engine

cuentas=[('admin','DEMO_ADMIN_PASSWORD'),('gestor','DEMO_GESTOR_PASSWORD'),('catalogador','DEMO_CATALOGO_PASSWORD')]
for nombre,var in cuentas:
    if len(os.getenv(var,''))<12:
        raise RuntimeError(f'{var} debe estar definida con al menos 12 caracteres en .env')
with engine().begin() as con:
    for nombre,var in cuentas:
        # Es un entorno de DEMO; se actualizan las claves en cada arranque para reproducibilidad.
        result=con.execute(text("UPDATE CUENTA_USUARIO SET contrasena=:hash,estado='ACTIVA' WHERE nombreUsuario=:nombre"),
                           {'hash':hash_password(os.environ[var]),'nombre':nombre})
        if result.rowcount!=1:
            raise RuntimeError(f'Cuenta semilla inexistente: {nombre}')
print('Cuentas de demostracion preparadas: admin, gestor, catalogador (sin exponer claves).')
