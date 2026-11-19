"""PMV integrado Caso 5 (UNAB): ventas, CRUD 2 tablas, roles, dashboard.
Las vistas y procedimientos R1..R12 se ejecutan por separado desde Workbench.
"""
import datetime as dt
from decimal import Decimal
import pandas as pd
import plotly.express as px
import streamlit as st
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from src.db import (engine, rows, scalar, registrar_venta, crear_coleccion,
                    actualizar_coleccion, desactivar_coleccion, crear_pieza,
                    actualizar_pieza, desactivar_pieza)
from src.auth import login, permisos_actuales

st.set_page_config(page_title='Caso 5 · Minerales y gemas',page_icon='💎',layout='wide')
ESTADOS=['Excelente','Bueno','Regular','En restauración']
RAREZA=['Común','Poco común','Raro','Muy raro','Único']
TIPOS=['Sin clasificar','Mineral','Fosil','Gema']


def dataframe(sql, params=None):
    return pd.DataFrame([dict(x) for x in rows(sql,params)])

def salir():
    st.session_state.pop('usuario',None)
    st.rerun()

def autorizacion(permiso):
    if permiso not in st.session_state.get('permisos',set()):
        st.error('Acceso denegado: el rol no dispone de este permiso.')
        st.stop()

def pantalla_login():
    st.title('💎 Sistema de Venta de Minerales y Gemas de Colección')
    st.write('PMV académico — Fase 2 · Caso 5')
    st.info('Los usuarios de prueba y sus contraseñas están documentados en el archivo privado `.env` de Codespaces.')
    with st.form('ingreso'):
        nombre=st.text_input('Usuario')
        clave=st.text_input('Contraseña',type='password')
        aceptar=st.form_submit_button('Ingresar')
    if aceptar:
        try:
            usuario=login(nombre.strip(),clave)
            if not usuario: st.error('Credenciales inválidas o usuario inactivo.')
            else:
                st.session_state['usuario']=usuario
                st.rerun()
        except SQLAlchemyError:
            st.error('No se pudo acceder a MySQL. Verifique docker compose ps y los logs de db/web.')


def pagina_inicio():
    st.header('Resumen del sistema')
    try:
        columnas=st.columns(4)
        for col,(tabla,label) in zip(columnas,[('COLECCION','Colecciones'),('PIEZA','Piezas'),('CLIENTE','Clientes'),('VENTA','Ventas')]):
            col.metric(label,scalar(f'SELECT COUNT(*) FROM {tabla}'))
        st.caption('Base coleccion_db. Las vistas y procedimientos R1–R12 se validan en MySQL Workbench, no se invocan desde este PMV.')
    except SQLAlchemyError as e: st.error(f'Error de conexión: {e}')


def pagina_ventas():
    autorizacion('registrar_venta')
    st.header('1 · Formulario transaccional de venta')
    st.caption('Una venta puede incluir varias piezas; VENTA y DETALLE_VENTA se guardan en una misma transacción.')
    clientes=rows('SELECT idCliente,nombre,apellido FROM CLIENTE ORDER BY nombre LIMIT 400')
    gestores=rows("SELECT idPersonal,nombre,apellido FROM PERSONAL WHERE cargo='Gestor comercial' ORDER BY nombre")
    piezas=rows('''SELECT p.idPieza,p.nombreComercial,p.valorEstimado,c.nombreColeccion
                  FROM PIEZA p JOIN COLECCION c ON c.idColeccion=p.idColeccion
                  WHERE p.activo=1 AND c.activo=1 ORDER BY p.idPieza''')
    if not clientes or not gestores or not piezas:
        st.warning('Faltan clientes, gestores o piezas activas para registrar ventas.')
        return
    cliente={r['idCliente']:f"{r['idCliente']} · {r['nombre']} {r['apellido']}" for r in clientes}
    gestor={r['idPersonal']:f"{r['idPersonal']} · {r['nombre']} {r['apellido']}" for r in gestores}
    etiquetas={r['idPieza']:f"{r['idPieza']} · {r['nombreComercial']} · {r['nombreColeccion']}" for r in piezas}
    pieza_map={r['idPieza']:r for r in piezas}
    # Se eligen piezas antes de abrir el formulario para poder mostrar un campo precio por pieza.
    seleccion=st.multiselect('Seleccione una o más piezas',list(etiquetas),format_func=lambda x:etiquetas[x])
    with st.form('nueva_venta',clear_on_submit=False):
        fecha=st.date_input('Fecha de venta',value=dt.date.today())
        cliente_sel=st.selectbox('Cliente',list(cliente),format_func=lambda x:cliente[x])
        gestor_sel=st.selectbox('Gestor comercial',list(gestor),format_func=lambda x:gestor[x])
        precios=[]
        for p in seleccion:
            sugerido=float(pieza_map[p]['valorEstimado'])
            precio=st.number_input('Precio acordado · '+etiquetas[p],min_value=0.01,value=max(0.01,sugerido),step=1.0,key='precio_'+p)
            precios.append((p,Decimal(str(precio))))
        if precios:
            st.metric('Total previsto',f"{sum((x[1] for x in precios),Decimal('0')):,.2f}")
        confirmar=st.form_submit_button('Registrar venta')
        if confirmar:
            if not seleccion: st.error('Debe seleccionar al menos una pieza.')
            else:
                try:
                    idv,tot=registrar_venta(fecha,cliente_sel,gestor_sel,precios)
                    st.success(f'Venta {idv} registrada correctamente. Total: {tot:,.2f}')
                except (ValueError,IntegrityError,SQLAlchemyError) as e:
                    st.error(f'No se pudo registrar: {e}')
    st.subheader('Últimas ventas')
    st.dataframe(dataframe('''SELECT v.idVenta,v.fechaVenta,v.montoTotal,c.nombre AS nombreCliente,
                                   c.apellido AS apellidoCliente FROM VENTA v
                           JOIN CLIENTE c ON c.idCliente=v.idCliente
                           ORDER BY v.fechaVenta DESC,v.idVenta DESC LIMIT 25'''),hide_index=True,use_container_width=True)
    st.caption('Los datos semilla contienen reventas de una misma pieza. El formulario evita duplicarla dentro de una venta, pero respeta el modelo y permite que aparezca en ventas diferentes.')


def form_coleccion(datos=None, pref='n'):
    d=datos or {}
    nombre=st.text_input('Nombre',value=d.get('nombreColeccion',''),key=pref+'colnom')
    tema=st.text_input('Temática',value=d.get('tematica') or '',key=pref+'coltema')
    fecha=st.date_input('Fecha de creación',value=d.get('fechaCreacion') or dt.date.today(),key=pref+'colfecha')
    responsable=st.text_input('Responsable',value=d.get('responsable',''),key=pref+'colresp')
    estado=st.selectbox('Conservación',ESTADOS,index=ESTADOS.index(d.get('estadoConservacion','Bueno')),key=pref+'colestado')
    return {'nombre':nombre.strip(),'tema':tema.strip() or None,'fecha':fecha,'responsable':responsable.strip(),'estado':estado}


def pagina_colecciones():
    autorizacion('crud_colecciones')
    st.header('2 · CRUD: Colecciones')
    tab1,tab2,tab3=st.tabs(['Consultar','Crear','Modificar / Desactivar'])
    with tab1:
        st.dataframe(dataframe('SELECT * FROM COLECCION ORDER BY idColeccion'),hide_index=True,use_container_width=True)
    with tab2:
        with st.form('crear_col'):
            d=form_coleccion(pref='crear')
            if st.form_submit_button('Crear colección'):
                if not d['nombre'] or not d['responsable']: st.error('Nombre y responsable obligatorios')
                else:
                    try: st.success(f'Creada {crear_coleccion(d)}')
                    except SQLAlchemyError as e: st.error(f'Error: {e}')
    with tab3:
        cols=rows('SELECT * FROM COLECCION ORDER BY idColeccion')
        if not cols: return
        opciones={r['idColeccion']:dict(r) for r in cols}
        pk=st.selectbox('Colección existente',list(opciones),format_func=lambda x:f"{x} · {opciones[x]['nombreColeccion']}")
        if pk:
            with st.form('modificar_col'):
                d=form_coleccion(opciones[pk],pref='mod_'+pk)
                modificar=st.form_submit_button('Guardar cambios')
                if modificar:
                    if not d['nombre'] or not d['responsable']: st.error('Nombre y responsable obligatorios')
                    else:
                        try: actualizar_coleccion(pk,d); st.success('Cambios guardados')
                        except SQLAlchemyError as e: st.error(str(e))
            if opciones[pk]['activo']:
                confirm=st.checkbox('Confirmo que deseo desactivar esta colección y sus piezas',key='confirmar_col')
                if st.button('Desactivar colección',disabled=not confirm):
                    try: desactivar_coleccion(pk); st.success('Colección y piezas desactivadas'); st.rerun()
                    except SQLAlchemyError as e: st.error(str(e))
            else: st.caption('Esta colección ya se encuentra inactiva.')


def form_pieza(colecciones,datos=None,pref='n'):
    d=datos or {}
    nombre=st.text_input('Nombre comercial',value=d.get('nombreComercial',''),key=pref+'pnom')
    origen=st.text_input('Procedencia geográfica',value=d.get('procedenciaGeografica') or '',key=pref+'pori')
    fecha=st.date_input('Fecha adquisición',value=d.get('fechaAdquisicion') or dt.date.today(),key=pref+'pfec')
    valor=st.number_input('Valor estimado',min_value=0.01,value=float(d.get('valorEstimado',1.0)),key=pref+'pval')
    estado=st.selectbox('Conservación',ESTADOS,index=ESTADOS.index(d.get('estadoConservacion','Bueno')),key=pref+'pest')
    rareza=st.selectbox('Rareza',RAREZA,index=RAREZA.index(d.get('nivelRareza','Común')),key=pref+'prar')
    actuales=list(colecciones)
    pred=d.get('idColeccion')
    idx=actuales.index(pred) if pred in actuales else 0
    coleccion=st.selectbox('Colección',actuales,index=idx,format_func=lambda x:colecciones[x],key=pref+'pcol')
    return {'nombre':nombre.strip(),'origen':origen.strip() or None,'fecha':fecha,'valor':Decimal(str(valor)),
            'estado':estado,'rareza':rareza,'coleccion':coleccion}


def pagina_piezas():
    autorizacion('crud_piezas')
    st.header('2 · CRUD: Piezas de colección')
    tab1,tab2,tab3=st.tabs(['Consultar','Crear','Modificar / Desactivar'])
    colrows=rows('SELECT idColeccion,nombreColeccion,activo FROM COLECCION ORDER BY idColeccion')
    colecciones={x['idColeccion']:x['nombreColeccion'] for x in colrows if x['activo']}
    with tab1:
        st.dataframe(dataframe('''SELECT p.idPieza,p.nombreComercial,p.idColeccion,p.valorEstimado,
                                   p.estadoConservacion,p.nivelRareza,p.activo FROM PIEZA p
                                 ORDER BY p.idPieza'''),hide_index=True,use_container_width=True)
    with tab2:
        if not colecciones: st.warning('Primero debe existir una colección activa.')
        else:
            with st.form('crear_pieza'):
                d=form_pieza(colecciones,pref='crear')
                tipo=st.selectbox('Clasificación',TIPOS)
                if st.form_submit_button('Crear pieza'):
                    if not d['nombre']: st.error('Nombre obligatorio')
                    else:
                        try: st.success(f'Creada {crear_pieza(d,tipo)} con clasificación {tipo}')
                        except SQLAlchemyError as e: st.error(f'Error: {e}')
    with tab3:
        piezas=rows('SELECT * FROM PIEZA ORDER BY idPieza')
        opciones={x['idPieza']:dict(x) for x in piezas}
        if not opciones: return
        pk=st.selectbox('Pieza existente',list(opciones),format_func=lambda x:f"{x} · {opciones[x]['nombreComercial']}")
        if pk:
            if not colecciones or opciones[pk]['idColeccion'] not in colecciones:
                st.warning('La colección está inactiva: no se puede modificar esta pieza.')
            else:
                with st.form('modificar_pieza'):
                    d=form_pieza(colecciones,opciones[pk],pref='mod_'+pk)
                    st.caption('La especialización Mineral/Fósil/Gema se conserva en la edición de campos básicos.')
                    if st.form_submit_button('Guardar cambios'):
                        if not d['nombre']: st.error('Nombre obligatorio')
                        else:
                            try: actualizar_pieza(pk,d); st.success('Cambios guardados')
                            except SQLAlchemyError as e: st.error(str(e))
                if opciones[pk]['activo']:
                    confirm=st.checkbox('Confirmo que deseo desactivar la pieza',key='confirmar_pza')
                    if st.button('Desactivar pieza',disabled=not confirm):
                        try: desactivar_pieza(pk); st.success('Pieza desactivada'); st.rerun()
                        except SQLAlchemyError as e: st.error(str(e))
                else: st.caption('Esta pieza ya está inactiva.')


def pagina_dashboard():
    autorizacion('ver_dashboard')
    st.header('4 · Dashboard · cuatro preguntas de negocio')
    fecha_min=scalar('SELECT MIN(fechaVenta) FROM VENTA') or dt.date(2023,1,1)
    fecha_max=scalar('SELECT MAX(fechaVenta) FROM VENTA') or dt.date.today()
    col1,col2=st.columns(2)
    inicio=col1.date_input('Desde',value=fecha_min,key='desde')
    fin=col2.date_input('Hasta',value=max(fecha_max,dt.date.today()),key='hasta')
    if inicio>fin: st.error('Rango inválido'); return
    todas=rows('SELECT idColeccion,nombreColeccion FROM COLECCION ORDER BY nombreColeccion')
    opciones={'Todas':'Todas',**{x['idColeccion']:x['nombreColeccion'] for x in todas}}
    coleccion=st.selectbox('Filtrar colección',list(opciones),format_func=lambda x:opciones[x])
    col_filter='(:coleccion = \'Todas\' OR p.idColeccion=:coleccion)'
    params={'inicio':inicio,'fin':fin,'coleccion':coleccion}

    st.subheader('P1 · Colecciones con mayor monto de ventas')
    q1=dataframe('''SELECT c.idColeccion,c.nombreColeccion,ROUND(SUM(dv.precioVenta),2) AS monto
           FROM COLECCION c JOIN PIEZA p ON p.idColeccion=c.idColeccion
           JOIN DETALLE_VENTA dv ON dv.idPieza=p.idPieza JOIN VENTA v ON v.idVenta=dv.idVenta
           WHERE v.fechaVenta BETWEEN :inicio AND :fin AND '''+col_filter+'''
           GROUP BY c.idColeccion,c.nombreColeccion ORDER BY monto DESC''',params)
    if not q1.empty:
        st.plotly_chart(px.bar(q1,x='nombreColeccion',y='monto',title='Ingresos por colección',labels={'monto':'Monto','nombreColeccion':'Colección'}),use_container_width=True)
    else: st.info('Sin ventas en el período / colección.')

    st.subheader('P2 · Distribución de piezas comercializadas por tipo')
    subtipo="CASE WHEN m.idPieza IS NOT NULL THEN 'Mineral' WHEN f.idPieza IS NOT NULL THEN 'Fosil' WHEN g.idPieza IS NOT NULL THEN 'Gema' ELSE 'Sin clasificar' END"
    q2=dataframe(f'''SELECT {subtipo} AS tipoPieza, COUNT(*) AS piezasComercializadas
          FROM DETALLE_VENTA dv JOIN VENTA v ON v.idVenta=dv.idVenta
          JOIN PIEZA p ON p.idPieza=dv.idPieza LEFT JOIN MINERAL m ON m.idPieza=p.idPieza
          LEFT JOIN FOSIL f ON f.idPieza=p.idPieza LEFT JOIN GEMA g ON g.idPieza=p.idPieza
          WHERE v.fechaVenta BETWEEN :inicio AND :fin AND {col_filter}
          GROUP BY tipoPieza ORDER BY piezasComercializadas DESC''',params)
    tipo_filtro=st.selectbox('Tipo de pieza',['Todos']+TIPOS,key='tipo_panel')
    if not q2.empty:
        if tipo_filtro!='Todos': q2=q2[q2['tipoPieza']==tipo_filtro]
        if not q2.empty: st.plotly_chart(px.pie(q2,names='tipoPieza',values='piezasComercializadas',title='Composición por tipo'),use_container_width=True)
    else: st.info('Sin registros para el filtro')

    st.subheader('P3 · Relación entre monto de venta y evaluación')
    q3=dataframe('''SELECT v.idVenta,v.fechaVenta,CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
               c.nombreColeccion AS coleccion,v.montoTotal,ROUND(AVG(ev.calificacion),2) AS calificacionMedia
          FROM VENTA v JOIN CLIENTE cl ON cl.idCliente=v.idCliente
          JOIN DETALLE_VENTA dv ON dv.idVenta=v.idVenta
          JOIN PIEZA p ON p.idPieza=dv.idPieza JOIN COLECCION c ON c.idColeccion=p.idColeccion
          JOIN EVALUACION ev ON ev.idVenta=v.idVenta
          WHERE v.fechaVenta BETWEEN :inicio AND :fin AND '''+col_filter+'''
          GROUP BY v.idVenta,v.fechaVenta,cl.nombre,cl.apellido,c.idColeccion,c.nombreColeccion,v.montoTotal
          ORDER BY v.fechaVenta''',params)
    if not q3.empty:
        st.plotly_chart(px.scatter(q3,x='montoTotal',y='calificacionMedia',hover_data=['idVenta','cliente','coleccion'],
                   title='Monto de venta vs. calificación (1–5)'),use_container_width=True)
        st.dataframe(q3,hide_index=True,use_container_width=True)
    else: st.info('No hay ventas con evaluaciones para los filtros.')

    st.subheader('P4 · ¿Cuáles son los clientes que más ingresos generan?')
    st.caption('Pregunta adicional propuesta: permite priorizar acciones de fidelización de clientes. No equivale a P1–P3.')
    q4=dataframe('''SELECT cl.idCliente,CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
                COUNT(DISTINCT v.idVenta) AS compras,ROUND(SUM(dv.precioVenta),2) AS monto
          FROM CLIENTE cl JOIN VENTA v ON v.idCliente=cl.idCliente
          JOIN DETALLE_VENTA dv ON dv.idVenta=v.idVenta JOIN PIEZA p ON p.idPieza=dv.idPieza
          WHERE v.fechaVenta BETWEEN :inicio AND :fin AND '''+col_filter+'''
          GROUP BY cl.idCliente,cl.nombre,cl.apellido ORDER BY monto DESC LIMIT 10''',params)
    if not q4.empty:
        st.plotly_chart(px.bar(q4,x='cliente',y='monto',title='Top 10 clientes por monto',hover_data=['compras']),use_container_width=True)
        st.dataframe(q4,hide_index=True,use_container_width=True)
    else: st.info('Sin datos para P4.')
    st.caption('Pandas prepara las tablas y Plotly representa los gráficos. Consultas PMV distintas a R1–R12.')


def main():
    if 'usuario' not in st.session_state:
        pantalla_login()
        return
    user=st.session_state['usuario']
    try:
        permisos=permisos_actuales(user['idCuenta'])
    except SQLAlchemyError:
        st.error('Servidor MySQL no disponible.'); return
    st.session_state['permisos']=permisos
    if not permisos:
        st.error('La cuenta no tiene permisos activos.')
        if st.button('Cerrar sesión'): salir()
        return
    with st.sidebar:
        st.title('💎 Caso 5')
        st.write(f"Sesión: **{user['nombre']}**")
        opciones=['Inicio']
        for perm,nombre in [('registrar_venta','Registrar venta'),('crud_colecciones','CRUD colecciones'),
                            ('crud_piezas','CRUD piezas'),('ver_dashboard','Dashboard')]:
            if perm in permisos: opciones.append(nombre)
        pag=st.radio('Menú',opciones)
        st.divider()
        st.button('Cerrar sesión',on_click=salir)
    try:
        {'Inicio':pagina_inicio,'Registrar venta':pagina_ventas,'CRUD colecciones':pagina_colecciones,
         'CRUD piezas':pagina_piezas,'Dashboard':pagina_dashboard}[pag]()
    except SQLAlchemyError as e:
        st.error(f'Error consultando MySQL: {e}')

if __name__=='__main__':main()
