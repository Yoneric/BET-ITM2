-- PUNTO 1 VISTAS

/* 
A.  Sumar el valor ganado de todas las apuestas de los usuarios que est�n 
en estado ganado de aquellos partidos asociados a las apuestas 
que se efectuaron en el trancurso de la semana y mostrarlas ordenadas por el valor m�s alto; 
El nombre de la vista ser� "GANADORES_SEMANALES" y tendr� dos columnas: nombre completo y valor acumulado.
*/

CREATE OR REPLACE VIEW GANADORES_SEMANALES AS
  SELECT us.primer_nombre ||' ' ||US.SEGUNDO_NOMBRE||' ' ||us.primer_apellido ||' '|| US.SEGUNDO_APELLIDO  "NOMBRE COMPLETO", sum(ap.total_ganancias)"TOTAL GANANCIAS" 
  FROM usuarios us INNER JOIN apuestas ap
  ON ap.id_usuario = us.id
  WHERE AP.FECHA BETWEEN (SELECT trunc(sysdate, 'DAY') FROM DUAL) AND (SELECT trunc(sysdate, 'DAY')+6 FROM dual)
  GROUP BY us.primer_nombre,SEGUNDO_NOMBRE, us.primer_apellido,SEGUNDO_APELLIDO;

SELECT * FROM GANADORES_SEMANALES


/* 
B.  Nombre de la vista: DETALLES_APUESTAS. Esta vista deber� mostrar todos 
los detalles de apuestas simples que se efectuaron para un boleto en particular.
*/

CREATE OR REPLACE VIEW DETALLE_APUESTAS AS 
  SELECT  E.EQUIPO ||' VS '|| E2.EQUIPO "PARTIDO", DAP.OPCION_CUOTA, C.CUOTA_GANADORA,CA.NOMBRE "CATEGOR�A", AP.ID "APUESTA"
  FROM   PARTIDOS P  
  INNER JOIN  EQUIPOS E  
  ON E.ID = P.ID_LOCAL 
  INNER JOIN EQUIPOS E2 
  ON E2.ID = P.ID_VISITANTE 
  INNER JOIN CUOTAS C
  ON P.ID = C.ID_PARTIDO 
  INNER JOIN CATEGORIAS CA
  ON CA.ID = C.ID_CATEGORIA
  INNER JOIN DETALLES_APUESTAS DAP
  ON C.ID = DAP.ID_CUOTA
  INNER JOIN APUESTAS AP
  ON AP.ID = DAP.ID_APUESTA

SELECT * FROM DETALLE_APUESTAS WHERE APUESTA = 1001


/* 
C.  Nombre de la vista: RESUMEN_APUESTAS. Esta vista mostrar� el resumen de 
cada apuesta efectuada en el sistema. La idea es que cuando se llame la vista, 
muestre la informaci�n �nicamente de esa apuesta en particular: 
SELECT * FROM RESUMEN_APUESTAS WHERE APUESTAS.ID = 123. 
*/

CREATE OR REPLACE VIEW RESUMEN_APUESTAS AS
  SELECT AP.ID "APUESTA" ,COUNT(*) "N�MERO DE APUESTAS",COUNT(*)||' x $'|| DAP.VALOR_APOSTADO || ' = $' || SUM(DAP.VALOR_APOSTADO) "VALOR TOTAL APUESTA",MAX (OPCION_CUOTA)  "MAX. TOTAL CUOTA"
  FROM  DETALLES_APUESTAS DAP
  INNER JOIN APUESTAS AP
  ON AP.ID = DAP.ID_APUESTA
  GROUP BY DAP.VALOR_APOSTADO,AP.ID

SELECT * FROM RESUMEN_APUESTAS WHERE APUESTA = 1001

/*
D.  Para la siguiente vista deber�n alterar el manejo de sesiones de usuario, 
el sistema deber� guardar el timestamp de la hora de sesi�n 
y el timestamp del fin de sesi�n, si el usuario tiene el campo fin de sesi�n en null, 
significa que la sesi�n est� activa. 
Crear una vista que traiga las personas que tienen una sesi�n activa, ordenado por la hora de inicio de sesi�n, 
mostrando las personas que m�s tiempo llevan activas; adicional, deber� tener una columna que calcule 
cu�ntas horas lleva en el sistema con respecto a la hora actual, 
la siguiente columna ser� la cantidad de horas seleccionada 
en las preferencias de usuario, finalmente, habr� una columna 
que reste cu�nto tiempo le falta para que se cierre la sesi�n 
(si aparece un valor negativo, significa que el usuario excedi� el tiempo en el sistema)
*/


CREATE OR REPLACE FUNCTION DIFERENCIA_HORAS(HORA_1 TIMESTAMP, HORA_2 TIMESTAMP) RETURN NUMBER as
  dias integer;
  horas integer;
  tiempo_transcurrido INTERVAL DAY TO SECOND;
  total_diferencia integer;
BEGIN
  tiempo_transcurrido := hora_2 - hora_1;
  dias := EXTRACT(day from tiempo_transcurrido);
  horas := EXTRACT(hour from tiempo_transcurrido); 
  
  total_diferencia := abs(dias*24 + horas);
  
  RETURN total_diferencia;
END;


SELECT DIFERENCIA_HORAS(current_timestamp, TO_TIMESTAMP('11/5/2019 15:10:35.000', 'MM/DD/YYYY HH24:MI:SS.FF')) from dual;

select id, login_at, diferencia_horas(current_timestamp, login_at) as diferencia from usuarios2;

declare
  hora_2 TIMESTAMP := TO_TIMESTAMP('11/5/2019 15:10:35.000', 'MM/DD/YYYY HH24:MI:SS.FF');
  resultado number := 0;
begin
  resultado := diferencia_horas(current_timestamp, hora_2);
  dbms_output.put_line('La diferencia de horas es: '||resultado);
end;


DECLARE
  id usuarios.id%TYPE;
  first_name usuarios.first_name%TYPE;
  last_name usuarios.last_name%TYPE;
  login_at usuarios.login_at%TYPE;
  cerrar_sesion usuarios.cerrar_sesion%TYPE;
  resultado VARCHAR2(255);
  CURSOR c_usuarios IS select id, first_name, last_name, login_at, cerrar_sesion from usuarios2;
BEGIN
  OPEN c_usuarios;
    LOOP
      FETCH c_usuarios INTO id, first_name, last_name, login_at, cerrar_sesion;
      
      IF DIFERENCIA_HORAS(CURRENT_TIMESTAMP, login_at) > cerrar_sesion THEN
        RESULTADO := 'TIEMPO EXPIRADO.';
      ELSE
        RESULTADO := 'PUEDE SEGUIR LOGUEADO.';
      END IF;
      
      dbms_output.put_line('id: ' || id || '. Diferencia horas: '|| DIFERENCIA_HORAS(CURRENT_TIMESTAMP, login_at) || ' ' ||RESULTADO);
      EXIT WHEN c_usuarios%notfound;
    END LOOP;
  CLOSE c_usuarios;
END;




-- TRIGGERS
/* 
A.  Crear un trigger para TODAS las tablas que tienen creadas, 
el trigger deber� llenar la informaci�n de la tabla de auditor�a 
cuando se produce una INSERCI�N, ACTUALIZACI�N y ELIMINACI�N de registros 
(Recordar que estamos trabajando con SOFT deletion y 
por ende ning�n usuario deber�a tener el privilegio de ELIMINAR registros). 
Para obtener la IP desde donde se produce la conexi�n.
*/
  
CREATE OR REPLACE TRIGGER AUDITORIA_USUARIOS
  AFTER INSERT OR UPDATE
  ON USUARIOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'USUARIOS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'USUARIOS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;
 
UPDATE USUARIOS SET SALDO = 1500000 WHERE ID  = 1008

  
CREATE OR REPLACE TRIGGER AUDITORIA_PARTIDOS
  AFTER INSERT OR UPDATE
  ON PARTIDOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'PARTIDOS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'PARTIDOS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_PAISES
  AFTER INSERT OR UPDATE
  ON PAISES
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'PAISES',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'PAISES',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_MUNICIPIOS
  AFTER INSERT OR UPDATE
  ON MUNICIPIOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'MUNICIPIOS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'MUNICIPIOS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_PREFIJOS
  AFTER INSERT OR UPDATE
  ON PREFIJOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'PREFIJOS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'PREFIJOS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_DEPARTAMENTOS
  AFTER INSERT OR UPDATE
  ON DEPARTAMENTOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'DEPARTAMENTOS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'DEPARTAMENTOS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_LIMITES
  AFTER INSERT OR UPDATE
  ON LIMITES
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'LIMITES',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'LIMITES',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_BONOS
  AFTER INSERT OR UPDATE
  ON BONOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'BONOS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'BONOS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_APUESTAS
  AFTER INSERT OR UPDATE
  ON APUESTAS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'APUESTAS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'APUESTAS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_EQUIPOS
  AFTER INSERT OR UPDATE
  ON EQUIPOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'EQUIPOS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'EQUIPOS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_DETALLES_APUESTAS
  AFTER INSERT OR UPDATE
  ON DETALLES_APUESTAS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'DETALLES_APUESTAS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'DETALLES_APUESTAS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_CUOTAS
  AFTER INSERT OR UPDATE
  ON CUOTAS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'CUOTAS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'CUOTAS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_CATEGORIAS
  AFTER INSERT OR UPDATE
  ON CATEGORIAS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'CATEGORIAS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'CATEGORIAS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_PREFERENCIAS_DE_USUARIOS
  AFTER INSERT OR UPDATE
  ON PREFERENCIAS_DE_USUARIOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'PREFERENCIAS_DE_USUARIOS',:new.ID_USUARIO ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'PREFERENCIAS_DE_USUARIOS',:old.ID_USUARIO ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;
 
 CREATE OR REPLACE TRIGGER AUDITORIA_ESTADOS
  AFTER INSERT OR UPDATE
  ON ESTADOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'ESTADOS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'ESTADOS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_RETIROS
  AFTER INSERT OR UPDATE
  ON RETIROS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'RETIROS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'RETIROS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_DEPOSITOS
  AFTER INSERT OR UPDATE
  ON DEPOSITOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'DEPOSITOS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'DEPOSITOS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_ESTADOS_DEPOSITOS
  AFTER INSERT OR UPDATE
  ON ESTADOS_DEPOSITOS
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'ESTADOS_DEPOSITOS',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'ESTADOS_DEPOSITOS',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_MEDIOS_DE_PAGO
  AFTER INSERT OR UPDATE
  ON MEDIOS_DE_PAGO
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'MEDIOS_DE_PAGO',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'MEDIOS_DE_PAGO',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_COMPROBANTES
  AFTER INSERT OR UPDATE
  ON COMPROBANTES
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'COMPROBANTES',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'COMPROBANTES',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;

 CREATE OR REPLACE TRIGGER AUDITORIA_SESIONES
  AFTER INSERT OR UPDATE
  ON SESIONES
  FOR EACH ROW

DECLARE
 
   USUARIO VARCHAR2(255);
   IP VARCHAR2(255);
   FECHA TIMESTAMP;
   
BEGIN

    SELECT USER INTO USUARIO FROM DUAL;
    SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') INTO IP FROM dual;
    SELECT current_timestamp INTO FECHA FROM dual;
    
  IF INSERTING THEN
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'SESIONES',:new.ID ,'INSERTADO',USUARIO, IP);
 END IF;
 
  IF UPDATING THEN 
    INSERT INTO  AUDITORIA (DATE_AND_TIME,TABLA, RECORD_ID, ACTION, USUARIO, IP) VALUES(
    FECHA, 'SESIONES',:old.ID ,'ACTUALIZADO',USUARIO, IP);

  END IF;

 END;
 
 
 /*
 B. Crear un(os) trigger(s) que permita(n) mantener el saldo del usuario ACTUALIZADO, 
 es decir, si se produce un retiro, una recarga, una apuesta o hay ganancias de una apuesta, 
 autom�ticamente deber� actualizar el saldo disponible del usuario.
 */
 

 CREATE OR REPLACE TRIGGER SALDO_APUESTAS
 BEFORE  INSERT
 ON APUESTAS
 FOR EACH ROW
 
 BEGIN 
   UPDATE USUARIOS SET SALDO = SALDO +( SELECT :new.TOTAL_GANANCIAS - :new.VALOR_TOTAL FROM (SELECT * FROM APUESTAS  ORDER BY (ID) DESC) WHERE  ROWNUM = 1) WHERE USUARIOS.ID = :new.id_usuario;
     --UPDATE USUARIOS SET SALDO = SALDO +( SELECT :new.TOTAL_GANANCIAS - :new.VALOR_TOTAL FROM  APUESTAS  WHERE ID = :new.ID ) WHERE USUARIOS.ID = :new.id_usuario; 
 END;
 
 
 
CREATE OR REPLACE TRIGGER SALDO_RETIROS
 BEFORE  INSERT
 ON RETIROS
 FOR EACH ROW
 
 BEGIN 
  UPDATE USUARIOS SET SALDO = SALDO - :new.VALOR_RETIRO WHERE USUARIOS.ID = :new.id_usuario;
 END;


CREATE OR REPLACE TRIGGER SALDO_DEPOSITOS
 BEFORE  INSERT
 ON DEPOSITOS
 FOR EACH ROW
 
 BEGIN 
  UPDATE USUARIOS SET SALDO = SALDO + :new.VALOR WHERE USUARIOS.ID = :new.id_usuario;
 END;

 
select * from retiros;
select * from depositos;
select saldo from usuarios where id  = 984;

 
Insert into DBA_JULIAN.APUESTAS (ID_USUARIO,VALOR_TOTAL,TOTAL_GANANCIAS,FECHA,ID_ESTADO,SOFT_DELETION) 
values (1008,'0','0',to_date('18/07/19','DD/MM/RR'),'3','1');

 
Insert into DBA_JULIAN.RETIROS (VALOR_RETIRO,FECHA_SOLICITUD,FECHA_DESEMBOLSO,BANCO,CUENTA_BANCARIA,REQUISITO,ID_USUARIO,ID_COMPROBANTE,SOFT_DELETION)
values (100000,to_timestamp('06/06/08 18:30:34,000000000','DD/MM/RR HH24:MI:SSXFF'),to_timestamp('07/06/08 18:30:34,000000000','DD/MM/RR HH24:MI:SSXFF'),'BANCOLOMBIA','56487764532','1','984','1','1');
 

Insert into DBA_JULIAN.DEPOSITOS (VALOR,FECHA,ID_USUARIO,ID_ESTADO,ID_MEDIO_DE_PAGO,SOFT_DELETION) 
values ('500000',to_timestamp('05/02/08 18:12:54,000000000','DD/MM/RR HH24:MI:SSXFF'),'984','4','1','1');
 

/*
C. Crear un trigger asociado a la tabla PARTIDOS, este trigger se disparar� solamente cuando 
el partido pase a estado "FINALIZADO". El prop�sito de este trigger es ejecutar el o 
los procedimientos hechos para liquidar las ganancias y p�rdidas de los usuarios 
que apostaron a ese partido.
*/

CREATE OR REPLACE TRIGGER ACTUALIZA_PARTIDOS
BEFORE UPDATE 
OF ESTADO 
ON PARTIDOS
FOR EACH ROW
 
DECLARE 
  
  V_ESTADO VARCHAR2(100);
  
BEGIN
  
  SELECT ESTADO INTO V_ESTADO FROM PARTIDOS  WHERE ID = :new.ID;
  
  IF V_ESTADO = 'FINALIZADO' THEN
  
   DBMS_OUTPUT.put_line ('Llama procedure');
   
  ELSE 
  
   DBMS_OUTPUT.put_line ('No hace nada ');
   
  END IF;
END; 


UPDATE PARTIDOS SET ESTADO = 'FINALIZADO' WHERE ID = 31;
SELECT ESTADO FROM PARTIDOS WHERE ID = 31;

/*
D. Crear un trigger asociado a la tabla DETALLES_APUESTAS, este trigger mantendr� actualizado el 
campo "valor_total" de la tabla APUESTAS
*/


CREATE OR REPLACE TRIGGER ACTUALIZA_VALOR_APUESTA
BEFORE  INSERT
ON DETALLES_APUESTAS
FOR EACH ROW

DECLARE 
 
  CONTADOR NUMBER;
 
BEGIN 

  SELECT COUNT(*) INTO CONTADOR FROM DETALLES_APUESTAS WHERE ID_APUESTA = :new.ID_APUESTA;

  IF CONTADOR = 0 THEN 

    UPDATE APUESTAS SET VALOR_TOTAL = :new.VALOR_APOSTADO WHERE ID = :new.ID_APUESTA;

  ELSE  

    UPDATE APUESTAS SET VALOR_TOTAL = ((SELECT SUM(VALOR_APOSTADO) FROM DETALLES_APUESTAS WHERE ID_APUESTA =  :new.ID_APUESTA) + :new.VALOR_APOSTADO) WHERE ID = :new.ID_APUESTA;

  END IF; 
END;
 
 
SELECT SUM(VALOR_APOSTADO) FROM DETALLES_APUESTAS WHERE ID_APUESTA = 1084;
SELECT * FROM APUESTAS WHERE ID = 1084;
DELETE FROM DETALLES_APUESTAS WHERE ID_APUESTA = 1084;
UPDATE APUESTAS SET VALOR_TOTAL = 0 WHERE ID = 1084;

Insert into DBA_JULIAN.DETALLES_APUESTAS (OPCION_CUOTA,CUOTA_GANADORA,ESTADO,VALOR_APOSTADO,ID_APUESTA,ID_CUOTA,SOFT_DELETION) values 
('1.60','1.60','GANADO',30000,1084,101,1);


------------------------Funciones---------------------------------------------------------------------------------
/*
A. Crear una funci�n que reciba un argumento de tipo n�mero, 
este representar� el id de un usuario; 
la funci�n retornar� TRUE si el usuario se encuentra logueado en el sistema. 
(Usar esta funci�n en todos los procedimientos donde se requiera validar que el usuario tenga una sesi�n activa.)
*/

CREATE OR REPLACE FUNCTION LOGIN (ID_US IN NUMBER) RETURN NUMBER IS
    CONEXION NUMBER;

BEGIN
    SELECT ESTADO_CONEXION INTO CONEXION FROM SESIONES  WHERE ID_USUARIO = ID_US AND ROWNUM = 1 ORDER BY (ID) DESC;
    RETURN CONEXION;
END;

SELECT LOGIN(1) FROM DUAL;


/*
B. Crear un procedimiento almacenado que reciba el nombre de la tabla y el id del registro que se desea actualizar, 
la idea de este procedimiento es que active el soft deletion de dicho registro ubicado en dicha tabla. 
Deber� tener manejo de excepciones dado el caso que el nombre de la tabla y/o el id no existan. 
*/

CREATE OR REPLACE PROCEDURE ELIMINAR_REGISTRO(ID_CAMPO NUMBER, NOMBRE_TABLA VARCHAR2) IS
  err_num NUMBER;
  err_msg VARCHAR2(255);
  i NUMBER;  
  consulta VARCHAR2(500);

BEGIN
  consulta := 'UPDATE '||  NOMBRE_TABLA ||' SET SOFT_DELETION = 0 WHERE ID ='|| ID_CAMPO ;
  EXECUTE IMMEDIATE consulta;
  i := SQL%rowcount; 

  IF i = 0 THEN

    DBMS_OUTPUT.PUT_LINE('No se ha eliminado ning�n registro: ');
  
  END IF;

EXCEPTION
  
  WHEN no_data_found then
    DBMS_OUTPUT.PUT_LINE('No se ha encontrado ning�n registro: ');

  WHEN value_error then   
    DBMS_OUTPUT.PUT_LINE('Se ha producido un error num�rico ');

  WHEN OTHERS THEN
    err_num := SQLCODE;
    err_msg := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('La tabla ' || NOMBRE_TABLA ||' no existe');
         
END ;

EXEC ELIMINAR_REGISTRO (1,'PARTIDOS');



/*
C. Crear un procedimiento que coloque un partido en estado "FINALIZADO", 
en ese momento deber� calcular las ganancias y p�rdidas de cada apuesta hecha asociada a ese partido.
*/

CREATE OR REPLACE PROCEDURE PARTIDO_FINALIZADO (ID_PARTIDO_FINALIZADO NUMERIC) 
IS

BEGIN
    UPDATE PARTIDOS SET ESTADO = 'FINALIZADO' WHERE ID = ID_PARTIDO_FINALIZADO;
DECLARE
    CURSOR CURSOR_PFINALIZADO IS
    SELECT APU.ID_USUARIO,  SUM( CAST(DAP.CUOTA_GANADORA AS DECIMAL(18,2)) * DAP.VALOR_APOSTADO) GANANCIAS
    FROM PARTIDOS PA INNER JOIN CUOTAS CU
    ON PA.ID = CU.ID_PARTIDO
    INNER JOIN DETALLES_APUESTAS DAP
    ON CU.ID = DAP.ID_CUOTA
    INNER JOIN APUESTAS APU
    ON DAP.ID_APUESTA = APU.ID
    WHERE DAP.ESTADO = 'GANADO' AND PA.ID = ID_PARTIDO_FINALIZADO
    GROUP BY APU.ID_USUARIO;
    
    V_ID_USUARIO NUMERIC;
    V_TOTAL_GANANCIAS NUMERIC;
    
    BEGIN
        OPEN CURSOR_PFINALIZADO;
        LOOP
            FETCH CURSOR_PFINALIZADO INTO V_ID_USUARIO, V_TOTAL_GANANCIAS;
                UPDATE APUESTAS SET TOTAL_GANANCIAS = V_TOTAL_GANANCIAS  WHERE ID = V_ID_USUARIO;
            EXIT WHEN CURSOR_PFINALIZADO%NOTFOUND;    
        END LOOP;  
        CLOSE CURSOR_PFINALIZADO;
    END;
END;



/*D Crear un procedimiento que reciba el ID de una APUESTA (Las que efectuan los usuarios) y reciba: 
id_usuario, valor, tipo_apuesta_id, cuota, opci�n ganadora (Ya cada uno mirar� como manejan esta parte 
conforme al dise�o que tengan). Con estos par�metros deber� insertar un registro en la tabla detalles de 
apuesta en estado "ABIERTA".*/

CREATE OR REPLACE PROCEDURE CREAR_DETALLE_APUESTA (V_ID_APUESTA NUMBER, V_ID_CUOTA NUMBER, V_VALOR_APOSTADO NUMBER, V_CUOTA VARCHAR2) IS
   
 CONSULTA VARCHAR2(500);
 
  BEGIN 
   
   CONSULTA := 'INSERT INTO DETALLES_APUESTAS (OPCION_CUOTA, ESTADO,VALOR_APOSTADO, ID_APUESTA,ID_CUOTA, SOFT_DELETION ) 
    VALUES ( ' || V_CUOTA || ',  ''ABIERTA'' , ' || V_VALOR_APOSTADO || ', ' || V_ID_APUESTA || ', '|| V_ID_CUOTA || ', 1)';
   
  
    DBMS_OUTPUT.PUT_LINE(CONSULTA);
    EXECUTE IMMEDIATE CONSULTA;
    
  END;  
  
  EXEC CREAR_DETALLE_APUESTA (1001,63,50000,'2.30');
  
    /*Crear un procedimiento que permita procesar el retiro de ganancias, recibir� el monto solicitado 
    y el id del usuario, este procedimiento deber� insertar un registro en la tabla movimientos / retiros en estado
    "PENDIENTE", posteriormente deber� validar si el saldo es suficiente, si el usuario ha prove�do toda la 
    documentaci�n exigida. Tambi�n validar� que si tenga una cuenta y un banco v�lido registrado. Si todo se 
    valida sin problemas, deber� colocar el estado "APROBADO" en el registro correspondiente y deber� restar 
    del saldo disponible el valor retirado. Si el procedimiento falla alguna validaci�n, el estado pasar� a 
    "RECHAZADO". El sistema deber� almacenar cu�l es la novedad por la cual se rechaz� (Ya ustedes deciden si 
    crean una nueva tabla, o colocan en la tabla de retiros una columna de observaciones).*/
  
  
   CREATE OR REPLACE PROCEDURE PROCESAR_RETIROS (MONTO NUMBER, V_ID_USUARIO NUMBER, BANCO VARCHAR2, CUENTA VARCHAR2, V_ID_COMPROBANTE NUMBER) IS
 
    V_FECHA_SOLICITUD TIMESTAMP;
    V_FECHA_DESEMBOLSO TIMESTAMP;
    CONSULTA VARCHAR2 (500);
    CONSULTA2 VARCHAR2 (500);
    V_ID NUMBER;
    SALDO_USUARIO NUMBER;
     
     BEGIN 
   
   SELECT current_timestamp INTO V_FECHA_SOLICITUD FROM dual;
   SELECT SALDO INTO SALDO_USUARIO FROM USUARIOS WHERE  ID = V_ID_USUARIO;
     
   CONSULTA := 'INSERT INTO RETIROS (VALOR_RETIRO, FECHA_SOLICITUD, BANCO, CUENTA_BANCARIA, REQUISITO,ID_USUARIO, ID_COMPROBANTE, SOFT_DELETION, ESTADO ) 
     VALUES ( '|| MONTO || ', to_timestamp('''|| V_FECHA_SOLICITUD || ''', ''DD/MM/RR HH24:MI:SSXFF''),'' '   || BANCO  || ' '', '' '|| CUENTA || ' '', 0 , '|| V_ID_USUARIO || ',1 , 1,''PENDIENTE'')';
      
      --EXECUTE IMMEDIATE CONSULTA;
   DBMS_OUTPUT.PUT_LINE(consulta);   
 
     IF SALDO_USUARIO = 0 OR SALDO_USUARIO < MONTO  THEN
     
          --SELECT ID INTO V_ID FROM RETIROS  WHERE ID_USUARIO = 984 AND ROWNUM = 1 ORDER BY (ID) DESC ;
          CONSULTA2 := 'UPDATE RETIROS SET ESTADO = ''RECHAZADO'' WHERE ID = '||V_ID;
          
         -- EXECUTE IMMEDIATE CONSULTA2;
         DBMS_OUTPUT.PUT_LINE(CONSULTA2);   
     ELSE 
        DBMS_OUTPUT.PUT_LINE('SI TIENES SALDO');   
    END IF; 
    
<<<<<<< HEAD
    END;
  
  
    EXEC PROCESAR_RETIROS(10000000,1008,'BANCOLOMBIA','223342',1);
    
    SELECT RE.ID AS NUMERO_RETIRO, COM.ID AS NUMERO_COMPROBANTE FROM COMPROBANTES COM INNER JOIN RETIROS RE
    ON COM.ID = RE.ID_COMPROBANTE
    
    SELECT * FROM COMPROBANTES
    
=======
    CREATE OR REPLACE PROCEDURE PROCESAR_RETIROS (MONTO NUMBER, V_ID_USUAIRO NUMBER) IS
=======
 
>>>>>>> 91bc4aae606917722aa2412e1aabbf834fba64f8

    SELECT * FROM RETIROS
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
/*
Para la siguiente vista deber�n alterar el manejo de sesiones de usuario, 
el sistema deber� guardar el timestamp de la hora de sesi�n y el timestamp del fin de sesi�n, 
si el usuario tiene el campo fin de sesi�n en null, significa que la sesi�n est� activa. 
Crear una vista que traiga las personas que tienen una sesi�n activa, 
ordenado por la hora de inicio de sesi�n, mostrando las personas que m�s tiempo llevan activas; 
adicional, deber� tener una columna que calcule cu�ntas horas lleva en el sistema con respecto a la hora actual, 
la siguiente columna ser� la cantidad de horas seleccionada en las preferencias de usuario, finalmente, 
habr� una columna que reste cu�nto tiempo le falta para que se cierre la sesi�n (si aparece un valor negativo, 
significa que el usuario excedi� el tiempo en el sistema)
*/

CREATE OR REPLACE FUNCTION DIFERENCIA_HORAS(HORA_1 TIMESTAMP, HORA_2 TIMESTAMP) RETURN NUMBER as
  dias integer;
  horas integer;
  tiempo_transcurrido INTERVAL DAY TO SECOND;
  total_diferencia integer;
BEGIN
  tiempo_transcurrido := hora_2 - hora_1;
  dias := EXTRACT(day from tiempo_transcurrido);
  horas := EXTRACT(hour from tiempo_transcurrido); 
  
  total_diferencia := abs(dias*24 + horas);
  
  RETURN total_diferencia;
END;

CREATE OR REPLACE FUNCTION SUMA_HORAS(HORA_1 NUMBER, HORA_2 NUMBER) RETURN NUMBER as
  tiempo_transcurrido NUMBER;
BEGIN
  tiempo_transcurrido := hora_1 - hora_2;
  
  RETURN tiempo_transcurrido;
END;

ALTER TABLE USUARIOS ADD HORAS_SESION NUMBER

CREATE OR REPLACE VIEW SESION_ACTIVA AS
    SELECT SUBSTR(INICIO_SESION,1,15) HORA_INCIO, DIFERENCIA_HORAS (CURRENT_TIMESTAMP, SE.INICIO_SESION) HORAS_ACTIVAS, US.HORAS_SESION, SUMA_HORAS(US.HORAS_SESION, DIFERENCIA_HORAS(CURRENT_TIMESTAMP, SE.INICIO_SESION)) TIEMPO_RESTANTE
    FROM SESIONES SE INNER JOIN USUARIOS US
    ON SE.ID_USUARIO = US.ID
    WHERE SE.ESTADO_CONEXION = 1
    ORDER BY HORAS_ACTIVAS DESC;
    
   

















>>>>>>> 3aed626fea594ca5480c90d41d3ac6939d330d81
