DROP TABLESPACE BET_ITM INCLUDING CONTENTS AND DATAFILES 

ALTER SESSION SET "_ORACLE_SCRIPT" = TRUE; 

CREATE SMALLFILE TABLESPACE BET_ITM
DATAFILE 'SMALL_TALLER_BET_ITM' SIZE 512 M,
'TALLER_BET_ITM' SIZE 512 M;


CREATE BIGFILE TABLESPACE BET_AUDITING
DATAFILE 'BIG_AUDITING.DBF' SIZE 2G;


CREATE UNDO TABLESPACE UNDOBET
DATAFILE 'UNDO_FILE_BET.DBF'
SIZE 500 M
AUTOEXTEND ON;

CREATE PROFILE DEVELOPER LIMIT  
    PASSWORD_LIFE_TIME 90
    CONNECT_TIME 60
    SESSIONS_PER_USER 1 
    IDLE_TIME 30 
    FAILED_LOGIN_ATTEMPTS 5;   
    
    
CREATE PROFILE WEB_APPLICATION LIMIT  
    PASSWORD_LIFE_TIME 30
    CONNECT_TIME UNLIMITED 
    SESSIONS_PER_USER 5
    IDLE_TIME UNLIMITED  
    FAILED_LOGIN_ATTEMPTS 2;   
    
    
    
ALTER PROFILE DBA_ADMIN LIMIT  
    SESSIONS_PER_USER 2
    CONNECT_TIME UNLIMITED 
    IDLE_TIME UNLIMITED  
    FAILED_LOGIN_ATTEMPTS 2
    PASSWORD_LIFE_TIME 30;   
    
    
CREATE PROFILE ANALYST LIMIT  
    SESSIONS_PER_USER 1
    CONNECT_TIME 30 
    IDLE_TIME 5  
    FAILED_LOGIN_ATTEMPTS 3
    PASSWORD_LIFE_TIME 30
    PASSWORD_GRACE_TIME 3;
    
    
CREATE PROFILE SUPPORT_III LIMIT  
    SESSIONS_PER_USER 1
    CONNECT_TIME 240 
    IDLE_TIME 5  
    FAILED_LOGIN_ATTEMPTS 3
    PASSWORD_LIFE_TIME 20
    PASSWORD_GRACE_TIME 3;
    
    
CREATE PROFILE REPORTER LIMIT  
    SESSIONS_PER_USER 1
    CONNECT_TIME 90 
    IDLE_TIME 15  
    FAILED_LOGIN_ATTEMPTS 4
    PASSWORD_LIFE_TIME UNLIMITED 
    PASSWORD_GRACE_TIME 5;
    
  
CREATE PROFILE AUDITOR LIMIT  
    SESSIONS_PER_USER 1
    CONNECT_TIME 90 
    IDLE_TIME 15  
    FAILED_LOGIN_ATTEMPTS 4
    PASSWORD_LIFE_TIME UNLIMITED 
    PASSWORD_GRACE_TIME 5;
    
    
  CREATE USER DEV_YONERIC
    IDENTIFIED BY yoneric
    PROFILE DEVELOPER;
    
  CREATE USER WEB_RONALD
    IDENTIFIED BY ronald
    PROFILE WEB_APPLICATION;
    
  
    CREATE USER DBA_JULIAN
    IDENTIFIED BY julian
    PROFILE DBA_ADMIN;
    
    
    CREATE USER ANLY_EDISSON
    IDENTIFIED BY edisson
    PROFILE ANALYST;
    
    CREATE USER SP3_KATE
    IDENTIFIED BY kate
    PROFILE SUPPORT_III;
    
    CREATE USER RPT_BRIAN
    IDENTIFIED BY brian
    PROFILE REPORTER;
    
    
    CREATE USER AUD_SANTIAGO
    IDENTIFIED BY santiago
    PROFILE AUDITOR;

    
   CREATE USER DEV_SERGIO
    IDENTIFIED sergio
    PROFILE DEVELOPER;
    
    
   CREATE USER DBA_ANDRES
    IDENTIFIED BY andres
    PROFILE DBA_ADMIN;
    
    
   CREATE USER WEB_MACARENA
    IDENTIFIED BY macarena
    PROFILE WEB_APPLICATION;
    

 
CREATE TABLE USUARIOS (
   ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL, 
   DOCUMENTO NUMERIC NOT NULL,
   TIPO_DOCUMENTO VARCHAR2 (255) NOT NULL,
   LUGAR_EXPEDICION VARCHAR2(255)NOT NULL ,
   FECHA_EXPEDICION DATE NOT NULL,
   NACIONALIDAD VARCHAR2 (255) NOT NULL,
   PRIMER_NOMBRE VARCHAR2(255) NOT NULL,
   SEGUNDO_NOMBRE VARCHAR2 (255),
   PRIMER_APELLIDO VARCHAR2 (255) NOT NULL,
   SEGUNDO_APELLIDO VARCHAR2 (255),
   FECHA_DE_NACIMIENTO DATE,
   LUGAR_NACIMIENTO VARCHAR2 (255) NOT NULL,
   DICRECCION VARCHAR2 (255) NOT NULL,
   DIRECCION2 VARCHAR (255),
   CONTRASENA VARCHAR2 (255) NOT NULL,
   EMAIL VARCHAR2 (255) NOT NULL,
   IDIOMA_EMAIL VARCHAR2 (255) NOT NULL,
   CELULAR NUMERIC,
   TERMINOS NUMERIC NOT NULL CHECK (TERMINOS IN (0,1)),
   RECIBIR_INFO NUMERIC NOT NULL CHECK (RECIBIR_INFO IN (0,1)), 
   TITULO VARCHAR2 (20) NOT NULL,
   RUTA_DOCUMENTOS VARCHAR2 (255),
   SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1)),
   SALDO NUMERIC NOT NULL,
   HORAS_SESION NUMERIC,
   ID_MUNICIPIO NUMERIC NOT NULL,
   ID_PREFIJO NUMERIC NOT NULL
 )
 TABLESPACE BET_ITM;

 CREATE TABLE PAISES (
   ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL, 
   PAIS VARCHAR2(255),
   SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
 )
 TABLESPACE BET_ITM;
 
 CREATE TABLE MUNICIPIOS(
   ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
   MUNICIPIO VARCHAR2(255),
   ID_DEPARTAMENTO NUMERIC NOT NULL,
   COD_POSTAL VARCHAR2(60),
   SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
 )
 TABLESPACE BET_ITM;
 
 
 CREATE TABLE PREFIJOS(
   ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
   PREFIJO VARCHAR2 (50) NULL,
   SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
 )
 TABLESPACE BET_ITM;
 
 
 CREATE TABLE DEPARTAMENTOS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  DEPARTAMENTO VARCHAR (255) NOT NULL,
  ID_PAIS NUMERIC NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;

CREATE TABLE LIMITES(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  LIMITE_DIA NUMERIC CHECK(LIMITE_DIA >0),
  LIMITE_SEMANA NUMERIC CHECK(LIMITE_SEMANA >0),
  LIMITE_MES NUMERIC CHECK(LIMITE_MES >0),
  FECHA_MODIFICACION TIMESTAMP,
  ID_USUARIO NUMERIC NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;


CREATE TABLE BONOS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  CODIGO_BONO VARCHAR2(50),
  FECHA_INICIO DATE,
  FECHA_FIN DATE,
  ID_USUARIO NUMERIC NOT NULL,
   SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;


CREATE TABLE APUESTAS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  ID_USUARIO NUMERIC NOT NULL,
  VALOR_TOTAL NUMERIC NOT NULL,
  TOTAL_GANANCIAS NUMERIC NOT NULL,
  FECHA DATE,
  ID_ESTADO NUMERIC,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;


CREATE TABLE PARTIDOS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  ID_LOCAL NUMERIC NOT NULL,
  ID_VISITANTE NUMERIC NOT NULL,
  GOLES_L_PT NUMERIC NOT NULL,
  GOLES_V_PT NUMERIC NOT NULL,
  TOTAL_GOLES_L NUMERIC NOT NULL,
  TOTAL_GOLES_V NUMERIC NOT NULL,
  TOTAL_GOLES_PARTIDO NUMERIC NOT NULL,
  ID_GANADOR_PT NUMERIC,
  ID_GANADOR_ST NUMERIC,
  ESTADO VARCHAR2 (255) NOT NULL,
  FECHA DATE,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;


CREATE TABLE EQUIPOS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  EQUIPO VARCHAR(255) NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;

CREATE TABLE DETALLES_APUESTAS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  OPCION_CUOTA VARCHAR2 (255) NOT NULL,
  CUOTA_GANADORA VARCHAR2 (255),
  ESTADO VARCHAR2 (255),
  VALOR_APOSTADO NUMERIC NOT NULL CHECK(VALOR_APOSTADO >=1),
  ID_APUESTA NUMERIC NOT NULL,
  ID_CUOTA NUMERIC NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;

CREATE TABLE CUOTAS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  OPCION1 VARCHAR2 (255),
  OPCION2 VARCHAR2 (255),
  OPCION3 VARCHAR2 (255),
  CUOTA_GANADORA VARCHAR2 (255),
  ESTADO VARCHAR2(255),
  ID_CATEGORIA NUMERIC NOT NULL,
  ID_PARTIDO NUMERIC NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;

CREATE TABLE CATEGORIAS (
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  NOMBRE VARCHAR2(255) NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;

CREATE TABLE PREFERENCIAS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  PREFERENCIA VARCHAR2 (255)NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;


CREATE TABLE PREFERENCIAS_DE_USUARIOS(
  ID_USUARIO NUMERIC  NOT NULL,
  ID_PREFERENCIA NUMERIC  NOT NULL,
  PRIMARY KEY ( ID_USUARIO,ID_PREFERENCIA),
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;

CREATE TABLE ESTADOS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  ESTADO VARCHAR2(255) NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;

CREATE TABLE RETIROS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  VALOR_RETIRO NUMERIC NOT NULL,
  FECHA_SOLICITUD TIMESTAMP NOT NULL,
  FECHA_DESEMBOLSO TIMESTAMP,
  BANCO VARCHAR2(255),
  CUENTA_BANCARIA VARCHAR2(255),
  REQUISITO NUMERIC CHECK (REQUISITO IN (0,1)) NOT NULL,
  ESTADO VARCHAR2 (255) NOT NULL ,
  ID_USUARIO NUMERIC NOT NULL,
  ID_COMPROBANTE NUMERIC NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1)),
  OBSERVACIONES VARCHAR2 (500),
  ESTADO VARCHAR2 (255)
  
)
TABLESPACE BET_ITM;

CREATE TABLE DEPOSITOS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  VALOR NUMERIC NOT NULL,
  FECHA TIMESTAMP NOT NULL,
  ID_USUARIO NUMERIC NOT NULL,
  ID_ESTADO NUMERIC NOT NULL,
  ID_MEDIO_DE_PAGO NUMERIC NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;


CREATE TABLE ESTADOS_DEPOSITOS(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  ESTADO VARCHAR2 (255) NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;


CREATE TABLE MEDIOS_DE_PAGO(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  MEDIO_DE_PAGO VARCHAR2(255) NOT NULL,
  VALOR_MINIMO NUMERIC NOT NULL,
  VALOR_MAXIMO NUMERIC NOT NULL,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;

CREATE TABLE COMPROBANTES(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  FACTURA_SERVICIOS VARCHAR2(255) ,
  TAMANO_FACTURA_SERVICIOS VARCHAR2(255) ,
  EXTENSION_FACTURA_SERVICIOS VARCHAR2(255) ,
  COMPROBANTE_DEPOSITO VARCHAR2(255) ,
  TAMANO_COMPROBANTE_DEPOSITO VARCHAR2(255) ,
  EXTENSION_COMPROBANTE_DEPOSITO VARCHAR2(255),
  IDENTIFICACION VARCHAR2(255) ,
  TAMANO_IDENTIFICACION VARCHAR2(255),
  EXTENSION_IDENTIFICACION VARCHAR2(255),
  FOTO_PERSONAL VARCHAR2(255) ,
  TAMANO_FOTO_PERSONAL VARCHAR2(255),
  EXTENSION_FOTO_PERSONAL VARCHAR2(255) ,
  SOFT_DELETION NUMERIC NOT NULL CHECK (SOFT_DELETION IN (0,1))
)
TABLESPACE BET_ITM;

CREATE TABLE SESIONES(
   ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
   INICIO_SESION TIMESTAMP NOT NULL,
   FIN_SESION TIMESTAMP,
   HORAS_SESION TIMESTAMP,
   ESTADO_CONEXION NUMERIC,
   ID_USUARIO NUMERIC NOT NULL
)
TABLESPACE BET_ITM;

DROP TABLE LOGIN

CREATE TABLE AUDITORIA(
  ID NUMERIC GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
  DATE_AND_TIME TIMESTAMP NOT NULL,
  TABLA VARCHAR2(255),
  RECORD_ID NUMERIC NOT NULL,
  ACTION VARCHAR2 (255)  NOT NULL,
  USUARIO VARCHAR2 (255)  NOT NULL,
  IP VARCHAR2 (20)
)
TABLESPACE BET_AUDITING;


ALTER TABLE LIMITES
ADD CONSTRAINT FK_USUARIO_LIMITE
   FOREIGN KEY (ID_USUARIO)
   REFERENCES USUARIOS(ID);

ALTER TABLE BONOS
ADD CONSTRAINT FK_USUARIO_BONO
   FOREIGN KEY (ID_USUARIO)
   REFERENCES USUARIOS(ID);
   
   
 ALTER TABLE APUESTAS
ADD CONSTRAINT FK_USUARIO
   FOREIGN KEY (ID_USUARIO)
   REFERENCES USUARIOS(ID);
   
  ALTER TABLE USUARIOS
ADD CONSTRAINT FK_PREFIJO
   FOREIGN KEY (ID_PREFIJO)
   REFERENCES PREFIJOS(ID);
   
  ALTER TABLE USUARIOS
ADD CONSTRAINT FK_MUNICIPIOS
   FOREIGN KEY (ID_MUNICIPIO)
   REFERENCES MUNICIPIOS(ID);
   
   
   ALTER TABLE MUNICIPIOS
ADD CONSTRAINT FK_DEPARTAMENTO
   FOREIGN KEY (ID_DEPARTAMENTO)
   REFERENCES DEPARTAMENTOS(ID);

ALTER TABLE DEPARTAMENTOS
ADD CONSTRAINT FK_PAIS
   FOREIGN KEY (ID_PAIS)
   REFERENCES PAISES(ID);
   
   ALTER TABLE DETALLES_APUESTAS
ADD CONSTRAINT FK_APUESTA
   FOREIGN KEY (ID_APUESTA)
   REFERENCES APUESTAS(ID);
   
   ALTER TABLE APUESTAS
ADD CONSTRAINT FK_ESTADO
   FOREIGN KEY (ID_ESTADO)
   REFERENCES ESTADOS(ID);
   
   ALTER TABLE PARTIDOS
ADD CONSTRAINT FK_EQUIPO_L
   FOREIGN KEY (ID_LOCAL)
   REFERENCES EQUIPOS(ID);


   ALTER TABLE PARTIDOS
ADD CONSTRAINT FK_EQUIPO_V
   FOREIGN KEY (ID_VISITANTE)
   REFERENCES EQUIPOS(ID);

   ALTER TABLE PARTIDOS
ADD CONSTRAINT FK_EQUIPO_GANADOR_PT
   FOREIGN KEY (ID_GANADOR_PT)
   REFERENCES EQUIPOS(ID);
   
   ALTER TABLE PARTIDOS
ADD CONSTRAINT FK_EQUIPO_GANADOR_ST
   FOREIGN KEY (ID_GANADOR_ST)
   REFERENCES EQUIPOS(ID);
   
   
ALTER TABLE DETALLES_APUESTAS
ADD CONSTRAINT FK_CUOTAS
   FOREIGN KEY (ID_CUOTA)
   REFERENCES CUOTAS(ID);
   
   ALTER TABLE CUOTAS
   ADD CONSTRAINT FK_PARTIDOS
   FOREIGN KEY (ID_PARTIDO)
   REFERENCES PARTIDOS(ID);
   
    ALTER TABLE CUOTAS
   ADD CONSTRAINT FK_CATEGORIA
   FOREIGN KEY (ID_CATEGORIA)
   REFERENCES CATEGORIAS(ID);


  ALTER TABLE PREFERENCIAS_DE_USUARIOS
ADD CONSTRAINT FK_PREFEREMCIAS_USUARIOS
   FOREIGN KEY (ID_USUARIO)
   REFERENCES USUARIOS(ID);


  ALTER TABLE PREFERENCIAS_DE_USUARIOS
ADD CONSTRAINT FK_PREFEREMCIAS
   FOREIGN KEY (ID_PREFERENCIA)
   REFERENCES PREFERENCIAS(ID);

   
   ALTER TABLE RETIROS
ADD CONSTRAINT FK_USUARIOS
   FOREIGN KEY (ID_USUARIO)
   REFERENCES USUARIOS(ID);
   
   ALTER TABLE RETIROS
ADD CONSTRAINT FK_COMPROBANTES
   FOREIGN KEY (ID_COMPROBANTE)
   REFERENCES COMPROBANTES(ID);
   
   ALTER TABLE DEPOSITOS
ADD CONSTRAINT FK_USUARIOS_DEPOSITOS
   FOREIGN KEY (ID_USUARIO)
   REFERENCES USUARIOS(ID);
   
   
ALTER TABLE DEPOSITOS
ADD CONSTRAINT FK_ESTADOS_DEPOSITOS
   FOREIGN KEY (ID_ESTADO)
   REFERENCES ESTADOS_DEPOSITOS(ID);


ALTER TABLE DEPOSITOS
ADD CONSTRAINT FK_MEDIOS_DE_PAGO
   FOREIGN KEY (ID_MEDIO_DE_PAGO)
   REFERENCES MEDIOS_DE_PAGO(ID);
   
ALTER TABLE SESIONES
  ADD CONSTRAINT FK_USUARIOS_SESION
  FOREIGN KEY (ID_USUARIO)
  REFERENCES USUARIOS(ID);
  
  
  
  

  