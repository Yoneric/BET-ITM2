-- PUNTO 1 VISTAS

/* A.  Sumar el valor ganado de todas las apuestas de los usuarios que est�n en estado ganado de aquellos partidos asociados 
a las apuestas que se efectuaron en el trancurso de la semana y mostrarlas ordenadas por el valor m�s alto; El nombre de la vista ser� 
"GANADORES_SEMANALES" y tendr� dos columnas: nombre completo y valor acumulado.

Considerar el siguiente query select trunc(sysdate, 'DAY') start_of_the_week, trunc(sysdate, 'DAY')+6 end_of_the_week from dual;*/

CREATE OR REPLACE VIEW GANADORES_SEMANALES AS
SELECT us.primer_nombre ||' ' ||US.SEGUNDO_NOMBRE||' ' ||us.primer_apellido ||' '|| US.SEGUNDO_APELLIDO  "NOMBRE COMPLETO", sum(ap.total_ganancias)"TOTAL GANANCIAS" 
FROM usuarios us INNER JOIN apuestas ap
ON ap.id_usuario = us.id
WHERE AP.FECHA BETWEEN (SELECT trunc(sysdate, 'DAY') FROM DUAL) AND (SELECT trunc(sysdate, 'DAY')+6 FROM dual)
GROUP BY us.primer_nombre,SEGUNDO_NOMBRE, us.primer_apellido,SEGUNDO_APELLIDO;

SELECT * FROM GANADORES_SEMANALES


/* B.  Nombre de la vista: DETALLES_APUESTAS. Esta vista deber� mostrar todos los detalles de apuestas simples que se 
efectuaron para un boleto en particular, tal como se muestra en el siguiente ejemplo: */

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


/* C.  Nombre de la vista: RESUMEN_APUESTAS. Esta vista mostrar� el resumen de cada apuesta efectuada en el sistema, 
la informaci�n de la siguiente imagen corresponder� a cada columna (Omitir la siguiente columna Pago m�x. incl. 5% bono 
(293.517,58 $)). La idea es que cuando se llame la vista, muestre la informaci�n �nicamente de esa apuesta en particular: 
SELECT * FROM RESUMEN_APUESTAS WHERE APUESTAS.ID = 123. */

CREATE OR REPLACE VIEW RESUMEN_APUESTAS AS
SELECT AP.ID "APUESTA" ,COUNT(*) "N�MERO DE APUESTAS",COUNT(*)||' x $'|| DAP.VALOR_APOSTADO || ' = $' || SUM(DAP.VALOR_APOSTADO) "VALOR TOTAL APUESTA",MAX (OPCION_CUOTA)  "MAX. TOTAL CUOTA"
FROM  DETALLES_APUESTAS DAP
INNER JOIN APUESTAS AP
ON AP.ID = DAP.ID_APUESTA
GROUP BY DAP.VALOR_APOSTADO,AP.ID

SELECT * FROM RESUMEN_APUESTAS WHERE APUESTA = 1001

/*D. 
Para la siguiente vista deber�n alterar el manejo de sesiones de usuario, 
el sistema deber� guardar el timestamp de la hora de sesi�n 
y el timestamp del fin de sesi�n, si el usuario tiene el campo fin de sesi�n en null, 
significa que la sesi�n est� activa. 
Crear una vista que traiga las personas que tienen una sesi�n activa, ordenado por la hora de inicio de sesi�n, 
mostrando las personas que m�s tiempo llevan activas; adicional, deber� tener una columna que calcule 
cu�ntas horas lleva en el sistema con respecto a la hora actual, 
la siguiente columna ser� la cantidad de horas seleccionada 
en las preferencias de usuario, finalmente, habr� una columna 
que reste cu�nto tiempo le falta para que se cierre la sesi�n 
(si aparece un valor negativo, significa que el usuario excedi� el tiempo en el sistema)*/



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
/* Crear un trigger para TODAS las tablas que tienen creadas, el trigger deber� llenar la informaci�n de la tabla de auditor�a 
cuando se produce una INSERCI�N, ACTUALIZACI�N y ELIMINACI�N de registros (Recordar que estamos trabajando con SOFT deletion y
por ende ning�n usuario deber�a tener el privilegio de ELIMINAR registros). Para obtener la IP desde donde se produce la conexi�n,
usar: SQL> SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') FROM dual;*/
  
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
 
 
 /*B
 Crear un(os) trigger(s) que permita(n) mantener el saldo del usuario ACTUALIZADO, es decir, si se produce un retiro, una recarga,
 una apuesta o hay ganancias de una apuesta, autom�ticamente deber� actualizar el saldo disponible del usuario.*/
 

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
 
select * from retiros

select * from depositos

select saldo from usuarios where id  = 984

 
 Insert into DBA_JULIAN.APUESTAS (ID_USUARIO,VALOR_TOTAL,TOTAL_GANANCIAS,FECHA,ID_ESTADO,SOFT_DELETION) 
 values (1008,'0','0',to_date('18/07/19','DD/MM/RR'),'3','1');

 
Insert into DBA_JULIAN.RETIROS (VALOR_RETIRO,FECHA_SOLICITUD,FECHA_DESEMBOLSO,BANCO,CUENTA_BANCARIA,REQUISITO,ID_USUARIO,ID_COMPROBANTE,SOFT_DELETION)
values (100000,to_timestamp('06/06/08 18:30:34,000000000','DD/MM/RR HH24:MI:SSXFF'),to_timestamp('07/06/08 18:30:34,000000000','DD/MM/RR HH24:MI:SSXFF'),'BANCOLOMBIA','56487764532','1','984','1','1');
 

Insert into DBA_JULIAN.DEPOSITOS (VALOR,FECHA,ID_USUARIO,ID_ESTADO,ID_MEDIO_DE_PAGO,SOFT_DELETION) 
values ('500000',to_timestamp('05/02/08 18:12:54,000000000','DD/MM/RR HH24:MI:SSXFF'),'984','4','1','1');
 
/*Crear una funci�n que reciba un argumento de tipo n�mero, 
este representar� el id de un usuario; 
la funci�n retornar� TRUE si el usuario se encuentra logueado en el sistema. 
(Usar esta funci�n en todos los procedimientos donde se requiera validar que el usuario tenga una sesi�n activa.)*/

CREATE OR REPLACE FUNCTION LOGIN (ID_US IN NUMBER) RETURN NUMBER AS
    CONEXION NUMBER;
BEGIN
    CONEXION := (SELECT ESTADO_CONEXION FROM SESIONES  WHERE ID_USUARIO = ID_US AND ROWNUM = 1 ORDER BY (ID) DESC);
    RETURN CONEXION;
END;

EXEC LOGIN (1);


















/*C
Crear un trigger asociado a la tabla PARTIDOS, este trigger se disparar� solamente cuando 
el partido pase a estado "FINALIZADO". El prop�sito de este trigger es ejecutar el o 
los procedimientos hechos para liquidar las ganancias y p�rdidas de los usuarios 
que apostaron a ese partido.
*/
drop trigger ACTUALIZA_PARTIDOS

CREATE OR REPLACE TRIGGER ACTUALIZA_PARTIDOS
  BEFORE UPDATE OF ESTADO ON PARTIDOS
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


UPDATE PARTIDOS SET ESTADO = 'FINALIZADO' WHERE ID = 31

SELECT ESTADO FROM PARTIDOS WHERE ID = 31;

/*D
Crear un trigger asociado a la tabla DETALLES_APUESTAS, este trigger mantendr� actualizado el 
campo "valor_total" de la tabla APUESTAS*/


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

DELETE FROM DETALLES_APUESTAS WHERE ID_APUESTA = 1084

UPDATE APUESTAS SET VALOR_TOTAL = 0 WHERE ID = 1084

Insert into DBA_JULIAN.DETALLES_APUESTAS (OPCION_CUOTA,CUOTA_GANADORA,ESTADO,VALOR_APOSTADO,ID_APUESTA,ID_CUOTA,SOFT_DELETION) values 
('1.60','1.60','GANADO',30000,1084,101,1);

