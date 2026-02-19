/* ========================================================================
   TRABAJO: Poblamiento y Consultas SQL - Semana 7
   HOLDING: Carpenter SPA
   AUTORES: Daniel Ceballos & Catalina Hillmer
   ======================================================================== */

-- 0. LIMPIEZA DE OBJETOS (Para permitir re-ejecución sin errores)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE personal CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE compania CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE comuna CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE region CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE idioma CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_comuna';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_compania';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ========================================================================
-- CASO 1: IMPLEMENTACIÓN DEL MODELO (DDL)
-- ========================================================================
-- Se crean las tablas respetando la jerarquía de integridad referencial.

-- Tabla Región con Identity (Inicio 7, Incremento 2)
CREATE TABLE region (
    id_region NUMBER GENERATED ALWAYS AS IDENTITY START WITH 7 INCREMENT BY 2,
    nombre_region VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_region PRIMARY KEY (id_region)
);

-- Tabla Idioma con Identity (Inicio 25, Incremento 3)
CREATE TABLE idioma (
    id_idioma NUMBER GENERATED ALWAYS AS IDENTITY START WITH 25 INCREMENT BY 3,
    nombre_idioma VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_idioma PRIMARY KEY (id_idioma)
);

-- Tabla Comuna (Poblamiento mediante secuencia externa)
CREATE TABLE comuna (
    id_comuna NUMBER NOT NULL,
    nombre_comuna VARCHAR2(100) NOT NULL,
    id_region NUMBER NOT NULL,
    CONSTRAINT pk_comuna PRIMARY KEY (id_comuna),
    CONSTRAINT fk_comuna_region FOREIGN KEY (id_region) REFERENCES region(id_region)
);

-- Tabla Compañía (Poblamiento mediante secuencia externa)
CREATE TABLE compania (
    id_empresa NUMBER NOT NULL,
    nombre_empresa VARCHAR2(100) NOT NULL,
    direccion VARCHAR2(200) NOT NULL,
    renta_promedio NUMBER NOT NULL,
    porc_aumento NUMBER(5,2),
    id_comuna NUMBER NOT NULL,
    CONSTRAINT pk_compania PRIMARY KEY (id_empresa),
    CONSTRAINT fk_compania_comuna FOREIGN KEY (id_comuna) REFERENCES comuna(id_comuna)
);

-- Tabla Personal
CREATE TABLE personal (
    run_personal NUMBER(8) NOT NULL,
    dv_personal CHAR(1) NOT NULL,
    nombre VARCHAR2(50) NOT NULL,
    apellido_paterno VARCHAR2(50) NOT NULL,
    apellido_materno VARCHAR2(50),
    email VARCHAR2(100),
    sueldo_base NUMBER NOT NULL,
    id_empresa NUMBER NOT NULL,
    CONSTRAINT pk_personal PRIMARY KEY (run_personal),
    CONSTRAINT fk_personal_empresa FOREIGN KEY (id_empresa) REFERENCES compania(id_empresa)
);

-- ========================================================================
-- CASO 2: MODIFICACIONES DEL MODELO (ALTER TABLE)
-- ========================================================================
-- Se incorporan reglas de negocio adicionales solicitadas.

-- Email debe ser único aunque sea opcional
ALTER TABLE personal ADD CONSTRAINT un_personal_email UNIQUE (email);

-- Restricción de Dígito Verificador (0-9 y K)
ALTER TABLE personal ADD CONSTRAINT ck_personal_dv 
    CHECK (UPPER(dv_personal) IN ('0','1','2','3','4','5','6','7','8','9','K'));

-- Sueldo mínimo del personal establecido en 450.000 pesos
ALTER TABLE personal ADD CONSTRAINT ck_personal_sueldo_min 
    CHECK (sueldo_base >= 450000);

-- ========================================================================
-- CASO 3: POBLAMIENTO Y SECUENCIAS
-- ========================================================================
-- Uso de objetos SEQUENCE para tablas específicas.

-- Secuencia Comuna: Inicio 1101, Incremento 6
CREATE SEQUENCE seq_comuna START WITH 1101 INCREMENT BY 6;

-- Secuencia Compañía: Inicio 10, Incremento 5
CREATE SEQUENCE seq_compania START WITH 10 INCREMENT BY 5;

-- Poblar Regiones
INSERT INTO region (nombre_region) VALUES ('Metropolitana');
INSERT INTO region (nombre_region) VALUES ('Valparaíso');
INSERT INTO region (nombre_region) VALUES ('Biobío');

-- Poblar Comunas usando .NEXTVAL de la secuencia
INSERT INTO comuna (id_comuna, nombre_comuna, id_region) VALUES (seq_comuna.NEXTVAL, 'Santiago', 7);
INSERT INTO comuna (id_comuna, nombre_comuna, id_region) VALUES (seq_comuna.NEXTVAL, 'Viña del Mar', 9);
INSERT INTO comuna (id_comuna, nombre_comuna, id_region) VALUES (seq_comuna.NEXTVAL, 'Concepción', 11);

-- Poblar Compañías usando .NEXTVAL de la secuencia
INSERT INTO compania (id_empresa, nombre_empresa, direccion, renta_promedio, porc_aumento, id_comuna)
VALUES (seq_compania.NEXTVAL, 'Carpenter Retail Central', 'Alameda 1010', 820000, 5, 1101);

INSERT INTO compania (id_empresa, nombre_empresa, direccion, renta_promedio, porc_aumento, id_comuna)
VALUES (seq_compania.NEXTVAL, 'Carpenter Logística Sur', 'Av. Prat 555', 750000, 7, 1107);

INSERT INTO compania (id_empresa, nombre_empresa, direccion, renta_promedio, porc_aumento, id_comuna)
VALUES (seq_compania.NEXTVAL, 'Carpenter Tech', 'Libertad 12', 950000, 10, 1113);

COMMIT;

-- ========================================================================
-- CASO 4: RECUPERACIÓN DE DATOS (REPORTES)
-- ========================================================================
-- Generación de informes mediante sentencias SELECT con operadores matemáticos.

-- INFORME 1: Simulación de Renta Promedio
-- Ordenado por Renta Promedio Descendente y Nombre Empresa Ascendente.
SELECT 
    nombre_empresa AS "Nombre Empresa",
    direccion AS "Dirección",
    renta_promedio AS "Renta Promedio",
    (renta_promedio * (1 + porc_aumento/100)) AS "Renta Promedio Aumentada"
FROM compania
ORDER BY "Renta Promedio" DESC, "Nombre Empresa" ASC;

-- INFORME 2: Nueva Simulación (+15% adicional)
-- Ordenado por Renta Promedio Actual Ascendente y Nombre Empresa Descendente.
SELECT 
    id_empresa AS "ID Empresa",
    nombre_empresa AS "Nombre Empresa",
    renta_promedio AS "Renta Promedio Actual",
    (porc_aumento + 15) || '%' AS "% Aumentado en 15%",
    (renta_promedio * (1 + (porc_aumento + 15)/100)) AS "Renta Promedio Incrementada"
FROM compania
ORDER BY "Renta Promedio Actual" ASC, "Nombre Empresa" DESC;