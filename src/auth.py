"""Hash PBKDF2 con sal aleatoria. Contraseñas no se escriben en el repositorio."""
import hashlib, hmac, os, secrets
from sqlalchemy import text
from src.db import engine

ITERATIONS=240_000

def hash_password(password):
    salt=secrets.token_hex(16)
    digest=hashlib.pbkdf2_hmac('sha256',password.encode(),bytes.fromhex(salt),ITERATIONS).hex()
    return f'pbkdf2_sha256${ITERATIONS}${salt}${digest}'

def check_password(password, stored):
    try:
        alg,its,salt,digest=stored.split('$')
        if alg!='pbkdf2_sha256': return False  # legacy SHA-256 desactivado
        calc=hashlib.pbkdf2_hmac('sha256',password.encode(),bytes.fromhex(salt),int(its)).hex()
        return hmac.compare_digest(calc,digest)
    except (ValueError,AttributeError,TypeError):
        return False

def login(nombre, password):
    with engine().connect() as c:
        user=c.execute(text('''SELECT idCuenta,nombreUsuario,contrasena FROM CUENTA_USUARIO
          WHERE nombreUsuario=:nombre AND estado='ACTIVA' '''),{'nombre':nombre}).mappings().first()
        if not user or not check_password(password,user['contrasena']): return None
        permisos=c.execute(text('''SELECT DISTINCT pr.permiso FROM PERMISO_ROL pr
              JOIN ASIGNADO a ON a.idRol=pr.idRol WHERE a.idCuenta=:cuenta'''),{'cuenta':user['idCuenta']}).scalars().all()
        return {'idCuenta':user['idCuenta'],'nombre':user['nombreUsuario'],'permisos':list(permisos)}

def permisos_actuales(id_cuenta):
    with engine().connect() as c:
        estado=c.execute(text("SELECT estado FROM CUENTA_USUARIO WHERE idCuenta=:id"),{'id':id_cuenta}).scalar()
        if estado!='ACTIVA': return set()
        return set(c.execute(text('''SELECT DISTINCT pr.permiso FROM PERMISO_ROL pr
              JOIN ASIGNADO a ON a.idRol=pr.idRol WHERE a.idCuenta=:id'''),{'id':id_cuenta}).scalars())
