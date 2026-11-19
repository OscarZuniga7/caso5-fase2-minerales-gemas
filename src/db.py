"""Conexiones y utilidades para el Caso 5. La app NO llama a R1...R12: esas son evidencias SQL en Workbench."""
import os
import secrets
from decimal import Decimal
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from sqlalchemy.exc import IntegrityError

_ENGINE = None

def engine():
    global _ENGINE
    if _ENGINE is None:
        url = URL.create('mysql+pymysql', username=os.getenv('DB_USER','caso5_app'),
                         password=os.environ['MYSQL_APP_PASSWORD'],
                         host=os.getenv('DB_HOST','db'), port=int(os.getenv('DB_PORT','3306')),
                         database=os.getenv('DB_NAME','coleccion_db'),
                         query={'charset':'utf8mb4'})
        _ENGINE=create_engine(url, pool_pre_ping=True, pool_recycle=1800, future=True)
    return _ENGINE

def rows(sql, params=None):
    with engine().connect() as conn:
        return conn.execute(text(sql),params or {}).mappings().all()

def scalar(sql, params=None):
    with engine().connect() as conn:
        return conn.execute(text(sql),params or {}).scalar()

def insert_id(prefix):
    # <=10 caracteres (PK VARCHAR(10)), colisión controlada por PRIMARY KEY.
    return prefix + secrets.token_hex(3).upper()


def registrar_venta(fecha, id_cliente, id_gestor, items):
    """Venta + detalles en una única transacción: rollback completo ante errores."""
    if not items or len({idp for idp, price in items}) != len(items):
        raise ValueError('Seleccione piezas sin repetir dentro de la misma venta')
    if any(Decimal(str(precio)) <= 0 for _,precio in items):
        raise ValueError('Todos los precios deben ser positivos')
    total=sum((Decimal(str(precio)) for _,precio in items), Decimal('0'))
    id_venta=insert_id('V')
    with engine().begin() as con:
        if not con.execute(text('SELECT COUNT(*) FROM CLIENTE WHERE idCliente=:x'),{'x':id_cliente}).scalar():
            raise ValueError('Cliente inexistente')
        if not con.execute(text("SELECT COUNT(*) FROM PERSONAL WHERE idPersonal=:x AND cargo='Gestor comercial'"),{'x':id_gestor}).scalar():
            raise ValueError('El personal seleccionado no es gestor comercial')
        validos={r[0] for r in con.execute(text('SELECT idPieza FROM PIEZA WHERE activo=1'))}
        if not all(i in validos for i,_ in items):
            raise ValueError('Hay piezas inexistentes o inactivas')
        con.execute(text('INSERT INTO VENTA(idVenta,fechaVenta,montoTotal,idCliente,idPersonal) VALUES (:id,:f,:m,:c,:g)'),
                    {'id':id_venta,'f':fecha,'m':total,'c':id_cliente,'g':id_gestor})
        for pos,(id_pieza,precio) in enumerate(items,1):
            con.execute(text('INSERT INTO DETALLE_VENTA(idVenta,nroCorrelativo,precioVenta,idPieza) VALUES (:v,:n,:p,:i)'),
                        {'v':id_venta,'n':pos,'p':Decimal(str(precio)),'i':id_pieza})
    return id_venta, total


def crear_coleccion(values):
    pk=insert_id('COL')
    with engine().begin() as con:
        con.execute(text('''INSERT INTO COLECCION(idColeccion,nombreColeccion,tematica,fechaCreacion,responsable,estadoConservacion,activo)
          VALUES(:id,:nombre,:tema,:fecha,:responsable,:estado,1)'''),{'id':pk,**values})
    return pk


def actualizar_coleccion(pk, values):
    with engine().begin() as con:
        con.execute(text('''UPDATE COLECCION SET nombreColeccion=:nombre, tematica=:tema,fechaCreacion=:fecha,
             responsable=:responsable, estadoConservacion=:estado WHERE idColeccion=:id'''),{'id':pk,**values})


def desactivar_coleccion(pk):
    with engine().begin() as con:
        # Desactivar además piezas de esa colección evita usar registros inactivos en nuevas ventas.
        con.execute(text('UPDATE COLECCION SET activo=0 WHERE idColeccion=:id'),{'id':pk})
        con.execute(text('UPDATE PIEZA SET activo=0 WHERE idColeccion=:id'),{'id':pk})


def crear_pieza(values, tipo):
    pk=insert_id('P')
    with engine().begin() as con:
        con.execute(text('''INSERT INTO PIEZA(idPieza,nombreComercial,procedenciaGeografica,fechaAdquisicion,
              valorEstimado,estadoConservacion,nivelRareza,idColeccion,activo)
              VALUES(:id,:nombre,:origen,:fecha,:valor,:estado,:rareza,:coleccion,1)'''),{'id':pk,**values})
        subtipo={'Mineral':'MINERAL','Fosil':'FOSIL','Gema':'GEMA'}.get(tipo)
        if subtipo:
            # Subtipo con atributos adicionales opcionales según DDL; FKs evitan piezas inexistentes.
            con.execute(text(f'INSERT INTO {subtipo}(idPieza) VALUES(:id)'),{'id':pk})
    return pk


def actualizar_pieza(pk, values):
    with engine().begin() as con:
        con.execute(text('''UPDATE PIEZA SET nombreComercial=:nombre,procedenciaGeografica=:origen,
          fechaAdquisicion=:fecha,valorEstimado=:valor,estadoConservacion=:estado,
          nivelRareza=:rareza,idColeccion=:coleccion WHERE idPieza=:id'''),{'id':pk,**values})


def desactivar_pieza(pk):
    with engine().begin() as con:
        con.execute(text('UPDATE PIEZA SET activo=0 WHERE idPieza=:id'),{'id':pk})
