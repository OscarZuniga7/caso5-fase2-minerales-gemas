"""Pruebas estáticas sin Docker; no sustituyen prueba MySQL real."""
from pathlib import Path
import yaml
import importlib.util
p=Path(__file__).resolve().parents[1]

def test_archivos():
    for f in ['Dockerfile','docker-compose.yml','README.md','app.py','sql/00_integral.sql','sql/05_pruebas.sql',
              'sql/01_schema.sql','sql/02_datos.sql','sql/03_vistas.sql','sql/04_procedimientos.sql']:
        assert (p/f).exists()

def test_sql_requerimientos():
    views=(p/'sql/03_vistas.sql').read_text()
    procs=(p/'sql/04_procedimientos.sql').read_text()
    assert views.count('CREATE OR REPLACE VIEW ')==6
    assert procs.count('CREATE PROCEDURE ')==6
    for r in [2,3,5,6,7,8]: assert f'v_r{r}_' in views
    for r in [1,4,9,10,11,12]: assert f'sp_r{r}_' in procs
    assert (p/'sql/01_schema.sql').read_text().count('CREATE TABLE ')==19

def test_yaml():
    conf=yaml.safe_load((p/'docker-compose.yml').read_text())
    assert set(conf['services'])=={'db','web'}
    assert conf['services']['db']['image']=='mysql:8.4'
    assert 'mysql_data' in conf['volumes']

def test_password_hash():
    # No requiere un servidor MySQL, pero sí SQLAlchemy para importar auth.
    from src.auth import hash_password, check_password
    v=hash_password('una_contrasena_larga_y_aleatoria')
    assert check_password('una_contrasena_larga_y_aleatoria',v)
    assert not check_password('incorrecta',v)
    assert not check_password('algo','a025df065d9de6ca0c608c62ce3112fcfbe389434ebf7ad9b840e0fbe8d796a7')
