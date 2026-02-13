/* ==========================================================
   TRABAJO: Implementación Modelo Relacional - Semana 6
   OBJETIVO: Diseño de Base de Datos Consultorio Santa Gema
   ========================================================== */

-- 0. BORRADO DE OBJETOS (Para permitir re-ejecución sin errores)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE detalle_receta CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE pago CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE receta CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE medicamento CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE tipo_receta CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE medico CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE especialidad CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE paciente CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE digitador CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE comuna CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL; -- Ignora errores si las tablas no existen aún
END;
/

-- ==========================================================
-- 1. CREACIÓN DE TABLAS (CASO 1)
-- ==========================================================

-- Tabla Especialidad: Incremento automático (Identity)
CREATE TABLE especialidad (
    id_especialidad NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1 PRIMARY KEY,
    nombre_especialidad VARCHAR2(50) NOT NULL
);

-- Tabla Comuna: Incremento automático comenzando en 1101
CREATE TABLE comuna (
    id_comuna NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1101 INCREMENT BY 1 PRIMARY KEY,
    nombre_comuna VARCHAR2(50) NOT NULL
);

-- Tabla Paciente (Incluye DV restrictivo)
CREATE TABLE paciente (
    run_paciente NUMBER(8) PRIMARY KEY,
    dv_paciente  CHAR(1) NOT NULL,
    nombre       VARCHAR2(50) NOT NULL,
    apellido     VARCHAR2(50) NOT NULL,
    direccion    VARCHAR2(100),
    edad         NUMBER(3), -- Se eliminará en el Caso 2
    id_comuna    NUMBER NOT NULL,
    CONSTRAINT ck_dv_paciente CHECK (UPPER(dv_paciente) BETWEEN '0' AND '9' OR UPPER(dv_paciente) = 'K'),
    CONSTRAINT fk_paciente_comuna FOREIGN KEY (id_comuna) REFERENCES comuna(id_comuna)
);

-- Tabla Medico (Teléfono único y DV restrictivo)
CREATE TABLE medico (
    run_medico      NUMBER(8) PRIMARY KEY,
    dv_medico       CHAR(1) NOT NULL,
    nombre          VARCHAR2(50) NOT NULL,
    telefono        VARCHAR2(15) NOT NULL,
    id_especialidad NUMBER NOT NULL,
    CONSTRAINT un_tel_medico UNIQUE (telefono),
    CONSTRAINT ck_dv_medico CHECK (UPPER(dv_medico) BETWEEN '0' AND '9' OR UPPER(dv_medico) = 'K'),
    CONSTRAINT fk_medico_especialidad FOREIGN KEY (id_especialidad) REFERENCES especialidad(id_especialidad)
);

-- Tabla Digitador
CREATE TABLE digitador (
    run_digitador NUMBER(8) PRIMARY KEY,
    dv_digitador  CHAR(1) NOT NULL,
    nombre        VARCHAR2(50) NOT NULL,
    CONSTRAINT ck_dv_digitador CHECK (UPPER(dv_digitador) BETWEEN '0' AND '9' OR UPPER(dv_digitador) = 'K')
);

-- Tabla Tipo Receta
CREATE TABLE tipo_receta (
    id_tipo_receta NUMBER PRIMARY KEY,
    nombre_tipo    VARCHAR2(50) NOT NULL -- digital, magistral, retenida, general, veterinaria
);

-- Tabla Receta
CREATE TABLE receta (
    id_receta       NUMBER PRIMARY KEY,
    fecha_emision   DATE NOT NULL,
    fecha_expira    DATE,
    diagnostico     VARCHAR2(500) NOT NULL,
    observaciones   VARCHAR2(1000),
    run_paciente    NUMBER(8) NOT NULL,
    run_medico      NUMBER(8) NOT NULL,
    run_digitador   NUMBER(8) NOT NULL,
    id_tipo_receta  NUMBER NOT NULL,
    CONSTRAINT fk_receta_paciente FOREIGN KEY (run_paciente) REFERENCES paciente(run_paciente),
    CONSTRAINT fk_receta_medico FOREIGN KEY (run_medico) REFERENCES medico(run_medico),
    CONSTRAINT fk_receta_digitador FOREIGN KEY (run_digitador) REFERENCES digitador(run_digitador),
    CONSTRAINT fk_receta_tipo FOREIGN KEY (id_tipo_receta) REFERENCES tipo_receta(id_tipo_receta)
);

-- Tabla Medicamento
CREATE TABLE medicamento (
    id_medicamento  NUMBER PRIMARY KEY,
    nombre          VARCHAR2(100) NOT NULL,
    dosis_recom     VARCHAR2(100),
    stock           NUMBER NOT NULL
);

-- Tabla Detalle Receta (Relación Muchos a Muchos entre Receta y Medicamento)
CREATE TABLE detalle_receta (
    id_receta       NUMBER NOT NULL,
    id_medicamento  NUMBER NOT NULL,
    cantidad        NUMBER NOT NULL,
    PRIMARY KEY (id_receta, id_medicamento),
    CONSTRAINT fk_det_receta FOREIGN KEY (id_receta) REFERENCES receta(id_receta),
    CONSTRAINT fk_det_medica FOREIGN KEY (id_medicamento) REFERENCES medicamento(id_medicamento)
);

-- Tabla Pago
CREATE TABLE pago (
    id_pago         NUMBER PRIMARY KEY,
    monto_pagado    NUMBER NOT NULL,
    fecha_pago      DATE NOT NULL,
    id_receta       NUMBER NOT NULL,
    CONSTRAINT fk_pago_receta FOREIGN KEY (id_receta) REFERENCES receta(id_receta)
);

-- ==========================================================
-- 2. MODIFICACIONES (CASO 2 - REQUERIMIENTOS ALTER TABLE)
-- ==========================================================

-- A. Precio unitario con rango entre $1.000 y $2.000.000
ALTER TABLE medicamento ADD precio_unitario NUMBER;
ALTER TABLE medicamento ADD CONSTRAINT ck_precio_rango 
    CHECK (precio_unitario BETWEEN 1000 AND 2000000);

-- B. Restricción de métodos de pago permitidos
ALTER TABLE pago ADD metodo_pago VARCHAR2(20);
ALTER TABLE pago ADD CONSTRAINT ck_metodos_pago 
    CHECK (UPPER(metodo_pago) IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA'));

-- C. Optimización de datos del Paciente (Eliminar Edad, Agregar Fecha Nacimiento)
ALTER TABLE paciente DROP COLUMN edad;
ALTER TABLE paciente ADD fecha_nacimiento DATE NOT NULL;

-- Finalización del script
COMMIT;