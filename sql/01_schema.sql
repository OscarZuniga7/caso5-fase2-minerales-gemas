-- =====================================================================
-- PROYECTO SEMESTRAL 2026 - TDFI103 Bases de Datos - Fase 2
-- Caso 5: Sistema de Venta de Minerales, Fósiles y Gemas de Colección
-- 01_schema.sql : creación de BD, tablas, PK, FK y restricciones
-- =====================================================================
SET NAMES utf8mb4;
-- ATENCION: solo para reconstruccion de la BD de DEMOSTRACION. Borra datos previos.
SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS coleccion_db;
CREATE DATABASE coleccion_db CHARACTER SET utf8mb4;
USE coleccion_db;

CREATE TABLE COLECCION (
  idColeccion        VARCHAR(10)  NOT NULL,
  nombreColeccion    VARCHAR(100) NOT NULL,
  tematica           VARCHAR(80)  NULL,
  fechaCreacion      DATE         NOT NULL,
  responsable        VARCHAR(100) NOT NULL,
  estadoConservacion VARCHAR(30)  NOT NULL,
  activo             TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (idColeccion),
  CONSTRAINT ck_col_estado CHECK (estadoConservacion IN ('Excelente','Bueno','Regular','En restauración'))
) ENGINE=InnoDB;

CREATE TABLE PIEZA (
  idPieza              VARCHAR(10)   NOT NULL,
  nombreComercial      VARCHAR(100)  NOT NULL,
  procedenciaGeografica VARCHAR(100) NULL,
  fechaAdquisicion     DATE          NOT NULL,
  valorEstimado        DECIMAL(12,2) NOT NULL,
  estadoConservacion   VARCHAR(30)   NOT NULL,
  nivelRareza          VARCHAR(30)   NOT NULL,
  idColeccion          VARCHAR(10)   NOT NULL,
  idPiezaReemplazada   VARCHAR(10)   NULL,
  activo               TINYINT(1)    NOT NULL DEFAULT 1,
  PRIMARY KEY (idPieza),
  UNIQUE KEY uq_pieza_reemplazada (idPiezaReemplazada),
  CONSTRAINT fk_pieza_coleccion FOREIGN KEY (idColeccion) REFERENCES COLECCION(idColeccion),
  CONSTRAINT fk_pieza_reemplaza FOREIGN KEY (idPiezaReemplazada) REFERENCES PIEZA(idPieza),
  CONSTRAINT ck_pieza_valor   CHECK (valorEstimado > 0),
  CONSTRAINT ck_pieza_estado  CHECK (estadoConservacion IN ('Excelente','Bueno','Regular','En restauración')),
  CONSTRAINT ck_pieza_rareza  CHECK (nivelRareza IN ('Común','Poco común','Raro','Muy raro','Único')),
  CONSTRAINT ck_pieza_noauto  CHECK (idPiezaReemplazada IS NULL OR idPiezaReemplazada <> idPieza)
) ENGINE=InnoDB;

CREATE TABLE CERTIFICACION (
  idCertificado  VARCHAR(10)  NOT NULL,
  organismoEmisor VARCHAR(100) NOT NULL,
  fechaEmision   DATE         NOT NULL,
  resultado      VARCHAR(50)  NULL,
  idPieza        VARCHAR(10)  NOT NULL,
  PRIMARY KEY (idCertificado),
  UNIQUE KEY uq_cert_pieza (idPieza),              -- relación 1:1 con PIEZA
  CONSTRAINT fk_cert_pieza FOREIGN KEY (idPieza) REFERENCES PIEZA(idPieza)
) ENGINE=InnoDB;

-- Subtipos (disyunción y parcialidad: una pieza en a lo más un subtipo)
CREATE TABLE MINERAL (
  idPieza     VARCHAR(10) NOT NULL,
  dureza      DECIMAL(3,1) NULL,
  tipoMineral VARCHAR(60)  NULL,
  PRIMARY KEY (idPieza),
  CONSTRAINT fk_mineral_pieza FOREIGN KEY (idPieza) REFERENCES PIEZA(idPieza) ON DELETE CASCADE,
  CONSTRAINT ck_mineral_dureza CHECK (dureza IS NULL OR dureza BETWEEN 1 AND 10)
) ENGINE=InnoDB;

CREATE TABLE FOSIL (
  idPieza            VARCHAR(10) NOT NULL,
  periodoGeologico   VARCHAR(60)  NULL,
  edadEstimada       VARCHAR(60)  NULL,
  especieRepresentada VARCHAR(100) NULL,
  PRIMARY KEY (idPieza),
  CONSTRAINT fk_fosil_pieza FOREIGN KEY (idPieza) REFERENCES PIEZA(idPieza) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE GEMA (
  idPieza  VARCHAR(10)  NOT NULL,
  quilates DECIMAL(6,2) NULL,
  color    VARCHAR(40)  NULL,
  calidad  VARCHAR(40)  NULL,
  PRIMARY KEY (idPieza),
  CONSTRAINT fk_gema_pieza FOREIGN KEY (idPieza) REFERENCES PIEZA(idPieza) ON DELETE CASCADE,
  CONSTRAINT ck_gema_quilates CHECK (quilates IS NULL OR quilates > 0)
) ENGINE=InnoDB;

CREATE TABLE EXPOSICION (
  idExposicion VARCHAR(10)  NOT NULL,
  nombre       VARCHAR(100) NOT NULL,
  lugar        VARCHAR(100) NOT NULL,
  tematica     VARCHAR(80)  NULL,
  fechaInicio  DATE         NOT NULL,
  fechaTermino DATE         NULL,
  PRIMARY KEY (idExposicion),
  CONSTRAINT ck_expo_fechas CHECK (fechaTermino IS NULL OR fechaTermino >= fechaInicio)
) ENGINE=InnoDB;

CREATE TABLE PARTICIPACION_EXPOSICION (
  idPieza            VARCHAR(10)  NOT NULL,
  idExposicion       VARCHAR(10)  NOT NULL,
  fechaIncorporacion DATE         NOT NULL,
  ubicacion          VARCHAR(100) NOT NULL,
  estadoConservacion VARCHAR(30)  NOT NULL,
  observaciones      VARCHAR(255) NULL,
  PRIMARY KEY (idPieza, idExposicion),
  CONSTRAINT fk_part_pieza FOREIGN KEY (idPieza) REFERENCES PIEZA(idPieza),
  CONSTRAINT fk_part_expo  FOREIGN KEY (idExposicion) REFERENCES EXPOSICION(idExposicion),
  CONSTRAINT ck_part_estado CHECK (estadoConservacion IN ('Excelente','Bueno','Regular','En restauración'))
) ENGINE=InnoDB;

CREATE TABLE CLIENTE (
  idCliente       VARCHAR(10) NOT NULL,
  nombre          VARCHAR(100) NOT NULL,
  apellido        VARCHAR(60) NOT NULL,
  correoSecundario VARCHAR(100) NULL,
  tipoCliente     VARCHAR(30) NOT NULL,
  PRIMARY KEY (idCliente),
  CONSTRAINT ck_cli_tipo CHECK (tipoCliente IN ('Coleccionista','Museo','Centro de investigación','Galería','Particular'))
) ENGINE=InnoDB;

CREATE TABLE TELEFONO (
  idCliente VARCHAR(10) NOT NULL,
  telefono  VARCHAR(20) NOT NULL,
  PRIMARY KEY (idCliente, telefono),
  CONSTRAINT fk_tel_cliente FOREIGN KEY (idCliente) REFERENCES CLIENTE(idCliente) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE PERSONAL (
  idPersonal VARCHAR(10) NOT NULL,
  nombre     VARCHAR(60) NOT NULL,
  apellido   VARCHAR(60) NOT NULL,
  cargo      VARCHAR(30) NOT NULL,
  PRIMARY KEY (idPersonal),
  CONSTRAINT ck_per_cargo CHECK (cargo IN ('Catalogador','Tasador','Restaurador','Gestor comercial','Administrador'))
) ENGINE=InnoDB;

CREATE TABLE VENTA (
  idVenta    VARCHAR(10)   NOT NULL,
  fechaVenta DATE          NOT NULL,
  montoTotal DECIMAL(12,2) NOT NULL,
  idCliente  VARCHAR(10)   NOT NULL,
  idPersonal VARCHAR(10)   NOT NULL,   -- gestor comercial de la venta (1 por venta)
  PRIMARY KEY (idVenta),
  CONSTRAINT fk_venta_cliente  FOREIGN KEY (idCliente)  REFERENCES CLIENTE(idCliente),
  CONSTRAINT fk_venta_personal FOREIGN KEY (idPersonal) REFERENCES PERSONAL(idPersonal),
  CONSTRAINT ck_venta_monto CHECK (montoTotal >= 0)
) ENGINE=InnoDB;

CREATE TABLE DETALLE_VENTA (          -- entidad débil de VENTA
  idVenta        VARCHAR(10)   NOT NULL,
  nroCorrelativo INT           NOT NULL,
  precioVenta    DECIMAL(12,2) NOT NULL,
  idPieza        VARCHAR(10)   NOT NULL,
  PRIMARY KEY (idVenta, nroCorrelativo),
  CONSTRAINT fk_dv_venta FOREIGN KEY (idVenta) REFERENCES VENTA(idVenta) ON DELETE CASCADE,
  CONSTRAINT fk_dv_pieza FOREIGN KEY (idPieza) REFERENCES PIEZA(idPieza),
  CONSTRAINT ck_dv_precio CHECK (precioVenta > 0),
  CONSTRAINT ck_dv_corr   CHECK (nroCorrelativo >= 1)
) ENGINE=InnoDB;

CREATE TABLE EVALUACION (             -- entidad débil de VENTA
  idVenta      VARCHAR(10)  NOT NULL,
  correlativo  INT          NOT NULL,
  fechaEvaluacion DATE      NOT NULL,
  calificacion INT          NOT NULL,
  comentario   VARCHAR(255) NULL,
  PRIMARY KEY (idVenta, correlativo),
  CONSTRAINT fk_eval_venta FOREIGN KEY (idVenta) REFERENCES VENTA(idVenta) ON DELETE CASCADE,
  CONSTRAINT ck_eval_cal CHECK (calificacion BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE RESERVA (
  idReserva     VARCHAR(10) NOT NULL,
  fechaReserva  DATE        NOT NULL,
  estadoReserva VARCHAR(30) NOT NULL,
  idCliente     VARCHAR(10) NOT NULL,
  idPieza       VARCHAR(10) NOT NULL,
  PRIMARY KEY (idReserva),
  CONSTRAINT fk_res_cliente FOREIGN KEY (idCliente) REFERENCES CLIENTE(idCliente),
  CONSTRAINT fk_res_pieza   FOREIGN KEY (idPieza)   REFERENCES PIEZA(idPieza),
  CONSTRAINT ck_res_estado CHECK (estadoReserva IN ('Pendiente','Confirmada','Cancelada','Vencida'))
) ENGINE=InnoDB;

CREATE TABLE CUENTA_USUARIO (
  idCuenta      VARCHAR(10)  NOT NULL,
  nombreUsuario VARCHAR(50)  NOT NULL,
  contrasena    VARCHAR(255) NOT NULL,        -- hash SHA-256 (hex)
  estado        VARCHAR(20)  NOT NULL,
  idPersonal    VARCHAR(10)  NOT NULL,
  PRIMARY KEY (idCuenta),
  UNIQUE KEY uq_cuenta_usuario (nombreUsuario),
  UNIQUE KEY uq_cuenta_personal (idPersonal),  -- 1 cuenta por persona
  CONSTRAINT fk_cuenta_personal FOREIGN KEY (idPersonal) REFERENCES PERSONAL(idPersonal),
  CONSTRAINT ck_cuenta_estado CHECK (estado IN ('ACTIVA','INACTIVA'))
) ENGINE=InnoDB;

CREATE TABLE ROL (
  idRol     VARCHAR(10) NOT NULL,
  nombreRol VARCHAR(50) NOT NULL,
  PRIMARY KEY (idRol),
  UNIQUE KEY uq_rol_nombre (nombreRol)
) ENGINE=InnoDB;

CREATE TABLE ASIGNADO (
  idCuenta VARCHAR(10) NOT NULL,
  idRol    VARCHAR(10) NOT NULL,
  PRIMARY KEY (idCuenta, idRol),
  CONSTRAINT fk_asig_cuenta FOREIGN KEY (idCuenta) REFERENCES CUENTA_USUARIO(idCuenta) ON DELETE CASCADE,
  CONSTRAINT fk_asig_rol    FOREIGN KEY (idRol)    REFERENCES ROL(idRol) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE PERMISO_ROL (
  idRol   VARCHAR(10)  NOT NULL,
  permiso VARCHAR(100) NOT NULL,
  PRIMARY KEY (idRol, permiso),
  CONSTRAINT fk_perm_rol FOREIGN KEY (idRol) REFERENCES ROL(idRol) ON DELETE CASCADE
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
