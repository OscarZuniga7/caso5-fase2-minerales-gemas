"""Faker reproducible para agregar clientes ficticios SIN alterar datos originales.
No se ejecuta automáticamente. Uso: python scripts/generar_datos.py --cantidad 10
Produce SQL de inserción adicional; los IDs se verifican contra la tabla antes de importar.
"""
import argparse
from pathlib import Path
from faker import Faker

parser=argparse.ArgumentParser();parser.add_argument('--cantidad',type=int,default=10)
a=parser.parse_args()
if not 1<=a.cantidad<=50: raise SystemExit('Cantidad entre 1 y 50')
f=Faker('es_CL');Faker.seed(2026)
lines=['USE coleccion_db;','-- Clientes de demostración adicionales; usar en BD reconstruida desde origen.']
for i in range(a.cantidad):
    idc=f'DMO{i+1:05d}';nom=f.first_name().replace("'","''");ape=f.last_name().replace("'","''")
    lines.append(f"INSERT INTO CLIENTE (idCliente,nombre,apellido,correoSecundario,tipoCliente) VALUES ('{idc}','{nom}','{ape}',NULL,'Particular');")
out=Path(__file__).resolve().parents[1]/'sql'/'02_datos_adicionales.sql'
out.write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'Creado {out}; NO reemplaza 02_datos.sql.')
