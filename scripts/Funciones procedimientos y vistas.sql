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

SELECT * FROM LOGIN

SELECT * FROM USUARIOS


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

