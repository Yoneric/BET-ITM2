-- PUNTO 1 VISTAS

/* A.  Sumar el valor ganado de todas las apuestas de los usuarios que están en estado ganado de aquellos partidos asociados 
a las apuestas que se efectuaron en el trancurso de la semana y mostrarlas ordenadas por el valor más alto; El nombre de la vista será 
"GANADORES_SEMANALES" y tendrá dos columnas: nombre completo y valor acumulado.

Considerar el siguiente query select trunc(sysdate, 'DAY') start_of_the_week, trunc(sysdate, 'DAY')+6 end_of_the_week from dual;*/

CREATE OR REPLACE VIEW GANADORES_SEMANALES AS
SELECT us.primer_nombre ||' ' ||US.SEGUNDO_NOMBRE||' ' ||us.primer_apellido ||' '|| US.SEGUNDO_APELLIDO  "NOMBRE COMPLETO", sum(ap.total_ganancias)"TOTAL GANANCIAS" 
FROM usuarios us INNER JOIN apuestas ap
ON ap.id_usuario = us.id
WHERE AP.FECHA BETWEEN (SELECT trunc(sysdate, 'DAY') FROM DUAL) AND (SELECT trunc(sysdate, 'DAY')+6 FROM dual)
GROUP BY us.primer_nombre,SEGUNDO_NOMBRE, us.primer_apellido,SEGUNDO_APELLIDO;

SELECT * FROM GANADORES_SEMANALES


/* B.  Nombre de la vista: DETALLES_APUESTAS. Esta vista deberá mostrar todos los detalles de apuestas simples que se 
efectuaron para un boleto en particular, tal como se muestra en el siguiente ejemplo: */

CREATE OR REPLACE VIEW DETALLE_APUESTAS AS 
SELECT  E.EQUIPO ||' VS '|| E2.EQUIPO "PARTIDO", DAP.OPCION_CUOTA, C.CUOTA_GANADORA,CA.NOMBRE "CATEGORÍA", AP.ID "APUESTA"
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


/* C.  Nombre de la vista: RESUMEN_APUESTAS. Esta vista mostrará el resumen de cada apuesta efectuada en el sistema, 
la información de la siguiente imagen corresponderá a cada columna (Omitir la siguiente columna Pago máx. incl. 5% bono 
(293.517,58 $)). La idea es que cuando se llame la vista, muestre la información únicamente de esa apuesta en particular: 
SELECT * FROM RESUMEN_APUESTAS WHERE APUESTAS.ID = 123. */

CREATE OR REPLACE VIEW RESUMEN_APUESTAS AS
SELECT AP.ID "APUESTA" ,COUNT(*) "NÚMERO DE APUESTAS",COUNT(*)||' x $'|| DAP.VALOR_APOSTADO || ' = $' || SUM(DAP.VALOR_APOSTADO) "VALOR TOTAL APUESTA",MAX (OPCION_CUOTA)  "MAX. TOTAL CUOTA"
FROM  DETALLES_APUESTAS DAP
INNER JOIN APUESTAS AP
ON AP.ID = DAP.ID_APUESTA
GROUP BY DAP.VALOR_APOSTADO,AP.ID

SELECT * FROM RESUMEN_APUESTAS WHERE APUESTA = 1001

SELECT * FROM LOGIN

SELECT * FROM USUARIOS


/*D. 
Para la siguiente vista deberán alterar el manejo de sesiones de usuario, 
el sistema deberá guardar el timestamp de la hora de sesión 
y el timestamp del fin de sesión, si el usuario tiene el campo fin de sesión en null, 
significa que la sesión está activa. 
Crear una vista que traiga las personas que tienen una sesión activa, ordenado por la hora de inicio de sesión, 
mostrando las personas que más tiempo llevan activas; adicional, deberá tener una columna que calcule 
cuántas horas lleva en el sistema con respecto a la hora actual, 
la siguiente columna será la cantidad de horas seleccionada 
en las preferencias de usuario, finalmente, habrá una columna 
que reste cuánto tiempo le falta para que se cierre la sesión 
(si aparece un valor negativo, significa que el usuario excedió el tiempo en el sistema)*/



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

