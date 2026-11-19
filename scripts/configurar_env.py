"""Generar .env privado con claves aleatorias. Ejecutar desde la raíz: python scripts/configurar_env.py"""
from pathlib import Path
import secrets
p=Path(__file__).resolve().parents[1]/'.env'
if p.exists():
    print('Ya existe .env; no se sobreescribe.'); raise SystemExit(0)
vals={
    'MYSQL_ROOT_PASSWORD':secrets.token_urlsafe(24),
    'MYSQL_APP_PASSWORD':secrets.token_urlsafe(24),
    'DEMO_ADMIN_PASSWORD':secrets.token_urlsafe(18),
    'DEMO_GESTOR_PASSWORD':secrets.token_urlsafe(18),
    'DEMO_CATALOGO_PASSWORD':secrets.token_urlsafe(18),
}
p.write_text('# NO SUBIR A GITHUB. Datos de demostración.\n'+''.join(f'{k}={v}\n' for k,v in vals.items()),encoding='utf-8')
try: p.chmod(0o600)
except OSError: pass
print('Creado .env PRIVADO. Abrirlo localmente para copiar las claves de acceso al PMV. No compartir en GitHub.')
